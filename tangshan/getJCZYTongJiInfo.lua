--[[
根据学段、科目获取相关统计信息
@Author  chenxg
@Date    2015-05-12
--]]
local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--地区
if args["stage_id"] == nil or args["stage_id"] == "" 
or args["subject_id"] == nil or args["subject_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"stage_id or subject_id 参数错误！\"}")
    return
end
local area_id = "200004"--args["area_id"]
local stage_id = args["stage_id"]
local subject_id = args["subject_id"]

local cjson = require "cjson"

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
--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local function urlEncode(str)
    if (str) then
        str = string.gsub (str, "\n", "\r\n")
        str = string.gsub (str, "([^%w ])",
        function (c) return string.format ("%%%%%02X", string.byte(c)) end)
    end
    return str
end

local zy_tj_info_tab = {}

--查询资源相关统计信息
local person_count = "SELECT COUNT(1) as tc FROM t_base_person where IDENTITY_ID=5 AND CITY_ID="..area_id .." and stage_id= "..stage_id.." and subject_id="..subject_id..";select count(1) as rc,sum(view_count) as vc,sum(DOWN_COUNT) as dc,case when sum(r.RESOURCE_SIZE_INT) / (1024 * 1024 * 1000) >= 1 then concat(round(sum(r.RESOURCE_SIZE_INT) / (1024 * 1024 * 1000), 2),'G') when sum(r.RESOURCE_SIZE_INT) / (1024 * 1024) >= 1 then  concat(round(sum(r.RESOURCE_SIZE_INT) / (1024 * 1024), 2),'M') when sum(r.RESOURCE_SIZE_INT) / 1024 >= 1 then  concat(round(sum(r.RESOURCE_SIZE_INT) / 1024, 2), 'K') else   concat(sum(r.RESOURCE_SIZE_INT),'B') end as rs from t_resource_info r where r.stage_id= "..stage_id.." and r.subject_id="..subject_id.." and (r.GROUP_ID = "..area_id.." or GROUP_ID=1);"
--ngx.log(ngx.ERR, "===sql===> " .. person_count .. " <===sql===");
local results, err, errno, sqlstate = db:query(person_count);
if not results then
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}");
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    return;
end

local res1 = db:read_result()		
zy_tj_info_tab["teacher_count"] = results[1]["tc"]
zy_tj_info_tab["res_count"] = res1[1]["rc"]
zy_tj_info_tab["res_size"] = res1[1]["rs"]
zy_tj_info_tab["view_count"] = res1[1]["vc"]
zy_tj_info_tab["down_count"] = res1[1]["dc"]

