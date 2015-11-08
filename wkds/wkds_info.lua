#ngx.header.content_type = "text/plain;charset=utf-8"

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

local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end
--微课id
local id = tostring(args["id"])
--判断是否有结点ID参数
if id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"id参数错误！\"}")
    return
end
--UFT_CODE
local function urlencode(s)
      s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end

local cjson = require "cjson"
--根据微课的id去缓存中获得微课中包含的资源的详细信息
local wkds_info = cache:hmget("wkds_"..id,"content_json","wk_type_name","stage_id","w_type","play_count")
local wk_type_name = wkds_info[2];
--ngx.say(wkds_info[1].."*********")
local content_json = wkds_info[1]

 if  content_json == ngx.null then
         ngx.say("{\"success\":false,\"info\":\"没有找到该微课的信息！\"}")    
         return
   else
         local data = cjson.decode(ngx.decode_base64(content_json))

            --视频数组
            local spArray={}
            --素材数组
            local scArray={}
            --学习指导
            local studyArray={}
            --练习
            local practicerArray={}
            --设计说明
            local design_listArray={}

          if #data.sp_list ~= 0 then
            for i=1,#data.sp_list do

                 local  resource_info_id = data.sp_list[i].id 

                 local sp_value = ssdb_db:multi_hget("resource_"..resource_info_id,"resource_title","thumb_id","preview_status","resource_format","file_id","resource_page","m3u8_status","m3u8_url","width","height");  


                 local tab1 = {}
                 tab1["id"]=resource_info_id
                 tab1["title"]=sp_value[2]
                 tab1["thumb_id"]=sp_value[4]
                 tab1["preview_status"]=sp_value[6]
                 tab1["extension"]=sp_value[8]
                 tab1["file_id"]=sp_value[10]
		         tab1["fileid"]=sp_value[10]
                 tab1["page"]=sp_value[12]
                 tab1["m3u8_status"]=sp_value[14]
                 tab1["m3u8_url"]=ngx.encode_base64(sp_value[16])
                 tab1["width"]=sp_value[18]
                 tab1["height"]=sp_value[20]
				 tab1["url_code"]=urlencode(sp_value[2])
                 spArray[i]=tab1
            end
          end

          if #data.sc_list ~= 0 then
            for i=1,#data.sc_list do

                 local  resource_info_id = data.sc_list[i].id 
                 local sp_value = ssdb_db:multi_hget("resource_"..resource_info_id,"resource_title","thumb_id","preview_status","resource_format","file_id","resource_page","width","height");         
                 local tab2 = {}
                 tab2["id"]=resource_info_id
                 tab2["title"]=sp_value[2]
                 tab2["thumb_id"]=sp_value[4]
                 tab2["preview_status"]=sp_value[6]
                 tab2["extension"]=sp_value[8]
                 tab2["file_id"]=sp_value[10]
                 tab2["page"]=sp_value[12]
				 tab2["width"]=sp_value[14]
                 tab2["height"]=sp_value[16]
				 
                 scArray[i]=tab2
            end
          end
          
          if #data.study_list ~= 0 then
            for i=1,#data.study_list do

                 local  resource_info_id = data.study_list[i].id 
                 local sp_value = ssdb_db:multi_hget("resource_"..resource_info_id,"resource_title","thumb_id","preview_status","resource_format","file_id","resource_page","width","height");         
                 local tab3 = {}
                 tab3["id"]=resource_info_id
                 tab3["title"]=sp_value[2]
                 tab3["thumb_id"]=sp_value[4]
                 tab3["preview_status"]=sp_value[6]
                 tab3["extension"]=sp_value[8]
                 tab3["file_id"]=sp_value[10]
                 tab3["page"]=sp_value[12]
				  tab3["width"]=sp_value[14]
                 tab3["height"]=sp_value[16]
                 studyArray[i]=tab3                 
            end
          end

          if #data.practice_list ~= 0 then

            for i=1,#data.practice_list do

                 local  resource_info_id =  data.practice_list[i].id;
                 local sp_value 
                 local info_id  ="-1"
                 local  paper_source  =data.practice_list[i].paper_source
                 if paper_source == "3" then
                     sp_value = ssdb_db:multi_hget("resource_"..resource_info_id,"resource_title","preview_status","resource_format","file_id","resource_page","width","height"); 
                 elseif paper_source == "1" then
                      sp_value = cache:hmget("paper_"..resource_info_id,"paper_name","preview_status","extension","file_id","paper_page");  
                 else 
                     info_id = cache:hmget("paper_"..resource_info_id,"resource_info_id")[1];
                     sp_value = cache:hmget("paper_"..resource_info_id,"paper_name"); 
					 
                     local resource_info = ssdb_db:multi_hget("resource_"..info_id,"preview_status","file_id","resource_page","resource_format","width","height");
                      sp_value[4] =  resource_info[2];
                      sp_value[6] =  resource_info[8];
                      sp_value[8] =  resource_info[4];
                      sp_value[10] =  resource_info[6];
					  sp_value[12] =  resource_info[10];
					  sp_value[14] =  resource_info[12];
                 end  
                 local tab4 = {}
                 tab4["id"]=resource_info_id
				 if paper_source == "3" then
				     tab4["title"]=sp_value[2]
				 else
				     tab4["title"]=sp_value[1]
				 end
                
                 tab4["preview_status"]=sp_value[4]
                 tab4["extension"]=sp_value[6]
                 tab4["file_id"]=sp_value[8]
                 tab4["page"]=sp_value[10]
				 tab4["width"]=sp_value[12]
				 tab4["height"]=sp_value[14]
                 tab4["paper_source"]=paper_source
                 tab4["paper_id"]=data.practice_list[i].paper_id
                 tab4["resource_info_id"]=info_id;


                 practicerArray[i]=tab4                 
            end
          end

            if tostring(data.design_list) ~= "nil" then

                 if #data.design_list ~= 0 then

                 for i=1,#data.design_list do
                 local  resource_info_id = data.design_list[i].id 
                 local design_value = ssdb_db:multi_hget("resource_"..resource_info_id,"resource_title","thumb_id","preview_status","resource_format","file_id","resource_page","m3u8_status","m3u8_url","width","height");         
                 local tab5 = {}
                 tab5["id"]=resource_info_id
                 tab5["title"]=design_value[2]
                 tab5["thumb_id"]=design_value[4]
                 tab5["preview_status"]=design_value[6]
                 tab5["extension"]=design_value[8]
                 tab5["file_id"]=design_value[10]
                 tab5["page"]=design_value[12]
				 tab5["width"]=design_value[14]
				 tab5["height"]=design_value[18]
                 design_listArray[i]=tab5
            
             end
            end
          end

          local tab = {}
          tab["success"]="true"
          tab["wk_status"]=data.wk_status
          tab["create_or_update"]=data.create_or_update
          tab["subject_id"]=data.subject_id
          tab["parent_structure_name"]=data.parent_structure_name
          tab["structure_id"]=data.structure_id
          tab["scheme_id"]=data.scheme_id
          tab["subject_name"]=data.subject_name
          tab["pid_str"]=data.pid_str
          tab["is_root"]=data.is_root
          tab["wkds_name"]=data.wkds_name
          tab["teacher_name"]=data.teacher_name
          tab["downloadable"]=data.downloadable
          tab["study_instr"]=data.study_instr
          tab["design_instr"]=data.design_instr
          tab["practice_instr"]=data.practice_instr
		  tab["wk_type_name"]=wk_type_name
          tab["sp_list"]=spArray
          tab["sc_list"]=scArray
          tab["study_list"]=studyArray
          tab["practice_list"]=practicerArray
          tab["design_list"]=design_listArray
		  tab["stage_id"]=wkds_info[3];
		  tab["w_type"]=wkds_info[4];
		  tab["play_count"]=wkds_info[5];
		  
		  
		  if wkds_info[4] == "2" then
		     tab["guide_1"]=data.guide_1
			 tab["guide_2"]=data.guide_2
			 tab["guide_3"]=data.guide_3
			 tab["guide_4"]=data.guide_4
			 tab["task"]=data.task
		   
		  end
		  

          local tabs={}

         table.insert(tabs,tab);       
         local jsonData = cjson.encode(tabs)
         local str = jsonData.sub(jsonData,2,#jsonData-1);
         str = string.gsub(str,"{}","[]")
         ngx.say(str);
end
       cache:set_keepalive(0,v_pool_size)

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size);
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
