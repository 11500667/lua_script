#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-02-12
#描述：修改发布到班级
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

 --连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--接收参数
--获得人员id
if args["person_id"] == nil or args["person_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
    return
end
local teacher_id = args["person_id"];

--获得删除的班级和类型152:1,153:1
if args["del_classorgroup"] == nil  then
    ngx.say("{\"success\":false,\"info\":\"del_classorgroup参数错误！\"}")
    return
end
local del_classorgroup = args["del_classorgroup"];

--获得增加的班级id 154:1,151:1
if args["add_classorgroup"] == nil then
    ngx.say("{\"success\":false,\"info\":\"add_classorgroup参数错误！\"}")
    return
end
local add_classorgroup = args["add_classorgroup"];

--获得微课id
if args["wk_id"] == nil or args["wk_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"wk_id参数错误！\"}")
    return
end
local wk_id = args["wk_id"];
local cjson = require "cjson";
local sql = "";
---删除班级-------------
if #del_classorgroup>0 then
local del_class_id_tab = Split(del_classorgroup,",");

for i=1,#del_class_id_tab do
--拆分班级或者群组id,获得类型
    local class_info = del_class_id_tab[i];
    local class_info_tab = Split(class_info,":");
    local class_id = class_info_tab[1];
    local type_id = class_info_tab[2];
	local del_class_sql = "delete from t_wkds_wktoclassgroup where wk_id="..wk_id.." and teacher_id="..teacher_id.." and type="..type_id.." and CLASSORGROUP_ID="..class_id;
    sql = del_class_sql..";"..sql
    --根据班级获得学生
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
	sql =string.sub(sql,1,#sql-1)
	for i=1,#student_list do
      
	  local del_student_sql = "delete from t_wkds_wktostudent where wk_id="..wk_id.." and teacher_id="..teacher_id.." and student_id ="..student_list[i].student_id;
	  sql = sql..";"..del_student_sql;
	end
end
end
end
-- 增加新的班级--------


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
local sql_str = "";
local sql_class_str = "";
--根据班级获得对应的学生
if #add_classorgroup>0 then
local class_id_tab = Split(add_classorgroup,",");

for i=1,#class_id_tab do
local student_list;
--拆分班级或者群组id,获得类型
local class_info = class_id_tab[i];
local class_info_tab = Split(class_info,":");
local class_id = class_info_tab[1];
local type_id = class_info_tab[2];

local id_class_ssdb = ssdb_db:incr("t_wkds_wktoclassgroup_pk");
        local id_class = id_class_ssdb[1]
   sql_class_str = sql_class_str..",("..id_class..","..wk_id..","..teacher_id..","..type_id..","..class_id..")";
   
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
		sql_str = sql_str..",("..id..","..wk_id..","..teacher_id..","..student_id..","..update_ts..",'"..create_time.."',"..class_id..")";
		
		ssdb_db:multi_hset(
	    "wktostudent_"..id, 
	    "wkds_id", wk_id,
		"create_time", create_time
        );

	end
end
end
end
if #sql_str>0 then
   sql_str = string.sub(sql_str,2,#sql_str);
end
if #sql_class_str then
   sql_class_str = string.sub(sql_class_str,2,#sql_class_str);
end
local in_wktostudent="";
if #sql_str>1 then
in_wktostudent = "INSERT INTO t_wkds_wktostudent(ID,WK_ID,TEACHER_ID,STUDENT_ID,UPDATE_TS,CREATE_TIME,CLASS_ID) VALUES "..sql_str..";";
end
local in_clsss = "";
if #sql_class_str>1 then
 in_clsss= "INSERT INTO t_wkds_wktoclassgroup(ID,WK_ID,TEACHER_ID,TYPE,CLASSORGROUP_ID) VALUES "..sql_class_str..";";
end

if #sql>1 then
  sql = sql..";";
end
-- 事务提交
local sql_submit="start transaction;"..sql..in_wktostudent..in_clsss.."commit;" ;
ngx.log(ngx.ERR,"================================="..sql_submit)
res, err, errno, sqlstate = db:query(sql_submit)
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










