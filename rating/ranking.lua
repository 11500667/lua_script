local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

local cjson = require "cjson"

--显示多少条
if args["show_size"] == nil or args["show_size"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"show_size参数错误！\"}")
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

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--加码
function encodeURI(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end

local rating_type
if args["rating_type"] == nil or args["rating_type"] == "" then
  rating_type = 1
else
  rating_type = args["rating_type"]
end

local w_type
if args["w_type"] == nil or args["w_type"] == "" then
  w_type = ""
else
  w_type = " AND w_type="..args["w_type"]
end


--热门资源排行
local rmzy_tab = {}


local rmzy_res = mysql_db:query("SELECT id,resource_info_id,person_name,bureau_name,ts,subject_id FROM t_rating_resource WHERE resource_status = 3 and rating_id in (select id from t_rating_info where rating_type="..rating_type..w_type..") ORDER BY vote_count DESC LIMIT "..show_size..";")
if rmzy_res[1] ~= nil then
	for i=1,#rmzy_res do
		local rmzy = {}
		local id = rmzy_res[i]["id"]
		local resource_info_id = rmzy_res[i]["resource_info_id"]
		local person_name = rmzy_res[i]["person_name"]
		local bureau_name = rmzy_res[i]["bureau_name"]				
		local subject_id = rmzy_res[i]["subject_id"]
		local res_info
		if rating_type ==1 then
		res_info = ssdb_db:multi_hget("resource_"..resource_info_id,"resource_format","resource_page","resource_size","file_id","thumb_id","preview_status","width","height","resource_title")
		
		rmzy["resource_format"] = res_info[2]
		rmzy["resource_page"] = res_info[4]
		rmzy["resource_size"] = res_info[6]		
		rmzy["file_id"] = res_info[8]
		rmzy["thumb_id"] = res_info[10]
		rmzy["preview_status"] = res_info[12]
		rmzy["width"] = res_info[14]
		rmzy["height"] = res_info[16]
		rmzy["resource_title"] = res_info[18]
		rmzy["url_code"] = encodeURI(res_info[18])
		else
		res_info = redis_db:hmget("wkds_"..resource_info_id,"wkds_id_int","wkds_id_char","scheme_id","structure_id","wkds_name","study_instr","teacher_name","play_count","score_count","create_time","download_count","downloadable","person_id","table_pk","group_id","content_json","wk_type","wk_type_name","type_id","uploader_id")
      rmzy["resource_info_id"] = resource_info_id
      rmzy["wkds_id_int"] = res_info[1]
      rmzy["wkds_id_char"] = res_info[2]
      rmzy["scheme_id_int"] = res_info[3]
      rmzy["structure_id"] = res_info[4]
      rmzy["wkds_name"]  = res_info[5]
      rmzy["study_instr"]  = res_info[6]
      rmzy["teacher_name"]  = res_info[7]
      rmzy["play_count"]  = res_info[8]
      rmzy["score_average"]  = res_info[9]
      rmzy["create_time"]  = res_info[10]
      rmzy["download_count"]  = res_info[11]

      rmzy["downloadable"]  = res_info[12]
      rmzy["person_id"]  = res_info[13]
      rmzy["table_pk"]  = res_info[14]
      rmzy["group_id"]  = res_info[15]
      rmzy["content_json"]  = res_info[16]
      rmzy["wk_type"]  = res_info[17]
      rmzy["wk_type_name"]  = res_info[18]
      rmzy["type_id"]  = res_info[19]
      rmzy["uploader_id"]  = res_info[20]
		end
		rmzy["person_name"] = person_name
		rmzy["org_name"] = bureau_name		
		rmzy["id"] = id
		rmzy["stage_subject"] = ssdb_db:hget("subject_"..subject_id,"stage_subject")[1]
		rmzy_tab[i] = rmzy
	end
end

--热门评比排行
local rmpb_tab = {}
local rmpb_res = mysql_db:query("SELECT t1.rating_id,t2.rating_title FROM t_rating_resource t1 INNER JOIN t_rating_info t2 on t1.rating_id = t2.id WHERE RESOURCE_STATUS = 3 AND t2.rating_status = 4 and t2.rating_type="..rating_type..w_type.." GROUP BY RATING_ID ORDER BY COUNT(1) DESC LIMIT "..show_size..";")
if rmpb_res[1] ~= nil then
	for i=1,#rmpb_res do
		local rmpb = {}
		rmpb["rating_id"] = rmpb_res[i]["rating_id"]
		rmpb["rating_title"] = rmpb_res[i]["rating_title"]
		rmpb_tab[i] = rmpb
	end
end

--活跃教师排行
local hyjs_tab = {}
local hyjs_res = mysql_db:query("SELECT person_id,person_name FROM t_rating_resource WHERE rating_id in (select id from t_rating_info where rating_type="..rating_type..w_type..") and resource_status = 3 GROUP BY person_id LIMIT "..show_size..";")

if hyjs_res[1] ~= nil then
	for i=1,#hyjs_res do
		local hyjs = {}
		hyjs["person_id"] = hyjs_res[i]["person_id"]
		hyjs["person_name"] = hyjs_res[i]["person_name"]
		hyjs_tab[i] = hyjs
	end
end

local result = {} 
result["rmzy"] = rmzy_tab
result["rmpb"] = rmpb_tab
result["hyjs"] = hyjs_tab
result["success"] = true

mysql_db:set_keepalive(0,v_pool_size)
redis_db:set_keepalive(0,v_pool_size)
ssdb_db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))