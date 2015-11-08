#ngx.header.content_type = "text/plain;charset=utf-8"
local request_method = ngx.var.request_method
local args = nil

if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end


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
--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)

-- 获取资源base_id参数
if args["resource_int_id"]==nil or args["resource_int_id"]=="" then
    ngx.say("{\"success\":false,\"info\":\"resource_int_id参数异常\"}")
    return
end

-- 获取资源info_id参数
if args["resource_info_id"]==nil or args["resource_info_id"]=="" then
    ngx.say("{\"success\":false,\"info\":\"resource_info_id参数异常\"}")
    return
end

-- 获取发布状态参数
if args["state"]==nil or args["state"]=="" then
    ngx.say("{\"success\":false,\"info\":\"state参数异常\"}")
    return
end

local resource_int_ids = tostring(args["resource_int_id"])  
local resource_info_ids = tostring(args["resource_info_id"])  
local state = tostring(args["state"])  

-- ngx.log(ngx.ERR,"===="..resource_ids)
-- 时间戳
local t=ngx.now();
local n=os.date("%Y%m%d%H%M%S").."00"..string.sub(t,12,14)
      n=n..string.rep("0",19-string.len(n))
local resource_id_int = Split(resource_int_ids,",")
local resource_info_id = Split(resource_info_ids,",")
--local question_id_char = Split(question_id_chars,",")

for i=1,#resource_id_int do
	local ts = n;
	local info_count =  db:query("UPDATE T_RESOURCE_INFO SET RELEASE_STATUS = ".. state .. ",UPDATE_TS = "..ts.." WHERE id = '"..resource_info_id[i].."'")
	local base_count =  db:query("UPDATE T_RESOURCE_BASE SET RELEASE_STATUS = ".. state ..",TS = ".. ts .." WHERE RESOURCE_ID_INT = '"..resource_id_int[i].."'")
   -- cache:hset("resource_"..resource_info_id[i],"release_status",state);
	
	 local resource_map = {};
	 resource_map.release_status = state;
	 resource_map.id = resource_info_id[i];
	 local resourceUtil  = require "base.resource.model.ResourceUtil";
     local result = resourceUtil:setResourceInfo(resource_map)
        if result~=true then
            ngx.say("{\"success\":false,\"info\":\"操作失败\"}")
        end
			   
	
end	
-- 将redis连接归还到连接池
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
    ngx.log(ngx.ERR, "====>将Redis连接归还连接池出错！");
end

-- 将mysql连接归还到连接池
local ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
    ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

ngx.say("{\"success\":true}")		
	