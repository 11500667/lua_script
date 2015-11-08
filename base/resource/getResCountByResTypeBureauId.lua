local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--bureau_id参数 单位ID
if args["bureau_ids"] == nil or args["bureau_ids"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"bureau_ids参数错误！\"}")
	return
end
local bureau_ids = args["bureau_ids"]

--1：资源  3：试卷  2：试题  4：备课   5：微课
if args["res_type"] == nil or args["res_type"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"res_type参数错误！\"}")
	return
end
local res_type = args["res_type"]

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local type_name = ""
if res_type == "1" then
    type_name = "zy"
elseif res_type=="2" then
    type_name = "st"
elseif res_type=="3" then
    type_name = "sj"
elseif res_type=="4" then
    type_name = "bk"
else
    type_name = "wk"
end

local cjson = require "cjson"

local count_tab = {}
if bureau_ids ~= "-1" then
	local bureau_info = Split(bureau_ids,",")
	for i=1,#bureau_info do 
		local count_info = {}
		local res_count = ssdb_db:hget("tj_bureau_"..type_name.."_"..bureau_info[i].."_all","resource_count",count)[1]
		count_info["count"] = "0"
		if #res_count ~= 0 then
			count_info["count"] = res_count
		end
		count_info["bureau_id"] = bureau_info[i]
		count_info["bureau_name"] = cache:hget("t_base_organization_"..bureau_info[i],"org_name")
		count_tab[i] = count_info
	end
end

local result = {}
result["success"] = true
result["list"] = count_tab

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false)
ngx.print(tostring(cjson.encode(result)))
