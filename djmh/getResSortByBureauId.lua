local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--bureau_id参数 单位ID
if args["bureau_id"] == nil or args["bureau_id"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"bureau_id参数错误！\"}")
	return
end
local bureau_id = args["bureau_id"]

--1：资源  3：试卷  2：试题  4：备课   5：微课
if args["res_type"] == nil or args["res_type"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"res_type参数错误！\"}")
	return
end
local res_type = args["res_type"]

--前台名
if args["top"] == nil or args["top"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"top参数错误！\"}")
	return
end
local top = args["top"]

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

local cjson = require "cjson"

local bureau_info = ngx.location.capture("/dsideal_yy/org/getSubBureauByBureauId?bureau_id="..bureau_id.."&random="..math.random(1000))
local bureau_str = bureau_info.body
local bureau_json = cjson.decode(bureau_str)

local bureau_ids = ""
for i=1,#bureau_json.list do
	bureau_ids = bureau_ids .. bureau_json.list[i].id ..","
end

if #bureau_ids == 0 then
	bureau_ids = "-1"
else	
	bureau_ids = string.sub(bureau_ids,0,#bureau_ids-1)
end

local sort_info = ngx.location.capture("/dsideal_yy/res/getResCountByResTypeBureauId?bureau_ids="..bureau_ids.."&res_type="..res_type.."&random="..math.random(1000))
local sort_str = sort_info.body
local sort_json = cjson.decode(sort_str)

local result_sort_tab = {}

if #sort_json.list ~= 0 then

	local temp_key = tostring(math.random(1000))..tostring(math.random(1000))..tostring(math.random(1000))
	for i=1,#sort_json.list do
		ssdb_db:zset(temp_key,sort_json.list[i].bureau_id,sort_json.list[i].count)
	end

	local i_count = 1

	local result_sort = ssdb_db:zrrange(temp_key,0,top)

	for i=1,#result_sort,2 do
		local result_sort_info = {}
		result_sort_info["bureau_id"] = result_sort[i]		
		result_sort_info["bureau_name"] = string.gsub(cache:hget("t_base_organization_"..result_sort[i],"org_name"),"教育局","",1)
		result_sort_info["count"] = result_sort[i+1]
		result_sort_tab[i_count] = result_sort_info
		i_count = i_count+1	
	end


	ssdb_db:zclear(temp_key)

end

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)

local result = {}
result["success"] = true
result["list"] = result_sort_tab

ngx.print(tostring(cjson.encode(result)))






