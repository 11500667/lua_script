#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-05-04
#描述：前台->普通教师->发送资源到检查中
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

--传参数
if args["add_check_ids"] == nil  then
    ngx.say("{\"success\":false,\"info\":\"add_check_ids参数错误！\"}")
    return
end
--local add_check_ids  = args["add_check_ids"];
local cjson = require "cjson"
local add_check_ids = ngx.unescape_uri(args["add_check_ids"])
local t_add_check_ids = cjson.decode(add_check_ids)

if args["del_check_ids"] == nil  then
    ngx.say("{\"success\":false,\"info\":\"del_check_ids参数错误！\"}")
    return
end
--local del_check_ids  = tostring(args["del_check_ids"]);

local del_check_ids = ngx.unescape_uri(args["del_check_ids"])
local t_del_check_ids = cjson.decode(del_check_ids)

if args["person_id"] == nil or args["person_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
    return
end
local person_id  = tostring(args["person_id"]);

if args["identity_id"] == nil or args["identity_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"identity_id参数错误！\"}")
    return
end
local identity_id  = tostring(args["identity_id"]);

if args["subject_id"] == nil or args["subject_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"subject_id参数错误！\"}")
    return
end
local subject_id  = tostring(args["subject_id"]);

if args["stage_id"] == nil or args["stage_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"stage_id参数错误！\"}")
    return
end
local stage_id  = tostring(args["stage_id"]);

if args["obj_id_int"] == nil or args["obj_id_int"] == "" then
    ngx.say("{\"success\":false,\"info\":\"obj_id_int参数错误！\"}")
    return
end
local obj_id_int  = tostring(args["obj_id_int"]);

if args["type_id"] == nil or args["type_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"type_id参数错误！\"}")
    return
end
local type_id  = tostring(args["type_id"]);

--根据人员id获得学校id

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local school_id = cache:hget("person_"..person_id.."_"..identity_id,"xiao");
-- 将redis连接归还到连接池
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
    ngx.log(ngx.ERR, "====>将redis数据库连接归还连接池出错");
end
--新增的检查
local add_check_tab = {};
add_check_tab = Split(add_check_ids,",");
--取消的检查
local del_check_tab = {};
del_check_tab = Split(del_check_ids,",");

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

--根据int_id获得对应的infoid
local sql_info_id = "";

if type_id == "1" then
    sql_info_id = "SELECT SQL_NO_CACHE id FROM t_resource_info_sphinxse where query='filter=resource_id_int,"..obj_id_int..";filter=group_id,2;'";
end
local result_infoid, err, errno, sqlstate = db:query(sql_info_id)
	 if not result_infoid then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	 ngx.say("{\"success\":false,\"info\":\"查询infoid失败！\"}");
	 return
 end
	
local obj_info_id = result_infoid[1]["id"];
local create_time = ngx.localtime();

local sql_del_check = "";
for j=1,#t_del_check_ids do
   sql_del_check = sql_del_check.."DELETE FROM t_resource_sendcheck WHERE person_id = "..person_id.." AND check_id = "..t_del_check_ids[j].." AND obj_info_id = "..obj_info_id..";";
end

local sql_sendcheck = "INSERT INTO T_RESOURCE_SENDCHECK(PERSON_ID,IDENTITY_ID,CHECK_ID,OBJ_INFO_ID,TYPE_ID,SCHOOL_ID,SUBJECT_ID,STAGE_ID,CREATE_TIME,TS) VALUES";
local sql_str = "";
local myts = require "resty.TS";
for i=1,#t_add_check_ids do
   local ts =  myts.getTs();
   sql_str = sql_str..",".."("..person_id..","..identity_id..","..t_add_check_ids[i]..","..obj_info_id..","..type_id..","..school_id..","..subject_id..","..stage_id..",'"..create_time.."',"..ts..")";
end

if #sql_str > 1 then
    sql_str = string.sub(sql_str,2,#sql_str);
	sql_str = sql_str..";";
end

if sql_str== "" then 
sql_sendcheck = "";
end
local sql_submit="start transaction;"..sql_del_check..sql_sendcheck..sql_str.."commit;" ;

local result, err, errno, sqlstate = db:query(sql_submit)
if not result then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	 ngx.say("{\"success\":false,\"info\":\"资源发送到检查失败！\"}");
	 return
end

-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

ngx.say("{\"success\":true,\"info\":\"资源发送到检查成功\"}")












