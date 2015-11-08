local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

local cjson = require "cjson"

--资源类型
if args["resource_type"] == nil or args["resource_type"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"resource_type参数错误！\"}")
    return
end
local resource_type = args["resource_type"]

--人员ID
if args["person_id"] == nil or args["person_id"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"person_id参数错误！\"}")
    return
end
local person_id = args["person_id"]

--人员身份ID
if args["identity_id"] == nil or args["identity_id"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"identity_id参数错误！\"}")
    return
end
local identity_id = args["identity_id"]

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

--
if args["beike_type"] == nil or args["beike_type"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"beike_type参数错误！\"}")
    return
end
local beike_type = args["beike_type"]

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

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--拼资源类型条件
local resourcetype_str = ""
if resource_type ~= "-1" then
	resourcetype_str = "filter=resource_type,"..resource_type..";"
end

--拼人员条件
local personid_str = "filter=person_id,"..person_id..";"

--拼系统类型
local restype_str = "filter=res_type,10;"

local beike_type_str = "filter=bk_type,"..beike_type..";";


local offset = pageSize*pageNumber-pageSize
local limit = pageSize
local str_maxmatches = "10000"

local res = db:query("SELECT SQL_NO_CACHE id FROM t_resource_info_sphinxse WHERE query='"..resourcetype_str..personid_str..restype_str..beike_type_str.."filter=release_status,1,2,3,4;sort=attr_desc:ts;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")

--去第二个结果集中的Status中截取总个数
local res1 = db:read_result()
local _,s_str = string.find(res1[1]["Status"],"found: ")
local e_str = string.find(res1[1]["Status"],", time:")
local totalRow = string.sub(res1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)
--[[
local resource_tab = {}
for i=1,#res do
    local resource_info = {}
	local iid = res[i]["id"]
	local resource_value = cache:hmget("resource_"..iid,"resource_id_int","resource_title","resource_format","file_id","thumb_id","preview_status","width","height","resource_id_char","for_urlencoder_url","for_iso_url","m3u8_status","m3u8_url")
	resource_info["iid"] = iid
	resource_info["resource_id_int"] = resource_value[1]
	resource_info["resource_title"] = resource_value[2]
	resource_info["resource_format"] = resource_value[3]
	resource_info["file_id"] = resource_value[4]
	resource_info["thumb_id"] = resource_value[5]
	resource_info["preview_status"] = resource_value[6]
	resource_info["width"] = resource_value[7]
	resource_info["height"] = resource_value[8]
	resource_info["resource_id_char"] = resource_value[9]
	resource_info["for_urlencoder_url"] = resource_value[10]
	resource_info["for_iso_url"] = resource_value[11]
	resource_info["m3u8_status"] = resource_value[12]
	resource_info["m3u8_url"] = resource_value[13]
	resource_tab[i] = resource_info
end
]]

local resourceUtil = require "base.resource.model.ResourceUtil";
local resourceJson = resourceUtil:getResourceInfoByIds(res)

local result = {}
result["success"] = true
result["totalRow"] = totalRow
result["totalPage"] = totalPage
result["pageNumber"] = pageNumber
result["pageSize"] = pageSize
result["list"] = resourceJson

--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false)
ngx.say(tostring(cjson.encode(result)))





