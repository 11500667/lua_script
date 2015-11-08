#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-07-25
#描述：判断该资源是否是锁定状态，如果锁定返回锁定信息
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

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
	if not ok then
		ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
		return
	end

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end


local lock_info = ssdb_db:multi_hget("lock_resource_"..obj_id_int,"is_lock","person_id","identity_id");

local is_lock;
local person_name="";

if lock_info[2] == "0" or lock_info[2] == 0 or lock_info[2] == nil then
     is_lock = 0;
else
     if person_id == lock_info[4] and identity_id == lock_info[6] then
	        is_lock = 0;
	 else
	        is_lock = 1;
		    person_name = cache:hget("person_"..lock_info[4].."_"..lock_info[6],"person_name");
	 end

end

 --放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)

-- 将redis连接归还到连接池
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
    ngx.log(ngx.ERR, "====>将redis数据库连接归还连接池出错");
end

ngx.say("{\"success\":true,\"info\":\"操作成功\",\"is_lock\":\""..is_lock.."\",\"person_name\":\""..person_name.."\"}")

	


