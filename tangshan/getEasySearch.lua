local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--关键字
if args["keyword"] == nil or args["keyword"] == "" then
    ngx.say("{\"success\":false,\"info\":\"keyword参数错误！\"}")
    return
end
local keyword = ngx.decode_base64(args["keyword"])..";"

--地区
if args["area_id"] == nil or args["area_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"area_id参数错误！\"}")
    return
end
local area_id = args["area_id"]

--媒体类型
if args["mtype_id"] == nil or args["mtype_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"mtype_id参数错误！\"}")
    return
end
local mtype_id = args["mtype_id"]

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

--拼group_id条件
local area_str = "filter=group_id,1,"..area_id..";"

--拼媒体类型条件
local mtype_str = ""
if mtype_id ~= "-1" then
	mtype_str = "filter=resource_type,"..mtype_id..";"
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

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local myPrime = require "resty.PRIME";
local cjson = require "cjson"

function encodeURI(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end

local offset = pageSize*pageNumber-pageSize
local limit = pageSize
local str_maxmatches = "10000"

local res = db:query("SELECT SQL_NO_CACHE id FROM t_resource_info_sphinxse WHERE query=\'"..keyword..area_str..mtype_str.."filter=release_status,1,3;filter=res_type,1;sort=attr_desc:ts;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")

--去第二个结果集中的Status中截取总个数
local res1 = db:read_result()
local _,s_str = string.find(res1[1]["Status"],"found: ")
local e_str = string.find(res1[1]["Status"],", time:")
local totalRow = string.sub(res1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

local resourceUtil = require "base.resource.model.ResourceUtil";
local resourceJson = resourceUtil:getResourceInfoByIds(res)

--[[
local res_tab = {}
for i=1,#res do
	local res_info_tab = {}
	local res_info_id = res[i]["id"]
	local res_info = cache:hmget("resource_"..res_info_id,"resource_id_int","resource_title","resource_type_name","resource_format","resource_page","resource_size","create_time","down_count","file_id","thumb_id","width","height","for_urlencoder_url","for_iso_url","parent_structure_name","preview_status","app_type_id","scheme_id_int","resource_type")
	res_info_tab["iid"] = res_info_id
	res_info_tab["resource_id_int"] = res_info[1]
	res_info_tab["resource_title"] = res_info[2]
	res_info_tab["resource_type_name"] = res_info[3]
	res_info_tab["resource_format"] = res_info[4]
	res_info_tab["resource_page"] = res_info[5]
	res_info_tab["resource_size"] = res_info[6]
	res_info_tab["create_time"] = res_info[7]
	res_info_tab["down_count"] = res_info[8]
	res_info_tab["file_id"] = res_info[9]
	res_info_tab["thumb_id"] = res_info[10]
	res_info_tab["width"] = res_info[11]
	res_info_tab["height"] = res_info[12]
	res_info_tab["for_urlencoder_url"] = res_info[13]
	res_info_tab["for_iso_url"] = res_info[14]
	res_info_tab["parent_structure_name"] = res_info[15]
	res_info_tab["preview_status"] = res_info[16]
	res_info_tab["resource_type"] = res_info[19]
	res_info_tab["url_code"] = encodeURI(res_info[2])
	ngx.log(ngx.ERR,res_info[18])
	ngx.log(ngx.ERR,res_info[17])
	--调用获取应用类型名称接口
	local appname_body = ngx.location.capture("/dsideal_yy/apptype/get_apptypename?scheme_id="..res_info[18].."&app_type_id="..res_info[17])
	res_info_tab["app_type_name"] = appname_body.body
	
	res_tab[i] = res_info_tab		
end

]]
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
