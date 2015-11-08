local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

local cjson = require "cjson"

--系统类型  1:zy  2:wk
if args["sys_type"] == nil or args["sys_type"] == "" then
    ngx.say("{\"success\":false,\"info\":\"sys_type参数错误！\"}")
    return
end

local sys_type = ""
if tostring(args["sys_type"]) == "1" then
	sys_type = "zy"
elseif tostring(args["sys_type"]) == "2" then
	sys_type = "wk"
elseif tostring(args["sys_type"]) == "3" then
	sys_type = "bk"
else
	sys_type = "sj"
end

--学段ID
if args["stage_id"] == nil or args["stage_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"stage_id参数错误！\"}")
    return
end
local stage_id = args["stage_id"]

--科目ID
if args["subject_id"] == nil or args["subject_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"subject_id参数错误！\"}")
    return
end
local subject_id = args["subject_id"]

--资源上传人
if args["person_id"] == nil or args["person_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
    return
end
local person_id = args["person_id"]

local bureau_id = ngx.var.cookie_background_bureau_id

--url加码
function encodeURI(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end

--一页显示多少
if args["pageSize"] == nil or args["pageSize"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"pageSize参数错误！\"}")
    return
end
local pageSize = args["pageSize"]

--第几页
if args["pageNumber"] == nil or args["pageNumber"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"pageNumber参数错误！\"}")
    return
end
local pageNumber = args["pageNumber"]

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
local redis_db = redis:new()
local ok,err = redis_db:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local ssdb_key = ""

if subject_id == "-1" then
	if stage_id == "-1" then
		if person_id == "-1" then
			ssdb_key = "tuijian_"..sys_type.."_"..bureau_id
		else
			ssdb_key = "tuijian_"..sys_type.."_"..bureau_id.."_"..person_id
		end
	else
		if person_id == "-1" then
			ssdb_key = "tuijian_"..sys_type.."_"..bureau_id.."_"..stage_id
		else
			ssdb_key = "tuijian_"..sys_type.."_"..bureau_id.."_"..stage_id.."_"..person_id
		end
	end
else
	if person_id == "-1" then	
		ssdb_key = "tuijian_"..sys_type.."_"..bureau_id.."_"..stage_id.."_"..subject_id
	else
		ssdb_key = "tuijian_"..sys_type.."_"..bureau_id.."_"..stage_id.."_"..subject_id.."_"..person_id
	end
end

ngx.log(ngx.ERR,"@@@"..ssdb_key.."@@@")

local offset = math.floor((pageNumber-1)*pageSize)
local totalRow = ssdb_db:zsize(ssdb_key)[1]
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

local i_count = 1
local resource_info_tab = {}

local tuijian_info = ssdb_db:zrrange(ssdb_key,offset,pageSize)
if #tuijian_info>1 then	
	for i=1,#tuijian_info,2 do
			local resource_info_id = tuijian_info[i]
			local is_zd = "0"			
			if string.sub(tuijian_info[i+1],1,1) == "9" then
				is_zd = "1"
			end
			local resource_info_res = {}
			if sys_type == "zy" then
				--local resource_info = redis_db:hmget("resource_"..resource_info_id,"resource_id_int","resource_title","create_time","person_id","file_id","thumb_id","preview_status","resource_id_char","for_urlencoder_url","for_iso_url","person_name","resource_format","width","height","resource_page","subject_id","stage_id")
				local resource_info = ssdb_db:multi_hget("resource_"..resource_info_id,"resource_id_int","resource_title","create_time","person_id","file_id","thumb_id","preview_status","resource_id_char","for_urlencoder_url","for_iso_url","person_name","resource_format","width","height","resource_page","subject_id","stage_id")
				resource_info_res["iid"] = resource_info_id
				resource_info_res["resource_id_int"] = resource_info[2]
				resource_info_res["resource_title"] = resource_info[4]
				resource_info_res["create_time"] = resource_info[6]
				resource_info_res["person_id"] = resource_info[8]
				resource_info_res["file_id"] = resource_info[10]
				--resource_info_res["thumb_id"] = resource_info[6]
				resource_info_res["preview_status"] = resource_info[14]
				resource_info_res["resource_id_char"] = resource_info[16]				
				resource_info_res["is_zd"] = is_zd				
				local org_name = ""
				local person_name = ""
				if resource_info[8]=="32" or resource_info[8]=="34" then
					org_name = "未知"
					person_name = "未知"
				elseif resource_info[8] =="1" then
					org_name = "东师理想";
					person_name = "东师理想";
				else
					local xiao = redis_db:hget("person_"..resource_info[8].."_5","xiao");
					org_name = redis_db:hget("t_base_organization_"..xiao,"org_name")
					person_name = resource_info[22]
				end
				resource_info_res["person_name"] = person_name
				resource_info_res["org_name"] = org_name
				resource_info_res["resource_format"] = resource_info[24]
				resource_info_res["width"] = resource_info[26]
				resource_info_res["height"] = resource_info[28]
				resource_info_res["resource_page"] = resource_info[30]								
				resource_info_res["stage_subject"] = ssdb_db:hget("subject_"..resource_info[32],"stage_subject")[1]
				
				resource_info_res["subject_id"] = resource_info[32]
				resource_info_res["stage_id"] = resource_info[34]
				
				
				resource_info_tab[i_count] = resource_info_res
			elseif sys_type == "wk" then
				 local wkds_info = redis_db:hmget("wkds_"..resource_info_id,"wkds_id_int","wkds_id_char","scheme_id","structure_id","wkds_name","study_instr","teacher_name","play_count","score_average","create_time","download_count","thumb_id","downloadable","person_id","table_pk","group_id","content_json","wk_type","wk_type_name","type_id","subject_id")	
				 
				 resource_info_res["iid"] = resource_info_id
				 resource_info_res["wkds_id_int"] = wkds_info[1]
				 resource_info_res["wkds_id_char"] = wkds_info[2]
				 resource_info_res["scheme_id_int"] = wkds_info[3]
				 resource_info_res["structure_id"] = wkds_info[4]
				 resource_info_res["resource_title"] = wkds_info[5]
				 resource_info_res["study_instr"] = wkds_info[6]				 
				 resource_info_res["play_count"] = wkds_info[8]
				 resource_info_res["score_average"] = wkds_info[9]
				 resource_info_res["create_time"] = wkds_info[10]
				 resource_info_res["download_count"] = wkds_info[11]
				 local  thumb_id = ""
				 local content_json = wkds_info[17]
				 ngx.log(ngx.ERR,"@@@"..resource_info_id.."@@@")
                 local aa = ngx.decode_base64(content_json)
                 local data = cjson.decode(aa)
                 if #data.sp_list~=0 then
                    local resource_info_id = data.sp_list[1].id
                    if resource_info_id ~= ngx.null then
                        --local thumbid = redis_db:hmget("resource_"..resource_info_id,"thumb_id")
						local thumbid = ssdb_db:hget("resource_"..resource_info_id,"thumb_id")[1]
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
				 resource_info_res["downloadable"] = wkds_info[13]
				 resource_info_res["person_id"] = wkds_info[14]				 
				 resource_info_res["table_pk"] = wkds_info[15]
				 resource_info_res["group_id"] = wkds_info[16]				 
				 resource_info_res["wk_type"] = wkds_info[18]
				 resource_info_res["wk_type_name"] = wkds_info[19]
				 resource_info_res["type_id"] = wkds_info[20]
				 
				 local org_name = ""
				 local person_name = ""
				 if wkds_info[14]	=="32" or wkds_info[14]	=="34" then
					org_name = "--"
					person_name = "--"
				 elseif wkds_info[14] =="1" then
					org_name = "东师理想";
					person_name = "东师理想";
				 else
					local xiao = redis_db:hget("person_"..wkds_info[14].."_5","xiao");
					org_name = redis_db:hget("t_base_organization_"..xiao,"org_name")
					person_name = wkds_info[7]
				 end
				 resource_info_res["person_name"] = person_name
				 resource_info_res["org_name"] = org_name
				 resource_info_res["is_zd"] = is_zd
				 resource_info_res["stage_subject"] = ssdb_db:hget("subject_"..wkds_info[21],"stage_subject")[1]
				 resource_info_res["subject_id"] = wkds_info[21]
				 resource_info_res["stage_id"] = ssdb_db:hget("subject_"..wkds_info[21],"stage_id")[1]
				 
				 
				 resource_info_tab[i_count] = resource_info_res
				 
			elseif sys_type == "bk" then
				--local resource_info = redis_db:hmget("resource_"..resource_info_id,"resource_id_int","resource_title","create_time","person_id","file_id","thumb_id","preview_status","resource_id_char","for_urlencoder_url","for_iso_url","person_name","resource_format","width","height","resource_page","subject_id","stage_id")
				
				local resource_info = ssdb_db:multi_hget("resource_"..resource_info_id,"resource_id_int","resource_title","create_time","person_id","file_id","thumb_id","preview_status","resource_id_char","for_urlencoder_url","for_iso_url","person_name","resource_format","width","height","resource_page","subject_id","stage_id")
				resource_info_res["iid"] = resource_info_id
				resource_info_res["resource_id_int"] = resource_info[2]
				resource_info_res["resource_title"] = resource_info[4]
				resource_info_res["create_time"] = resource_info[6]
				resource_info_res["person_id"] = resource_info[8]
				resource_info_res["file_id"] = resource_info[10]
				--resource_info_res["thumb_id"] = resource_info[6]
				resource_info_res["preview_status"] = resource_info[14]
				resource_info_res["resource_id_char"] = resource_info[16]				
				resource_info_res["is_zd"] = is_zd				
				local org_name = ""
				local person_name = ""
				if resource_info[8]=="32" or resource_info[8]=="34" then
					org_name = "未知"
					person_name = "未知"
				elseif resource_info[8] =="1" then
					org_name = "东师理想";
					person_name = "东师理想";
				else
					local xiao = redis_db:hget("person_"..resource_info[8].."_5","xiao");					
					if xiao ~= ngx.null then
						org_name = redis_db:hget("t_base_organization_"..xiao,"org_name")
					else
						org_name = "未知"
					end
					person_name = resource_info[22]
				end
				resource_info_res["person_name"] = person_name
				resource_info_res["org_name"] = org_name
				resource_info_res["resource_format"] = resource_info[24]
				resource_info_res["width"] = resource_info[26]
				resource_info_res["height"] = resource_info[28]
				resource_info_res["resource_page"] = resource_info[30]
				resource_info_res["stage_subject"] = ssdb_db:hget("subject_"..resource_info[32],"stage_subject")[1]
				resource_info_res["subject_id"] = resource_info[32]
				resource_info_res["stage_id"] = resource_info[34]
				
				
				resource_info_tab[i_count] = resource_info_res
			else
				local paper_info = redis_db:hmget("paper_"..resource_info_id,"paper_name","paper_type","extension","paper_id_char","paper_id_int","person_id","subject_id","stage_id")
				
				resource_info_res["iid"] = resource_info_id
				resource_info_res["paper_name"] = paper_info[1]
				resource_info_res["paper_source"] = paper_info[2]				
				resource_info_res["extenstion"] = paper_info[3]				
				resource_info_res["paper_id_char"] = paper_info[4]
				resource_info_res["paper_id_int"] = paper_info[5]
				resource_info_res["person_id"] = paper_info[6]
				
				local preview_status = ""
				local for_iso_url = ""
				local for_urlencoder_url = ""
				local file_id = ""
				local page = ""
				
				if paper_info[2]=="2" then
					local resource_info_id = redis_db:hmget("paper_"..resource_info_id,"resource_info_id")[1]
					--local resource_info = redis_db:hmget("resource_"..resource_info_id,"preview_status","for_iso_url","for_urlencoder_url","file_id","resource_page","structure_id","scheme_id_int")
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
				
				local org_name = ""
				local person_name = ""
				if paper_info[6]=="32" or paper_info[6]=="34" then
					org_name = "未知"
					person_name = "未知"
				elseif paper_info[6] =="1" then
					org_name = "东师理想";
					person_name = "东师理想";
				else
					local xiao = redis_db:hget("person_"..paper_info[6].."_5","xiao");					
					if xiao ~= ngx.null then
						org_name = redis_db:hget("t_base_organization_"..xiao,"org_name")
					else
						org_name = "未知"
					end
					person_name = redis_db:hget("person_"..paper_info[6].."_5","person_name")
				end
				
				resource_info_res["person_name"] = person_name
				resource_info_res["org_name"] = org_name
				resource_info_res["subject"] = ssdb_db:hget("subject_"..paper_info[7],"stage_subject")[1]
				resource_info_res["subject_id"] = paper_info[7]
				resource_info_res["stage_id"] = paper_info[8]
				resource_info_res["is_zd"] = is_zd
				
				resource_info_tab[i_count] = resource_info_res
				
			end
			i_count = i_count+1
	end

	local result = {}
	result["list"] = resource_info_tab 
	result["totalRow"] = totalRow
	result["totalPage"] = totalPage
	result["pageNumber"] = pageNumber
	result["pageSize"] = pageSize
	result["success"] = true

	--放回到SSDB连接池
	ssdb_db:set_keepalive(0,v_pool_size)
	--redis放回连接池
	redis_db:set_keepalive(0,v_pool_size)
	
	local cjson = require "cjson"

	ngx.print(cjson.encode(result))
else
	local result = {}
	result["list"] = resource_info_tab 
	result["totalRow"] = 0
	result["totalPage"] = 0
	result["pageNumber"] = tonumber(pageNumber)
	result["pageSize"] = tonumber(pageSize)
	result["success"] = true

	--放回到SSDB连接池
	ssdb_db:set_keepalive(0,v_pool_size)
	--redis放回连接池
	redis_db:set_keepalive(0,v_pool_size)

	
	cjson.encode_empty_table_as_object(false);
	ngx.print(cjson.encode(result))	

end
