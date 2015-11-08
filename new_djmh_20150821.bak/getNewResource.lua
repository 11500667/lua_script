local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

--bureau_id参数 单位ID
if args["bureau_id"] == nil or args["bureau_id"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"bureau_id参数错误！\"}")
	return
end
local bureau_id = args["bureau_id"]

--show_size参数 显示多少条
if args["show_size"] == nil or args["show_size"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"show_size参数错误！\"}")
	return
end
local show_size = args["show_size"]

--stage_id学段ID
if args["stage_id"] == nil or args["stage_id"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"stage_id参数错误！\"}")
	return
end
local stage_id = args["stage_id"]

--res_type类型 1：资源  2：备课  4：试卷  5：微课
if args["res_type"] == nil or args["res_type"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"res_type参数错误！\"}")
	return
end
local res_type = args["res_type"]

local cjson = require "cjson"

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

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--url加码
function encodeURI(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end

--拼group_id条件
local group_str = "filter=group_id,1,"..bureau_id..";"
--拼stage_id条件
local stage_str = ""
if stage_id ~= "-1" then
	stage_str = "filter=stage_id,"..stage_id..";"
else
	stage_str = "filter=stage_id,4,5,6;"
end

local i_count = 1
--获取资源的最新资源
local res_new_tab = {}
if res_type == "1" then
	local res_sql = mysql_db:query("SELECT SQL_NO_CACHE id FROM t_resource_info_sphinxse WHERE query='"..group_str..stage_str.."filter=res_type,1;filter=release_status,1,3;groupby=attr:resource_id_int;groupsort=ts desc;limit="..show_size.."';")

	for i=1,#res_sql do
		--local res_info = cache:hmget("resource_"..res_sql[i]["id"],"resource_title","resource_format","resource_page","file_id","thumb_id","preview_status","width","height","for_urlencoder_url","for_iso_url","down_count","scheme_id_int","resource_id_int")
		local res_info = ssdb_db:multi_hget("resource_"..res_sql[i]["id"],"resource_title","resource_format","resource_page","file_id","thumb_id","preview_status","width","height","for_urlencoder_url","for_iso_url","down_count","scheme_id_int","resource_id_int")
		--根据版本ID获取该版本属于哪个学科   
		
		local subject_name = ssdb_db:hget("t_resource_scheme_"..res_info[24],"subject_name")[1]    
		local res_info_tab = {}
		res_info_tab["iid"] = res_sql[i]["id"]
		res_info_tab["resource_title"] = res_info[2]	
		res_info_tab["resource_format"] = res_info[4]
		res_info_tab["resource_page"] = res_info[6]
		res_info_tab["file_id"] = res_info[8]
		res_info_tab["thumb_id"] = res_info[10]
		res_info_tab["preview_status"] = res_info[12]
		res_info_tab["width"] = res_info[14]
		res_info_tab["height"] = res_info[16]
		res_info_tab["for_urlencoder_url"] = res_info[18]
		res_info_tab["for_iso_url"] = res_info[20]
		res_info_tab["browse_count"] = res_info[22]
		res_info_tab["resource_id_int"] = res_info[26]
		res_info_tab["subject"] = subject_name
		res_info_tab["url_code"] = encodeURI(res_info[2])
		res_new_tab[i] = res_info_tab    
	end
elseif res_type == "2" then
	local res_sql = mysql_db:query("SELECT SQL_NO_CACHE id FROM t_resource_info_sphinxse WHERE query='"..group_str..stage_str.."filter=res_type,2;filter=release_status,1,3;!filter=bk_type,1;groupby=attr:resource_id_int;groupsort=ts desc;limit="..show_size.."';")

	for i=1,#res_sql do
		--local res_info = cache:hmget("resource_"..res_sql[i]["id"],"resource_title","resource_format","resource_page","file_id","thumb_id","preview_status","width","height","for_urlencoder_url","for_iso_url","down_count","scheme_id_int","resource_id_int")	
		local res_info = ssdb_db:multi_hget("resource_"..res_sql[i]["id"],"resource_title","resource_format","resource_page","file_id","thumb_id","preview_status","width","height","for_urlencoder_url","for_iso_url","down_count","scheme_id_int","resource_id_int")	
		--根据版本ID获取该版本属于哪个学科   
		
		local subject_name = ssdb_db:hget("t_resource_scheme_"..res_info[24],"subject_name")[1]    
		local res_info_tab = {}
		res_info_tab["iid"] = res_sql[i]["id"]
		res_info_tab["resource_title"] = res_info[2]	
		res_info_tab["resource_format"] = res_info[4]
		res_info_tab["resource_page"] = res_info[6]
		res_info_tab["file_id"] = res_info[8]
		res_info_tab["thumb_id"] = res_info[10]
		res_info_tab["preview_status"] = res_info[12]
		res_info_tab["width"] = res_info[14]
		res_info_tab["height"] = res_info[16]
		res_info_tab["for_urlencoder_url"] = res_info[18]
		res_info_tab["for_iso_url"] = res_info[20]
		res_info_tab["browse_count"] = res_info[22]
		res_info_tab["resource_id_int"] = res_info[26]
		res_info_tab["subject"] = subject_name
		res_info_tab["url_code"] = encodeURI(res_info[2])
		res_new_tab[i] = res_info_tab    
	end
elseif res_type == "4" then
	local res_sql = mysql_db:query("SELECT SQL_NO_CACHE id FROM t_sjk_paper_info_sphinxse WHERE query='"..group_str..stage_str.."filter=b_delete,0;sort=attr_desc:ts;limit="..show_size.."';")
	
	for i=1,#res_sql do
		local resource_info_id = res_sql[i]["id"]
		local iSexists = tostring(cache:exists("paper_"..resource_info_id))
		if iSexists ~= "0" then
		local resource_info_res = {}
		local paper_info = cache:hmget("paper_"..resource_info_id,"paper_name","paper_type","extension","paper_id_char","paper_id_int","person_id","subject_id","stage_id","scheme_id")
				
		local subject_name = ssdb_db:hget("t_resource_scheme_"..paper_info[9],"subject_name")[1] 
		resource_info_res["iid"] = resource_info_id
		resource_info_res["paper_name"] = paper_info[1]
		resource_info_res["paper_source"] = paper_info[2]				
		resource_info_res["extenstion"] = paper_info[3]				
		resource_info_res["paper_id_char"] = paper_info[4]
		resource_info_res["paper_id_int"] = paper_info[5]
		resource_info_res["person_id"] = paper_info[6]
		resource_info_res["subject"] = subject_name
		
		local preview_status = ""
		local for_iso_url = ""
		local for_urlencoder_url = ""
		local file_id = ""
		local page = ""
		
		if paper_info[2]=="2" then
			local resource_info_id = cache:hmget("paper_"..resource_info_id,"resource_info_id")[1]
			--local resource_info = cache:hmget("resource_"..resource_info_id,"preview_status","for_iso_url","for_urlencoder_url","file_id","resource_page","structure_id","scheme_id_int")
			local resource_info = ssdb_db:multi_hget("resource_"..resource_info_id,"preview_status","for_iso_url","for_urlencoder_url","file_id","resource_page","structure_id","scheme_id_int")
			preview_status = resource_info[2]
			for_iso_url = resource_info[4]
			for_urlencoder_url= resource_info[6]
			file_id = resource_info[8]
			page = resource_info[10]
		end
		
		
		resource_info_res["preview_status"] = preview_status
		resource_info_res["for_urlencoder_url"] = for_urlencoder_url
		resource_info_res["for_iso_url"] = for_iso_url
		resource_info_res["url_code"] = encodeURI(paper_info[1])				
		resource_info_res["file_id"] = file_id
		resource_info_res["page"] = page

		
		res_new_tab[i_count] = resource_info_res
		i_count = i_count+1
		end
	end
else
	local res_sql = mysql_db:query("SELECT SQL_NO_CACHE id FROM t_wkds_info_sphinxse WHERE query='"..group_str..stage_str.."filter=b_delete,0;sort=attr_desc:ts;limit="..show_size.."';")

	for i=1,#res_sql do
		local resource_info_id = res_sql[i]["id"]
		local resource_info_res = {}
		local resource_info = cache:hmget("wkds_"..resource_info_id,"wkds_name","thumb_id","content_json","play_count","wkds_id_int","download_count","scheme_id","teacher_name")
		
		resource_info_res["iid"] = resource_info_id
		resource_info_res["wkds_name"] = resource_info[1]
		resource_info_res["play_count"] = resource_info[4]
		resource_info_res["wkds_id_int"] = resource_info[5]
		resource_info_res["down_count"] = resource_info[6]
		local subject_name = ssdb_db:hget("t_resource_scheme_"..resource_info[7],"subject_name")[1]
		resource_info_res["subject"] = subject_name
		resource_info_res["upload_person"] = resource_info[8]
		
			
		local  thumb_id = ""
		 local content_json = resource_info[3]		 
		 local aa = ngx.decode_base64(content_json)
		 local data = cjson.decode(aa)
		 if #data.sp_list~=0 then
			local resource_info_id = data.sp_list[1].id
			if resource_info_id ~= ngx.null then
				local thumbid = ssdb_db:hget("resource_"..resource_info_id,"thumb_id")
				if tostring(thumbid[1]) ~= "userdata: NULL" then
					thumb_id = thumbid[1]
				end
			end
		 else
			 thumb_id = "E6648460-4FFD-E626-1C14-6FBF9F94A23C"
		 end

		if not thumb_id or string.len(thumb_id) == 0 then
		  thumb_id = "E6648460-4FFD-E626-1C14-6FBF9F94A23C"
		end
		resource_info_res["thumb_id"] = thumb_id
		
		res_new_tab[i] = resource_info_res
	end
end

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
mysql_db:set_keepalive(0,v_pool_size)

local result = {}
result["success"] = true
result["list"] = res_new_tab

cjson.encode_empty_table_as_object(false)
ngx.print(tostring(cjson.encode(result)))
