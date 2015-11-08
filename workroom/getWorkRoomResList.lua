local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

local cjson = require "cjson"

--获取教师ID
if args["teacher_id"] == nil or args["teacher_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"teacher_id参数错误！\"}")
    return
end
local teacher_id = args["teacher_id"]

--获取res_type
if args["res_type"] == nil or args["res_type"] == "" then
    ngx.say("{\"success\":false,\"info\":\"res_type参数错误！\"}")
    return
end
local res_type = args["res_type"]

--获取res_cascade_type
if args["res_cascade_type"] == nil or args["res_cascade_type"] == "" then
    ngx.say("{\"success\":false,\"info\":\"res_cascade_type参数错误！\"}")
    return
end
local res_cascade_type = args["res_cascade_type"]

--获取每页显示多少条
if args["pageSize"] == nil or args["pageSize"] == "" then
    ngx.say("{\"success\":false,\"info\":\"pageSize参数错误！\"}")
    return
end
local pageSize = args["pageSize"]

--获取每页显示多少条
if args["pageNumber"] == nil or args["pageNumber"] == "" then
    ngx.say("{\"success\":false,\"info\":\"pageNumber参数错误！\"}")
    return
end
local pageNumber = args["pageNumber"]

--拼teacher_id条件
local personid_str = "filter=person_id,"..teacher_id..";"

--拼res_type条件
local restype_str = "filter=res_type,"..res_type..";"

--拼res_cascade_type条件
local resourcetype_str = ""
if res_cascade_type ~= "-1" then
    resourcetype_str = "filter=resource_type,"..res_cascade_type..";"
end

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
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

--UFT_CODE
--[[local function urlEncode(str)
    if (str) then
        str = string.gsub (str, "\n", "\r\n")
        str = string.gsub (str, "([^%w ])",
        function (c) return string.format ("%%%%%02X", string.byte(c)) end)
    end
    return str
end]]
function urlEncode(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end
--计算offset和limit
local offset = pageSize*pageNumber-pageSize
local limit = pageSize
--设置查询最大匹配的数量
local str_maxmatches = "3000"

local res = db:query("SELECT SQL_NO_CACHE id FROM t_resource_info_sphinxse WHERE query='"..personid_str..restype_str..resourcetype_str.."groupby=attr:resource_id_int;groupsort=ts desc;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")

--去第二个结果集中的Status中截取总个数
local res1 = db:read_result()
local _,s_str = string.find(res1[1]["Status"],"found: ")
local e_str = string.find(res1[1]["Status"],", time:")
local totalRow = string.sub(res1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

local resource_tab= {}
for i=1,#res do
    local  res_tab = {}
    --local  res_info = cache:hmget("resource_"..res[i]["id"],"resource_title","resource_type_name","resource_size","create_time","down_count","file_id","width","height","resource_format","resource_page","thumb_id","preview_status","for_urlencoder_url","for_iso_url")
	local  res_info = ssdb:multi_hget("resource_"..res[i]["id"],"resource_title","resource_type_name","resource_size","create_time","down_count","file_id","width","height","resource_format","resource_page","thumb_id","preview_status","for_urlencoder_url","for_iso_url")
    res_tab["iid"] = res[i]["id"]        
    res_tab["resource_title"] = res_info[2]    
    res_tab["resource_type_name"] = res_info[4]
    res_tab["resource_size"] = res_info[6]
    res_tab["create_time"] = res_info[8]
    res_tab["down_count"] = res_info[10]
    res_tab["file_id"] = res_info[12]    
    res_tab["width"] = res_info[14]
    res_tab["height"] = res_info[16]
    res_tab["resource_format"] = res_info[18]
    res_tab["resource_page"] = res_info[20]
    res_tab["thumb_id"] = res_info[22]
    res_tab["preview_status"] = res_info[24]
    res_tab["for_urlencoder_url"] = res_info[26]
    res_tab["for_iso_url"] = res_info[28]
    res_tab["url_code"] = urlEncode(res_info[2])
    resource_tab[i] = res_tab
end

--返回的table
local result = {}

result["success"] = true
result["totalRow"] = totalRow
result["totalPage"] = totalPage
result["pageNumber"] = pageNumber
result["pageSize"] = pageSize
result["list"] = resource_tab

--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0,v_pool_size)
--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
cjson.encode_empty_table_as_object(false)
ngx.say(tostring(cjson.encode(result)))