--查询最新资源和热门下载资源
local res_list = "SELECT id as resource_id_int from t_resource_info r where RES_TYPE=1 and r.stage_id= "..stage_id.." and r.subject_id="..subject_id.." and (r.GROUP_ID = "..area_id.." or GROUP_ID=1) order by ts desc limit 5;SELECT id as resource_id_int from t_resource_info r where RES_TYPE=1 and r.stage_id= "..stage_id.." and r.subject_id="..subject_id.." and (r.GROUP_ID = "..area_id.." or GROUP_ID=1) order by down_count desc limit 5;"
local ress, err, errno, sqlstate = db:query(res_list);
if not ress then
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}");
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    return;
end
local ress1 = db:read_result()
local new_res_tab = {}
local hot_res_tab = {}
local resss = {}
resss[1] = "1058891"
resss[2] = "1058892"
resss[3] = "1058893"
resss[4] = "1058894"
resss[5] = "1058895"
resss[6] = "1058896"
resss[7] = "1058897"
resss[8] = "1058898"
resss[9] = "1058899"
resss[10] = "1058900"
for i=1,#ress do
	--ngx.print(ress[1]["resource_id_int"])

	local res_info_id = ress[i]["resource_id_int"]
	--local res_info_id = resss[i]
	
	--local  res_info = cache:hmget("resource_"..res_info_id,"resource_title","resource_type_name","resource_size","create_time","down_count","file_id","width","height","resource_format","resource_page","thumb_id","preview_status","for_urlencoder_url","for_iso_url","resource_size_int","beike_type","scheme_id_int","resource_id_int","person_id","app_type_id","resource_type","person_name","structure_id","resource_id_char")
	local  res_info = ssdb:multi_hget("resource_"..res_info_id,"resource_title","resource_type_name","resource_size","create_time","down_count","file_id","width","height","resource_format","resource_page","thumb_id","preview_status","for_urlencoder_url","for_iso_url","resource_size_int","beike_type","scheme_id_int","resource_id_int","person_id","app_type_id","resource_type","person_name","structure_id","resource_id_char")
				
	--根据版本ID获取该版本属于哪个学科    
	--local subject_name = ssdb:hget("t_resource_scheme_"..res_info[17],"subject_name")[1]
	--local subject_id = ssdb:hget("t_resource_scheme_"..res_info[17],"subject_id")[1]

	local res_tab = {}  
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
	res_tab["resource_size_int"] = res_info[30]
	res_tab["beike_type"] = res_info[32]
	res_tab["url_code"] = urlEncode(res_info[2])
	--res_tab["subject_name"] = subject_name
	--res_tab["subject_id"] = subject_id
	res_tab["obj_type"] = obj_type
	res_tab["resource_id_int"] = res_info[36]
	res_tab["person_id"] = res_info[38]
	res_tab["app_type_id"] = res_info[40]
	res_tab["resource_type"] = res_info[42]
	res_tab["person_name"] = res_info[44]
	res_tab["structure_id"] = res_info[46]
	res_tab["obj_id_char"] = res_info[48]
	res_tab["scheme_id"] =res_info[34]

	new_res_tab[i] = res_tab
--*****
end

for i=1,#ress1 do
	--ngx.print(ress[1]["resource_id_int"])

	local res_info_id = ress1[i]["resource_id_int"]
	--local res_info_id = resss[i]
	
	--local  res_info = cache:hmget("resource_"..res_info_id,"resource_title","resource_type_name","resource_size","create_time","down_count","file_id","width","height","resource_format","resource_page","thumb_id","preview_status","for_urlencoder_url","for_iso_url","resource_size_int","beike_type","scheme_id_int","resource_id_int","person_id","app_type_id","resource_type","person_name","structure_id","resource_id_char")
	local  res_info = ssdb:multi_hget("resource_"..res_info_id,"resource_title","resource_type_name","resource_size","create_time","down_count","file_id","width","height","resource_format","resource_page","thumb_id","preview_status","for_urlencoder_url","for_iso_url","resource_size_int","beike_type","scheme_id_int","resource_id_int","person_id","app_type_id","resource_type","person_name","structure_id","resource_id_char")
				
	--根据版本ID获取该版本属于哪个学科    
	--local subject_name = ssdb:hget("t_resource_scheme_"..res_info[17],"subject_name")[1]
	--local subject_id = ssdb:hget("t_resource_scheme_"..res_info[17],"subject_id")[1]

	local res_tab = {}  
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
	res_tab["resource_size_int"] = res_info[30]
	res_tab["beike_type"] = res_info[32]
	res_tab["url_code"] = urlEncode(res_info[2])
	--res_tab["subject_name"] = subject_name
	--res_tab["subject_id"] = subject_id
	res_tab["obj_type"] = obj_type
	res_tab["resource_id_int"] = res_info[36]
	res_tab["person_id"] = res_info[38]
	res_tab["app_type_id"] = res_info[40]
	res_tab["resource_type"] = res_info[42]
	res_tab["person_name"] = res_info[44]
	res_tab["structure_id"] = res_info[46]
	res_tab["obj_id_char"] = res_info[48]
	res_tab["scheme_id"] =res_info[34]

	hot_res_tab[i] = res_tab
--*****
end


zy_tj_info_tab["new_res_tab"] = new_res_tab
zy_tj_info_tab["hot_res_tab"] = hot_res_tab
zy_tj_info_tab["success"] = true

ngx.print(cjson.encode(zy_tj_info_tab))

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0,v_pool_size)