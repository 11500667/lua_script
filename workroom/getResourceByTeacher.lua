local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

local cjson = require "cjson"

--获取工作室ID
if args["workroom_id"] == nil or args["workroom_id"] == ""
 or args["teacher_id"] == nil or args["teacher_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"workroom_id or teacher_id 参数错误！\"}")
    return
end
local workroom_id = args["workroom_id"]
local teacher_id = args["teacher_id"]

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

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
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local workroom_tj = {}
local res = ""

--UFT_CODE
local function urlEncode(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end

--end

--获取最新资源
local resource_new_tab= {}
res = mysql_db:query("SELECT SQL_NO_CACHE id FROM t_base_publish_sphinxse WHERE query='filter=b_delete,0;filter=pub_target,"..workroom_id..";filter=person_id,"..teacher_id..";sort=attr_desc:INFO_TS;limit=5'")
for i=1,#res do
	local  res_new_tab = {}
	local iid = cache:hget("publish_"..res[i]["id"],"obj_info_id")
	--local  res_info = cache:hmget("resource_"..iid,"resource_title","resource_format","resource_page","file_id","thumb_id","preview_status","width","height","for_urlencoder_url","for_iso_url","res_type","beike_type","resource_size_int","create_time")
	local  res_info = ssdb_db:multi_hget("resource_"..iid,"resource_title","resource_format","resource_page","file_id","thumb_id","preview_status","width","height","for_urlencoder_url","for_iso_url","res_type","beike_type","resource_size_int","create_time")
	res_new_tab["iid"] = iid
	res_new_tab["resource_title"] = res_info[2]
	res_new_tab["resource_format"] = res_info[4]
	res_new_tab["resource_page"] = res_info[6]
	res_new_tab["file_id"] = res_info[8]
	res_new_tab["thumb_id"] = res_info[10]
	res_new_tab["preview_status"] = res_info[12]
	res_new_tab["width"] = res_info[14]
	res_new_tab["height"] = res_info[16]
	res_new_tab["for_urlencoder_url"] = res_info[18]
	res_new_tab["for_iso_url"] = res_info[20]
	res_new_tab["res_type"] = res_info[22]
	res_new_tab["beike_type"] = res_info[24]
	res_new_tab["resource_size_int"] = res_info[26]
	res_new_tab["url_code"] = urlEncode(res_info[2])
	res_new_tab["create_time"] = res_info[28]
	resource_new_tab[i] = res_new_tab
end

workroom_tj["success"] = true
workroom_tj["resource_new"] = resource_new_tab

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
mysql_db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false)
ngx.say(tostring(cjson.encode(workroom_tj)))