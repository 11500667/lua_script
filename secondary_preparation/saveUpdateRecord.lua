#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-05-07
#描述：保存用户修改记录
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
if args["new_obj_id_int"] == nil or args["new_obj_id_int"] == "" then
    ngx.say("{\"success\":false,\"info\":\"new_obj_id_int参数错误！\"}")
    return
end
local new_obj_id_int  = tostring(args["new_obj_id_int"]);

if args["old_obj_id_int"] == nil or args["old_obj_id_int"] == "" then
    ngx.say("{\"success\":false,\"info\":\"old_obj_id_int参数错误！\"}")
    return
end
local old_obj_id_int  = tostring(args["old_obj_id_int"]);

if args["new_person_id"] == nil or args["new_person_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"new_person_id参数错误！\"}")
    return
end
local new_person_id  = tostring(args["new_person_id"]);

if args["old_person_id"] == nil or args["old_person_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"old_person_id参数错误！\"}")
    return
end
local old_person_id  = tostring(args["old_person_id"]);


if args["type_id"] == nil or args["type_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"type_id参数错误！\"}")
    return
end
local type_id  = tostring(args["type_id"]);


local action_id  = tostring(args["action_id"]);

if args["action_id"] == nil then
    action_id = -1;
end

local describe;
if args["describe"] == nil  then
	describe = "";
else
    describe   = tostring(args["describe"]);
end

--根据int_id获得对应的infoid
local sql_info_id = "";
local sql_info_id1 = "";

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

if type_id == "1" then
    sql_info_id = "SELECT SQL_NO_CACHE id FROM t_resource_info_sphinxse where query='filter=resource_id_int,"..old_obj_id_int..";filter=group_id,2;'";
	sql_info_id1 = "SELECT  id FROM t_resource_info where resource_id_int = "..new_obj_id_int.." and group_id = 2";
end

local result_infoid, err, errno, sqlstate = db:query(sql_info_id)
	 if not result_infoid then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	 ngx.say("{\"success\":false,\"info\":\"查询infoid失败！\"}");
	 return
 end
 local result_infoid1, err, errno, sqlstate = db:query(sql_info_id1)
	 if not result_infoid then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	 ngx.say("{\"success\":false,\"info\":\"查询infoid失败！\"}");
	 return
 end

local old_obj_info_id = result_infoid[1]["id"];
local new_obj_info_id = result_infoid1[1]["id"];
local yuan_obj_info_id;

local sql_get_yuan_obj_info_id = "SELECT yuan_obj_info_id FROM t_resource_update_flow where new_obj_info_id ="..old_obj_info_id.." and type_id="..type_id;
local result_yuan = db:query(sql_get_yuan_obj_info_id)
if #result_yuan>0 then
	  yuan_obj_info_id = result_yuan[1]["yuan_obj_info_id"];
	else
	  yuan_obj_info_id = old_obj_info_id;
	end

local create_time = ngx.localtime();
local sql_add_record = "INSERT INTO t_resource_update_flow(type_id,new_obj_info_id,old_obj_info_id,new_person_id,old_person_id,create_time,yuan_obj_info_id,describe_info,action_id) values ("..type_id..","..new_obj_info_id..","..old_obj_info_id..","..new_person_id..","..old_person_id..",'"..create_time.."',"..yuan_obj_info_id..",'"..describe.."',"..action_id..")";

local result, err, errno, sqlstate = db:query(sql_add_record)
	 if not result then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	 ngx.say("{\"success\":false,\"info\":\"新增修改记录失败！\"}");
	 return
    end

--修改资源的数据库和缓存
local update_res = "update t_resource_info set is_secondary = 1 where id = "..new_obj_info_id;
db:query(update_res);
--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end
local res_map = {};
res_map.is_secondary = 1;
res_map.id = new_obj_info_id;
--修改缓存
--cache:hmset("resource_"..new_obj_info_id,res_map);
    local resourceUtil  = require "base.resource.model.ResourceUtil";
    local result = resourceUtil:setResourceInfo(res_map)
    
    if result~=true then
           ngx.say("{\"success\":false,\"info\":\"操作失败！\"}")
    end

-- 将redis连接归还到连接池
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
    ngx.log(ngx.ERR, "====>将redis数据库连接归还连接池出错");
end

-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

ngx.say("{\"success\":true,\"info\":\"新增修改记录成功\"}")
