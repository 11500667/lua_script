local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--地区
if args["area_id"] == nil or args["area_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"area_id参数错误！\"}")
    return
end
local area_id = args["area_id"]

--一页显示多少
if args["pageSize"] == nil or args["pageSize"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"pageSize参数错误！\"}")
    return
end
local pageSize = args["pageSize"]

local cjson = require "cjson"

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

local workroom_list = ssdb_db:zrrange("workroom_hot_"..area_id,0,pageSize)

local workroom_tab = {}
local i_count = 1
for i=1,#workroom_list,2 do
	local workroom_res = {}
	local person_id = workroom_list[i]
	local person_info = cache:hmget("person_"..person_id.."_5","person_name","avatar_url","xiao")
	local person_name = person_info[1]
	local avatar_url = person_info[2]
	local xiao_id = person_info[3]
	local school_name = cache:hget("t_base_organization_"..xiao_id,"org_name")
	workroom_res["teacher_id"] = person_id
	workroom_res["person_name"] = person_name
	workroom_res["avatar_url"] = avatar_url
	workroom_res["school_name"] = school_name
	workroom_tab[i_count] = workroom_res
	i_count = i_count+1	
end

local result = {}
result["list"] = workroom_tab 
result["success"] = true

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false)
ngx.say(cjson.encode(result))
