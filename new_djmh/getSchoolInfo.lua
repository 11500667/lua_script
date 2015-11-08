local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

local cjson = require "cjson"

--bureau_id参数 单位ID
if args["bureau_id"] == nil or args["bureau_id"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"bureau_id参数错误！\"}")
	return
end
local bureau_id = args["bureau_id"]

--school_type参数 1小学  2初中  3高中  4完全中学  5九年一贯制 6十二年一贯制
if args["school_type"] == nil or args["school_type"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"school_type参数错误！\"}")
	return
end
local school_type = args["school_type"]

--一页显示多少
if args["pageSize"] == nil or args["pageSize"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"pageSize参数错误！\"}")
    return
end
local pageSize = args["pageSize"]

--第几页
if args["pageNumber"] == nil or args["pageNumber"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"pageNumber参数错误！\"}")
    return
end
local pageNumber = args["pageNumber"]

--连接mysql数据库
local mysql = require "resty.mysql"
local mysql_db = mysql:new()
mysql_db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024*1024
}

--连接redis服务器
local redis = require "resty.redis"
local redis_db = redis:new()
local ok,err = redis_db:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--拼school_type条件
local schooltype_str = ""
if school_type ~= "0" then
	schooltype_str = " AND SCHOOL_TYPE="..school_type
end


local djmh_school_ts = redis_db:get("djmh_school_ts_"..bureau_id.."_"..schooltype_str.."_"..pageNumber)
local generate_school_ts = redis_db:get("generate_school_ts_"..bureau_id)

if generate_school_ts == ngx.null then
	redis_db:set("generate_school_ts_"..bureau_id,math.random(1000000))
end

if djmh_school_ts == ngx.null or djmh_school_ts ~= generate_school_ts then
	
	redis_db:set("djmh_school_ts_"..bureau_id.."_"..schooltype_str.."_"..pageNumber,generate_school_ts)	

	local school_sql = mysql_db:query("SELECT COUNT(1) AS totalRow FROM t_base_organization WHERE ORG_TYPE=2 AND DISTRICT_ID = "..bureau_id..schooltype_str)
	local totalRow = tonumber(school_sql[1]["totalRow"])
	local offset = math.floor((pageNumber-1)*pageSize)
	local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

	local school_sql = mysql_db:query("SELECT org_id,org_name,school_type FROM t_base_organization WHERE ORG_TYPE=2 AND DISTRICT_ID = "..bureau_id..schooltype_str.." LIMIT "..offset..","..pageSize)

	local school_info_tab = {}
	for i=1,#school_sql do
		local school_info_res = {}
		school_info_res["org_id"] = school_sql[i]["org_id"]
		school_info_res["org_name"] = school_sql[i]["org_name"]
		school_info_res["school_type"] = school_sql[i]["school_type"]
		school_info_tab[i] = school_info_res
	end

	local result = {} 
	result["list"] = school_info_tab
	result["totalRow"] = totalRow
	result["totalPage"] = totalPage
	result["pageNumber"] = pageNumber
	result["pageSize"] = pageSize
	result["success"] = true
	
	cjson.encode_empty_table_as_object(false)
	redis_db:set("djmh_school_"..bureau_id.."_"..schooltype_str.."_"..pageNumber,tostring(cjson.encode(result)))

end

local school_info = redis_db:get("djmh_school_"..bureau_id.."_"..schooltype_str.."_"..pageNumber)

--mysql放回连接池
mysql_db:set_keepalive(0,v_pool_size)
redis_db:set_keepalive(0,v_pool_size)

ngx.print(school_info)



















