local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

local cjson = require "cjson"

--评比ID
if args["rating_id"] == nil or args["rating_id"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"rating_id参数错误！\"}")
    return
end
local rating_id = args["rating_id"]

--第几页
if args["pageNumber"] == nil or args["pageNumber"] == "" then
    ngx.say("{\"success\":false,\"info\":\"pageNumber参数错误！\"}")
    return
end
local pageNumber = args["pageNumber"]

--一页显示多少
if args["pageSize"] == nil or args["pageSize"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"pageSize参数错误！\"}")
    return
end
local pageSize = args["pageSize"]

--学段ID
if args["stage_id"] == nil or args["stage_id"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"stage_id参数错误！\"}")
    return
end
local stage_id = args["stage_id"]

--学科ID
if args["subject_id"] == nil or args["subject_id"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"subject_id参数错误！\"}")
    return
end
local subject_id = args["subject_id"]

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

--创建ssdb连接
local ssdblib = require "resty.ssdb"
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--加码
function encodeURI(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end

local stage_str = ""
if stage_id ~= "-1" then
	stage_str = " AND stage_id="..stage_id
end

local subject_str = ""
if subject_id ~= "-1" then
	subject_str = " AND subject_id="..subject_id
end

local w_type
if args["w_type"] == nil or args["w_type"] == "" then
  w_type = ""
else
  w_type = " AND w_type="..args["w_type"]
end

local resource_count = mysql_db:query("SELECT count(1) as count FROM t_rating_resource WHERE rating_id = "..rating_id.." AND resource_status = 1 "..stage_str..subject_str..w_type.." ORDER BY ts DESC")

local offset = pageSize*pageNumber-pageSize
local limit = pageSize
local totalRow = resource_count[1]["count"]
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

local resource_info = mysql_db:query("SELECT id,resource_info_id,person_name,bureau_name,ts FROM t_rating_resource WHERE rating_id = "..rating_id.." AND resource_status = 1 "..stage_str..subject_str..w_type.." ORDER BY ts DESC LIMIT "..offset..","..limit..";")

local resource_tab = {}

if resource_info ~= nil then
	for i=1,#resource_info do
		local resource_res = {}
		local id = resource_info[i]["id"]
		local resource_info_id = resource_info[i]["resource_info_id"]
		local person_name = resource_info[i]["person_name"]
		local bureau_name = resource_info[i]["bureau_name"]
		local ts = resource_info[1]["ts"]
		local create_time = string.sub(ts,0,4).."-"..string.sub(ts,5,6).."-"..string.sub(ts,7,8)
		local res_info = ssdb:multi_hget("resource_"..resource_info_id,"resource_format","resource_page","resource_size","file_id","thumb_id","preview_status","width","height","resource_title")
		resource_res["id"] = id
		resource_res["resource_format"] = res_info[2]
	  resource_res["resource_page"] = res_info[4]
	  resource_res["resource_size"] = res_info[6]		
	  resource_res["file_id"] = res_info[8]
	  resource_res["thumb_id"] = res_info[10]
	  resource_res["preview_status"] = res_info[12]
	  resource_res["width"] = res_info[14]
	  resource_res["height"] = res_info[16]
	  resource_res["resource_title"] = res_info[18]
	  resource_res["url_code"] = encodeURI(res_info[18])
		resource_res["person_name"] = person_name
		resource_res["org_name"] = bureau_name
		resource_tab[i] = resource_res
	end
end

local result = {} 
result["list"] = resource_tab
result["totalRow"] = totalRow
result["totalPage"] = totalPage
result["pageNumber"] = pageNumber
result["pageSize"] = pageSize
result["success"] = true

mysql_db:set_keepalive(0,v_pool_size)
redis_db:set_keepalive(0,v_pool_size)
ssdb:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))













