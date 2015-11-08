#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-07-25
#描述：记录锁开始，结束
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
if args["obj_id_int"] == nil or args["obj_id_int"] == "" then
    ngx.say("{\"success\":false,\"info\":\"obj_id_int参数错误！\"}")
    return
end
local obj_id_int  = tostring(args["obj_id_int"]);

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

if args["type_id"] == nil or args["type_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"type_id参数错误！\"}")
    return
end
-- 类型id 1表示加锁 2表示解锁
local type_id  = tostring(args["type_id"]);
--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
	if not ok then
		ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
		return
	end

local is_lock = 0;
if type_id=="1" or type_id == 1 then
	is_lock = 1;
end

local create_time = ngx.localtime();
local lock_info = {};
	lock_info.person_id = person_id;
	lock_info.is_lock = is_lock;
	lock_info.time = create_time;
	lock_info.identity_id = identity_id;
	
 local result = ssdb_db:multi_hset("lock_resource_"..obj_id_int, lock_info);
 
 --放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)
  
if result=="false" then
	 ngx.say("{\"success\":false,\"info\":\"操作失败\"}")
else
	 ngx.say("{\"success\":true,\"info\":\"操作成功\"}")
end 
	


