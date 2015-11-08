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
if args["workroom_id"] == nil or args["workroom_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"workroom_id参数错误！\"}")
    return
end
local workroom_id = args["workroom_id"]

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

--获取名师总数 陈续刚 2015.08.15 开始
local teacher_count = "0"
local base_sql = "SELECT teacher_count as teacher_num from t_base_workroom_tj wt where wt.workroom_id = "..workroom_id.." and wt.stage_id=0";
local base_result = mysql_db:query(base_sql)
if base_result and #base_result ==1 then
	teacher_count = tostring(base_result[1]["teacher_count"])
end
--获取名师总数 陈续刚 2015.08.15 结束
--获取资源统计

local resource_tj_tab = {teacher_count="0",resource_count="0",today_upload="0",down_count="0"}
local resource_tj_str = ssdb_db:multi_hget("workroom_tj_"..workroom_id,"teacher_count","resource_count","today_upload","down_count")
for i=1,#resource_tj_str,2 do
    resource_tj_tab[resource_tj_str[i]]=resource_tj_str[i+1]
end
	resource_tj_tab[teacher_count]=teacher_count
--[[
--获取该工作室中有多少教师
local person_str = "filter=person_id"
local person_info = ngx.location.capture("/dsideal_yy/ypt/workroom/getTeachersForTJ?workroom_id="..workroom_id.."&random="..math.random(1000))
local person_josn =  cjson.decode(person_info.body)
local person_list = person_josn.list
for i=1,#person_list do
    person_str = person_str..","..person_list[i].person_id    
end
person_str = person_str..";"
]]
--UFT_CODE
local function urlEncodeasdasd(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end
--转url_code
local function urlEncode(str)
    if (str) then
        str = string.gsub (str, "\n", "\r\n")
        str = string.gsub (str, "([^%w ])",
        function (c) return string.format ("%%%%%02X", string.byte(c)) end)
    end
    return str
end
--获取最热资源
local resource_hot_tab= {}
--if #person_list ~=0 then
    --res = mysql_db:query("SELECT SQL_NO_CACHE id FROM t_resource_info_sphinxse WHERE query='"..person_str.."filter=res_type,1,2,4;filter=release_status,1,3;groupby=attr:resource_id_int;groupsort=down_count desc;limit=10'")
	res = mysql_db:query("SELECT SQL_NO_CACHE id FROM t_base_publish_sphinxse WHERE query='filter=b_delete,0;filter=pub_target,"..workroom_id..";sort=attr_desc:DOWN_COUNT;limit=10'")
    for i=1,#res do
		local  res_hot_tab = {}
		local iid = cache:hget("publish_"..res[i]["id"],"obj_info_id")	
		--local  res_info = cache:hmget("resource_"..iid,"resource_title","resource_format","resource_page","file_id","thumb_id","preview_status","width","height","for_urlencoder_url","for_iso_url","res_type","beike_type","resource_size_int")
		local  res_info = ssdb_db:multi_hget("resource_"..iid,"resource_title","resource_format","resource_page","file_id","thumb_id","preview_status","width","height","for_urlencoder_url","for_iso_url","res_type","beike_type","resource_size_int")
		res_hot_tab["iid"] = iid
		res_hot_tab["resource_title"] = res_info[2]
		res_hot_tab["resource_format"] = res_info[4]
		res_hot_tab["resource_page"] = res_info[6]
		res_hot_tab["file_id"] = res_info[8]
		res_hot_tab["thumb_id"] = res_info[10]
		res_hot_tab["preview_status"] = res_info[12]
		res_hot_tab["width"] = res_info[14]
		res_hot_tab["height"] = res_info[16]
		res_hot_tab["for_urlencoder_url"] = res_info[18]
		res_hot_tab["for_iso_url"] = res_info[20]
		res_hot_tab["res_type"] = res_info[22]
		res_hot_tab["beike_type"] = res_info[24]
		res_hot_tab["resource_size_int"] = res_info[26]
		res_hot_tab["url_code"] = urlEncode(res_info[2])
		resource_hot_tab[i] = res_hot_tab
    end
--end

--获取最新资源
local resource_new_tab= {}
--if #person_list ~=0 then
    --res = mysql_db:query("SELECT SQL_NO_CACHE id FROM t_resource_info_sphinxse WHERE query='"..person_str.."filter=res_type,1,2,4;filter=release_status,1,3;groupby=attr:resource_id_int;groupsort=ts desc;limit=10'")
	res = mysql_db:query("SELECT SQL_NO_CACHE id FROM t_base_publish_sphinxse WHERE query='filter=b_delete,0;filter=pub_target,"..workroom_id..";sort=attr_desc:INFO_TS;limit=10'")
    for i=1,#res do
		local  res_new_tab = {}
		local iid = cache:hget("publish_"..res[i]["id"],"obj_info_id")
		--local  res_info = cache:hmget("resource_"..iid,"resource_title","resource_format","resource_page","file_id","thumb_id","preview_status","width","height","for_urlencoder_url","for_iso_url","res_type","beike_type","resource_size_int")
		local  res_info = ssdb_db:multi_hget("resource_"..iid,"resource_title","resource_format","resource_page","file_id","thumb_id","preview_status","width","height","for_urlencoder_url","for_iso_url","res_type","beike_type","resource_size_int")
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
		resource_new_tab[i] = res_new_tab
    end
--end

workroom_tj["resource_tj"] = resource_tj_tab
workroom_tj["resource_hot"] = resource_hot_tab
workroom_tj["resource_new"] = resource_new_tab

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
mysql_db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false)
ngx.say(tostring(cjson.encode(workroom_tj)))