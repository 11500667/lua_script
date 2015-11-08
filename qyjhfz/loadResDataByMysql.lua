--[[
根据资源类型[资源、试卷、备课、微课]获取发布到区域均衡栏目下的资源[mysql版]
@Author  chenxg
@Date    2015-06-05
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"
cjson.encode_empty_table_as_object(false);
--判断request类型, 获得请求参数
local request_method = ngx.var.request_method
local args,err
if request_method == "GET" then
    args,err = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args,err = ngx.req.get_post_args() 
end
if not args then 
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local returnjson = {}
--参数
--传入的当前用户
local person_id = args["person_id"] 
--传入的资源类型ID 1：资源 3：试卷 4：备课 5：微课
local obj_type = args["obj_type"]
--传入的大学区Id或者协作体ID
local path_id = args["path_id"]
--控制显示的数量
local limit = args["limit"]

--判断参数是否为空
if not path_id or string.len(path_id) == 0 
	or not limit or string.len(limit) == 0 
	or not obj_type or string.len(obj_type) == 0 
   then
    --say("{\"success\":false,\"info\":\"参数错误！\"}")
	returnjson["info"] = "参数错误！"
	returnjson["zy_hot"] = {}
	returnjson["sj_hot"] = {}
	returnjson["wk_hot"] = {}
	returnjson["bk_hot"] = {}
	returnjson.success = "false"
	say(cjson.encode(returnjson))
    return
end
limit = tonumber(limit)

--从cookie获取当前用户的省市区ID
local qyjh_id = tostring(ngx.var.cookie_qyjh_id)

--创建ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
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

--加码
function encodeURI(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end

local perfilter = ""
if person_id  then
	perfilter = "filter=person_id,"..person_id..";"
end

local resource_hot_tab= {}
if obj_type == "1" then
	--获取资源数据 --!range=hd_id,0,999999;
	res = mysql_db:query("SELECT SQL_NO_CACHE id FROM t_base_publish_sphinxse WHERE query='"..perfilter.."filter=b_delete,0;filter=obj_type,1;filter=pub_type,3;filter=xzt_id,"..path_id..";filter=qyjh_id,"..qyjh_id..";groupby=attr:obj_info_id;groupsort=ts desc;limit="..limit.."'")
	for i=1,#res do
		local iid = cache:hget("publish_"..res[i]["id"],"obj_info_id")
		--local zy_tj_new = cache:hmget("resource_"..iid,"resource_title","resource_format","resource_page","file_id","thumb_id","preview_status","width","height","for_urlencoder_url","for_iso_url","down_count","scheme_id_int","resource_id_int","create_time")
		local zy_tj_new = ssdb:multi_hget("resource_"..iid,"resource_title","resource_format","resource_page","file_id","thumb_id","preview_status","width","height","for_urlencoder_url","for_iso_url","down_count","scheme_id_int","resource_id_int","create_time")
		--根据版本ID获取该版本属于哪个学科    
		local subject_name = ssdb:hget("t_resource_scheme_"..zy_tj_new[24],"subject_name")[1]
		local subject_id = ssdb:hget("t_resource_scheme_"..zy_tj_new[24],"subject_id")[1]		
		local zy_tj_new_tab = {}
		zy_tj_new_tab["iid"] = iid
		zy_tj_new_tab["resource_title"] = zy_tj_new[2]
		zy_tj_new_tab["resource_format"] = zy_tj_new[4]
		zy_tj_new_tab["resource_page"] = zy_tj_new[6]
		zy_tj_new_tab["file_id"] = zy_tj_new[8]
		zy_tj_new_tab["thumb_id"] = zy_tj_new[10]
		zy_tj_new_tab["preview_status"] = zy_tj_new[12]
		zy_tj_new_tab["width"] = zy_tj_new[14]
		zy_tj_new_tab["height"] = zy_tj_new[16]
		zy_tj_new_tab["for_urlencoder_url"] = zy_tj_new[18]
		zy_tj_new_tab["for_iso_url"] = zy_tj_new[20]
		zy_tj_new_tab["browse_count"] = zy_tj_new[22]
		zy_tj_new_tab["resource_id_int"] = zy_tj_new[26]
		zy_tj_new_tab["subject"] = subject_name
		zy_tj_new_tab["subject_id"] = subject_id
		zy_tj_new_tab["create_time"] = zy_tj_new[28]
		zy_tj_new_tab["url_code"] = encodeURI(zy_tj_new[2])
		resource_hot_tab[i] = zy_tj_new_tab    
	end
	returnjson["zy_hot"] = resource_hot_tab
elseif obj_type == "3" then
	--获取试卷数据  !range=hd_id,0,999999;
	res = mysql_db:query("SELECT SQL_NO_CACHE id FROM t_base_publish_paper_sphinxse WHERE query='"..perfilter.."filter=b_delete,0;filter=obj_type,3;filter=pub_type,3;filter=xzt_id,"..path_id..";filter=qyjh_id,"..qyjh_id..";groupby=attr:obj_info_id;groupsort=ts desc;limit="..limit.."'")
	
	for i=1,#res do
		local iid = cache:hget("publish_"..res[i]["id"],"obj_info_id")	
		ngx.log(ngx.ERR,"@@@@@@@@@"..iid.."@@@@@@@@@")
		local paper_value = cache:hmget("paper_"..iid,"paper_id_char","paper_name","question_count","create_time","paper_type","extension","parent_structure_name","paper_id_int","person_id","resource_info_id")
		local sj_tj_new_tab = {}
		sj_tj_new_tab["iid"] = iid
		sj_tj_new_tab["paper_id"] = paper_value[1]
		sj_tj_new_tab["paper_name"] = paper_value[2]
		sj_tj_new_tab["ti_num"] = paper_value[3]
		sj_tj_new_tab["create_time"] = paper_value[4]
		sj_tj_new_tab["paper_source"] = paper_value[5]
		sj_tj_new_tab["extenstion"] = paper_value[6]
		sj_tj_new_tab["parent_structure_name"] = paper_value[7]
		sj_tj_new_tab["paper_id_int"] = paper_value[8]
		sj_tj_new_tab["person_id"] =paper_value[9]
		sj_tj_new_tab["paper_id_char"] =paper_value[1]
		ngx.log(ngx.ERR,"@@@@@@@@@"..paper_value[9].."@@@@@@@@@")
		--local resource_value = cache:hmget("resource_"..paper_value[10],"preview_status","for_iso_url","for_urlencoder_url","file_id","resource_page","structure_id","scheme_id_int","create_time")
		local resource_value = ssdb:multi_hget("resource_"..paper_value[10],"preview_status","for_iso_url","for_urlencoder_url","file_id","resource_page","structure_id","scheme_id_int","create_time")
		sj_tj_new_tab["preview_status"] =resource_value[2]
		sj_tj_new_tab["for_iso_url"] =resource_value[4]
		sj_tj_new_tab["for_urlencoder_url"] =resource_value[6]
		sj_tj_new_tab["file_id"] =resource_value[8]
		sj_tj_new_tab["page"] =resource_value[10]
		sj_tj_new_tab["structure_id_int"] =resource_value[12]
		sj_tj_new_tab["structure_id"] =resource_value[12]
		sj_tj_new_tab["scheme_id_int"] =resource_value[14]
		sj_tj_new_tab["scheme_id"] =resource_value[14]
		sj_tj_new_tab["create_time"] =resource_value[16]
		local subject_name = ssdb:hget("t_resource_scheme_"..resource_value[14],"subject_name")[1] 
		local subject_id = ssdb:hget("t_resource_scheme_"..resource_value[14],"subject_id")[1]
		sj_tj_new_tab["subject"] = subject_name	
		sj_tj_new_tab["subject_id"] = subject_id	
		sj_tj_new_tab["url_code"] = encodeURI(paper_value[2])		
		resource_hot_tab[i] = sj_tj_new_tab    
	end
returnjson["sj_hot"] = resource_hot_tab
	
elseif obj_type == "4" then
	--获取备课数据  !range=hd_id,0,999999;
	res = mysql_db:query("SELECT SQL_NO_CACHE id FROM t_base_publish_sphinxse WHERE query='"..perfilter.."filter=b_delete,0;filter=obj_type,4;filter=pub_type,3;filter=xzt_id,"..path_id..";filter=qyjh_id,"..qyjh_id..";groupby=attr:obj_info_id;groupsort=ts desc;limit="..limit.."'")
	
	for i=1,#res do
		local iid = cache:hget("publish_"..res[i]["id"],"obj_info_id")
		--local bk_tj_hot = cache:hmget("resource_"..iid,"resource_title","resource_format","resource_page","file_id","thumb_id","preview_status","width","height","for_urlencoder_url","for_iso_url","down_count","scheme_id_int","resource_id_int","create_time","resource_size_int","beike_type","structure_id","resource_id_char")
		local bk_tj_hot = ssdb:multi_hget("resource_"..iid,"resource_title","resource_format","resource_page","file_id","thumb_id","preview_status","width","height","for_urlencoder_url","for_iso_url","down_count","scheme_id_int","resource_id_int","create_time","resource_size_int","beike_type","structure_id","resource_id_char")
		--ngx.log(ngx.ERR, "cxg_log aaaaownxzts====>"..iid.."<====");
		--根据版本ID获取该版本属于哪个学科    
		local subject_name = ssdb:hget("t_resource_scheme_"..bk_tj_hot[24],"subject_name")[1] 
		local subject_id = ssdb:hget("t_resource_scheme_"..bk_tj_hot[24],"subject_id")[1]		
		local bk_tj_hot_tab = {}
		bk_tj_hot_tab["iid"] = iid
		bk_tj_hot_tab["resource_title"] = bk_tj_hot[2]
		bk_tj_hot_tab["resource_format"] = bk_tj_hot[4]
		bk_tj_hot_tab["resource_page"] = bk_tj_hot[6]
		bk_tj_hot_tab["file_id"] = bk_tj_hot[8]
		bk_tj_hot_tab["thumb_id"] = bk_tj_hot[10]
		bk_tj_hot_tab["preview_status"] = bk_tj_hot[12]
		bk_tj_hot_tab["width"] = bk_tj_hot[14]
		bk_tj_hot_tab["height"] = bk_tj_hot[16]
		bk_tj_hot_tab["for_urlencoder_url"] = bk_tj_hot[18]
		bk_tj_hot_tab["for_iso_url"] = bk_tj_hot[20]
		bk_tj_hot_tab["browse_count"] = bk_tj_hot[22]
		bk_tj_hot_tab["resource_id_int"] = bk_tj_hot[26]    
		bk_tj_hot_tab["subject"] = subject_name
		bk_tj_hot_tab["subject_id"] = subject_id
		bk_tj_hot_tab["create_time"] = bk_tj_hot[28]
		bk_tj_hot_tab["resource_size_int"] = bk_tj_hot[30]
		bk_tj_hot_tab["beike_type"] = bk_tj_hot[32]
		bk_tj_hot_tab["structure_id"] = bk_tj_hot[34]
		bk_tj_hot_tab["resource_id_char"] = bk_tj_hot[36]
		bk_tj_hot_tab["url_code"] = encodeURI(bk_tj_hot[2])
		bk_tj_hot_tab["scheme_id"] =bk_tj_hot[24]
		resource_hot_tab[i] = bk_tj_hot_tab    
	end
returnjson["bk_hot"] = resource_hot_tab	
elseif obj_type == "5" then
	--获取微课数据  !range=hd_id,0,999999;
	res = mysql_db:query("SELECT SQL_NO_CACHE id FROM t_base_publish_wk_sphinxse WHERE query='"..perfilter.."filter=b_delete,0;filter=obj_type,5;filter=pub_type,3;filter=xzt_id,"..path_id..";filter=qyjh_id,"..qyjh_id..";groupby=attr:obj_info_id;groupsort=ts desc;limit="..limit.."'")
	
	for i=1,#res do
		local iid = cache:hget("publish_"..res[i]["id"],"obj_info_id")
		if tostring(res_info_id) ~= "userdata: NULL" then
			local thumb_id = "";
			  local wkds_value_null = cache:hmget("wkds_"..iid,"wkds_id_int");
			  if wkds_value_null[1] ~= ngx.null then
				  local wkds_value = cache:hmget("wkds_"..iid,"wkds_id_int","wkds_id_char","scheme_id","structure_id","wkds_name",
				  "study_instr","teacher_name","play_count","score_average","create_time",
				  "download_count","downloadable","person_id","table_pk","group_id","content_json");
				  --获得缩略图id
				   local content_json = wkds_value[16]
				   local aa = ngx.decode_base64(content_json)
				   local data = cjson.decode(aa)
				   if #data.sp_list~=0 then

					  local resource_info_id = data.sp_list[1].id
					  if resource_info_id ~= ngx.null then
					   local thumbid = ssdb:multi_hget("resource_"..resource_info_id,"thumb_id")
					   thumb_id = thumbid[2]
					  end                              
				   else
					   thumb_id = "E6648460-4FFD-E626-1C14-6FBF9F94A23C"
				   end
					
			   --获得微课位置				
				local structure_id = wkds_value[4]
				local curr_path = ""
				local structures = cache:zrange("structure_code_"..structure_id,0,-1)
				for i=1,#structures do
					local structure_info = cache:hmget("t_resource_structure_"..structures[i],"structure_name")
				 curr_path = curr_path..structure_info[1].."->"
				end
				curr_path = string.sub(curr_path,0,#curr_path-2)
				local subject_name = ssdb:hget("t_resource_scheme_"..wkds_value[3],"subject_name")[1]  
				local subject_id = ssdb:hget("t_resource_scheme_"..wkds_value[3],"subject_id")[1]
				local wk_tj_hot_tab = {}
				wk_tj_hot_tab["iid"]=iid;
				wk_tj_hot_tab["wkds_id_int"]=wkds_value[1];
				wk_tj_hot_tab["wkds_id_char"]=wkds_value[2];
				wk_tj_hot_tab["scheme_id_int"]=wkds_value[3];
				wk_tj_hot_tab["structure_id"]=wkds_value[4];
				wk_tj_hot_tab["wkds_name"]=wkds_value[5];
				wk_tj_hot_tab["study_instr"]=wkds_value[6];
				wk_tj_hot_tab["teacher_name"]=wkds_value[7];
				wk_tj_hot_tab["play_count"]=wkds_value[8];
				wk_tj_hot_tab["score_average"]=wkds_value[9];
				wk_tj_hot_tab["create_time"]=wkds_value[10];
				wk_tj_hot_tab["download_count"]=wkds_value[11];
				wk_tj_hot_tab["thumb_id"]=thumb_id;
				wk_tj_hot_tab["downloadable"]=wkds_value[12];
				wk_tj_hot_tab["person_id"]=wkds_value[13];
				wk_tj_hot_tab["table_pk"]=wkds_value[14];
				wk_tj_hot_tab["group_id"]=wkds_value[15];
				wk_tj_hot_tab["content_json"]=wkds_value[16];
				wk_tj_hot_tab["parent_structure_name"]=curr_path;
				wk_tj_hot_tab["subject_name"]=subject_name;
				wk_tj_hot_tab["subject_id"]=subject_id;
				resource_hot_tab[i] = wk_tj_hot_tab
			  end
		
		end
	end
returnjson["wk_hot"] = resource_hot_tab	
	
end

returnjson.success = "true"

say(cjson.encode(returnjson))

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
mysql_db:set_keepalive(0,v_pool_size)