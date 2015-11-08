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

local cjson = require "cjson"

function encodeURI(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end

--最新上传 resource_newUpload_area_200004  ssdb_db:multi_hget
local newUpload_tab = {}
local newUpload_ids= db:query("SELECT SQL_NO_CACHE id FROM t_resource_info_sphinxse WHERE query='filter=group_id,1,"..area_id..";filter=release_status,1,3;filter=res_type,1;sort=attr_desc:ts;offset=0;limit="..pageSize.."'")
for i=1,#newUpload_ids do
	local newUpload_res = {}
	local resource_info_id = newUpload_ids[i]["id"]
	--local res_info = cache:hmget("resource_"..resource_info_id,"resource_id_int","resource_title","resource_type_name","resource_format","resource_page","resource_size","create_time","down_count","file_id","thumb_id","width","height","for_urlencoder_url","for_iso_url","parent_structure_name","preview_status","app_type_id","scheme_id_int","person_name")
	local res_info = ssdb_db:multi_hget("resource_"..resource_info_id,"resource_id_int","resource_title","resource_type_name","resource_format","resource_page","resource_size","create_time","down_count","file_id","thumb_id","width","height","for_urlencoder_url","for_iso_url","parent_structure_name","preview_status","app_type_id","scheme_id_int","person_name")
	newUpload_res["iid"] = resource_info_id
	newUpload_res["resource_id_int"] = res_info[2]
	newUpload_res["resource_title"] = res_info[4]
	--newUpload_res["resource_type_name"] = res_info[6]
	newUpload_res["resource_format"] = res_info[8]
	newUpload_res["resource_page"] = res_info[10]
	--newUpload_res["resource_size"] = res_info[12]
	--newUpload_res["create_time"] = res_info[14]
	newUpload_res["down_count"] = res_info[16]
	newUpload_res["file_id"] = res_info[18]
	newUpload_res["thumb_id"] = res_info[20]
	newUpload_res["width"] = res_info[22]
	newUpload_res["height"] = res_info[24]
	newUpload_res["for_urlencoder_url"] = res_info[26]
	newUpload_res["for_iso_url"] = res_info[28]
	--newUpload_res["parent_structure_name"] = res_info[30]
	newUpload_res["preview_status"] = res_info[32]
	newUpload_res["url_code"] = encodeURI(res_info[4])
	newUpload_res["person_name"] = res_info[38]
	newUpload_tab[i] = newUpload_res			
end

--最新下载 resource_hotDown_area_200004
local hotDown_tab = {}
local hotDown_ids= db:query("SELECT SQL_NO_CACHE id FROM t_resource_info_sphinxse WHERE query='filter=group_id,1,"..area_id..";filter=release_status,1,3;filter=res_type,1;sort=attr_desc:down_count;offset=0;limit="..pageSize.."'")
--local hotDown_ids = ssdb_db:zrrange("resource_hotDown_area_"..area_id,0,pageSize)
for i=1,#hotDown_ids do
	local hotDown_res = {}
	local resource_info_id = hotDown_ids[i]["id"]
	--local res_info = cache:hmget("resource_"..resource_info_id,"resource_id_int","resource_title","resource_type_name","resource_format","resource_page","resource_size","create_time","down_count","file_id","thumb_id","width","height","for_urlencoder_url","for_iso_url","parent_structure_name","preview_status","app_type_id","scheme_id_int")
	local res_info = ssdb_db:multi_hget("resource_"..resource_info_id,"resource_id_int","resource_title","resource_type_name","resource_format","resource_page","resource_size","create_time","down_count","file_id","thumb_id","width","height","for_urlencoder_url","for_iso_url","parent_structure_name","preview_status","app_type_id","scheme_id_int")
	hotDown_res["iid"] = resource_info_id
	hotDown_res["resource_id_int"] = res_info[2]
	hotDown_res["resource_title"] = res_info[4]
	--hotDown_res["resource_type_name"] = res_info[6]
	hotDown_res["resource_format"] = res_info[8]
	hotDown_res["resource_page"] = res_info[10]
	--hotDown_res["resource_size"] = res_info[12]
	--hotDown_res["create_time"] = res_info[14]
	hotDown_res["down_count"] = res_info[16]
	hotDown_res["file_id"] = res_info[18]
	hotDown_res["thumb_id"] = res_info[20]
	hotDown_res["width"] = res_info[22]
	hotDown_res["height"] = res_info[24]
	hotDown_res["for_urlencoder_url"] = res_info[26]
	hotDown_res["for_iso_url"] = res_info[28]
	--hotDown_res["parent_structure_name"] = res_info[30]
	hotDown_res["preview_status"] = res_info[32]
	hotDown_res["url_code"] = encodeURI(res_info[4])
	hotDown_tab[i] = hotDown_res
end

--最活跃用户 active_user_200004
local activeUser_tab = {}
local activeUser_count = 1
local activeUser_ids = ssdb_db:zrrange("active_user_"..area_id,0,pageSize)
for i=1,#activeUser_ids,2 do
	local activeUser_res = {}
	activeUser_res["name"] = cache:hget("person_"..activeUser_ids[i].."_5","person_name")
	activeUser_res["count"] = activeUser_ids[i+1]
	activeUser_tab[activeUser_count] = activeUser_res
	activeUser_count = activeUser_count+1
end

--最活跃机构 active_bureau_200004
local activeBureau_tab = {}
local activeBureau_count = 1
local activeBureau_ids = ssdb_db:zrrange("active_bureau_"..area_id,0,pageSize)
for i=1,#activeBureau_ids,2 do
	local activeBureau_res = {}
	activeBureau_res["name"] = cache:hget("t_base_organization_"..activeBureau_ids[i],"org_name")
	activeBureau_res["count"] = activeBureau_ids[i+1]
	activeBureau_tab[activeBureau_count] = activeBureau_res
	activeBureau_count = activeBureau_count+1
end

local result = {}
result["newUpload_list"] = newUpload_tab 
result["hotDown_list"] = hotDown_tab
result["activeUser_list"] = activeUser_tab
result["activeBureau_list"] = activeBureau_tab
result["success"] = true


--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)

ngx.say(cjson.encode(result))
