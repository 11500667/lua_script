local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

local cjson = require "cjson"

--单位ID
if args["bureau_id"] == nil or args["bureau_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"bureau_id参数错误！\"}")
    return
end
local bureau_id = args["bureau_id"]

--show_size参数 显示多少条
if args["show_size"] == nil or args["show_size"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"show_size参数错误！\"}")
	return
end
local show_size = args["show_size"]

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

--点播排行
local dbph_res = mysql_db:query("SELECT SQL_NO_CACHE id FROM t_wkds_info_sphinxse WHERE query='filter=group_id,"..bureau_id..";sort=attr_desc:play_count;limit="..show_size.."';")
local dbph_tab = {}
for i=1,#dbph_res do
	local dbph_info = {}	
	local wk_id = dbph_res[i]["id"]
	local wk_info = redis_db:hmget("wkds_"..wk_id,"wkds_name","play_count","wkds_id_int")	
	dbph_info["iid"] = wk_id
	dbph_info["wkds_name"] = wk_info[1]
	dbph_info["play_count"] = wk_info[2]	
	dbph_info["wkds_id_int"] = wk_info[3]	
	dbph_tab[i] = dbph_info
end

--下载排行
local xzph_res = mysql_db:query("SELECT SQL_NO_CACHE id FROM t_wkds_info_sphinxse WHERE query='filter=group_id,"..bureau_id..";sort=attr_desc:download_count;limit="..show_size.."';")
local xzph_tab = {}
for i=1,#xzph_res do
	local xzph_info = {}	
	local wk_id = xzph_res[i]["id"]
	local wk_info = redis_db:hmget("wkds_"..wk_id,"wkds_name","download_count","wkds_id_int","play_count")	
	xzph_info["iid"] = wk_id
	xzph_info["wkds_name"] = wk_info[1]
	xzph_info["count"] = wk_info[2]	
	xzph_info["wkds_id_int"] = wk_info[3]
	xzph_info["play_count"] = wk_info[4]
	xzph_tab[i] = xzph_info
end

--教师排行
local jsph_res = mysql_db:query("SELECT person_id,teacher_name,count(1) as count FROM t_wkds_info WHERE GROUP_ID="..bureau_id.." GROUP BY PERSON_ID  ORDER BY COUNT(1) DESC LIMIT "..show_size..";")
local jsph_tab = {}
for i=1,#jsph_res do
	local jsph_info = {}		
	
	jsph_info["person_id"] = jsph_res[i]["person_id"]
	jsph_info["person_name"] = jsph_res[i]["teacher_name"]
	jsph_info["count"] = jsph_res[i]["count"]
	
	jsph_tab[i] = jsph_info
end

--学校排行
local xxph_res = mysql_db:query("SELECT t2.bureau_id,COUNT(1) as count FROM t_wkds_info t1 inner join t_base_person t2 on t1.person_id = t2.person_id where t1.group_id="..bureau_id.." GROUP BY t2.bureau_id ORDER BY COUNT(1) DESC LIMIT "..show_size..";")
local xxph_tab = {}
for i=1,#xxph_res do
	local xxph_info = {}		
	local bureau_id = xxph_res[i]["bureau_id"]
	xxph_info["bureau_id"] = bureau_id
	xxph_info["bureau_name"] = redis_db:hget("t_base_organization_"..bureau_id,"org_name")
	xxph_info["count"] = xxph_res[i]["count"]
	xxph_tab[i] = xxph_info
end

local result = {} 
--点播排行
result["dbph"] = dbph_tab
--下载排行
result["xzph"] = xzph_tab
--教师排行
result["jsph"] = jsph_tab
--学校排行
result["xxph"] = xxph_tab
result["success"] = true

--mysql放回连接池
mysql_db:set_keepalive(0,v_pool_size)
--redis放回连接池
redis_db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false)
ngx.print(tostring(cjson.encode(result)))













