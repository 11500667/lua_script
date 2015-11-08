#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-02-12
#描述：发布微课到学生
]]
--1.获得参数方法
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end
 local myts = require "resty.TS";

--接收参数
--获得人员id
if args["person_id"] == nil or args["person_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
    return
end
local person_id = args["person_id"];

--获得人员名
if args["class_ids"] == nil or args["class_ids"] == "" then
    ngx.say("{\"success\":false,\"info\":\"class_ids参数错误！\"}")
    return
end
local class_ids = args["class_ids"];

--获得微课id
if args["wk_id"] == nil or args["wk_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"wk_id参数错误！\"}")
    return
end
local wk_id = args["wk_id"];


--获得类型id
if args["type_id"] == nil or args["type_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"type_id参数错误！\"}")
    return
end
local type_id = args["type_id"];


--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local cjson = require "cjson";
local TS = require "resty.TS";

--连接数据库
local mysql = require "resty.mysql"
local db = mysql:new()
db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024*1024
}
--写入ssdb
local create_time = os.date("%Y-%m-%d %H:%M:%S")
--根据班级获得对应的学生
local class_id_tab = Split(class_ids,",")
local sql_str = "";
local sql_class_str = "";
for i=1,#class_id_tab do
local student_list;
local class_info = class_id_tab[i];
local class_info_tab = Split(class_info,":");
local class_id = class_info_tab[1];
local type_id = class_info_tab[2];

local id_class_ssdb = ssdb_db:incr("t_wkds_wktoclassgroup_pk");
local id_class = id_class_ssdb[1]
   sql_class_str = sql_class_str..",("..id_class..","..wk_id..","..person_id..","..type_id..","..class_id..")";
   
if string.len(class_id)>0 then
	local student = ngx.location.capture("/dsideal_yy/base/getStudentByClassId",
	{
        	args={class_id=class_id}
	})

	if student.status == 200 then
        	student_list= cjson.decode(student.body).list
	else
        	say("{\"success\":false,\"info\":\"查询学生失败！\"}")
        	return
	end
	for i=1,#student_list do
       	local id_ssdb = ssdb_db:incr("t_wkds_wktostudent_pk");
        local id = id_ssdb[1]
	    local student_id = student_list[i].student_id;
		local update_ts = TS.getTs();
		sql_str = sql_str..",("..id..","..wk_id..","..person_id..","..student_id..","..update_ts..",'"..create_time.."')";
	end
end
end
if #sql_str>0 then
   sql_str = string.sub(sql_str,2,#sql_str);
end
if #sql_class_str then
   sql_class_str = string.sub(sql_class_str,2,#sql_class_str);
end

local in_wktostudent = "INSERT INTO t_wkds_wktostudent(ID,WK_ID,TEACHER_ID,STUDENT_ID,UPDATE_TS,CREATE_TIME) VALUES "..sql_str;
local in_clsss = "INSERT INTO t_wkds_wktoclassgroup(ID,WK_ID,TEACHER_ID,TYPE,CLASSORGROUP_ID) VALUES "..sql_class_str;

-- 事务提交
local sql="start transaction;"..in_wktostudent..";"..in_clsss..";commit;" ;
res, err, errno, sqlstate = db:query(sql)
if not res then
    ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
    return
end
-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)
ngx.say("{\"success\":true}");










