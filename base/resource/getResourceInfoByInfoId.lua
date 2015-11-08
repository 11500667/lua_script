local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--资源INFO_ID
if args["resource_info_ids"] == nil or args["resource_info_ids"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"resource_info_ids参数错误！\"}")
    return
end
local resource_info_ids = args["resource_info_ids"]
--[[
--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end
]]
--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end


local cjson = require "cjson"

local json_str = ""

local ids = Split(resource_info_ids,",")
for i=1,#ids do
	local id_info = Split(ids[i],"_")
	local info_id = id_info[1]
	local type_id = id_info[2] --1：resource 2：myresource
	
	local myjson =""
	if type_id == "1" then
		myjson = ssdb_db:hgetall("resource_"..info_id)
	else
		myjson = ssdb_db:hgetall("myresource_"..info_id)
	end
	if #myjson ~= 0 then
	    local str = "{"
	    for j=2,#myjson,2 do
		str = str.."\""..myjson[j-1].."\":\""..myjson[j].."\","	
	    end
	    str = string.sub(str,0,#str-1).."},"		
	    json_str = json_str..str
	end
end
if #json_str ~= 0 then
  json_str = string.sub(json_str,0,#json_str-1)
end

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size);

ngx.say("{\"success\":true,\"list\":["..json_str.."]}")
