#ngx.header.content_type = "text/plain;charset=utf-8"
local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)
local cookie_token = tostring(ngx.var.cookie_token)

--判断是否有person_id的cookie信息
if cookie_person_id == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"person_id参数错误！\"}")
    return
end
--判断是否有identity_id的cookie信息
if cookie_identity_id == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"identity_id参数错误！\"}")
    return
end
--判断是否有token的cookie信息
if cookie_token == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"token参数错误！\"}")
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

--获取redis中该用户的token
local redis_token,err = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"token")
if not redis_token then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end
--验证cookie中的token和redis中存的token是否相同
if redis_token ~= cookie_token then
    ngx.say("{\"success\":\"false\",\"info\":\"错误的验证信息！\"}")
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
local cjson = require "cjson"
--根据微课的id去缓存中获得微课中包含的资源的详细信息
local wkds_info = cache:hmget("wkds_"..id,"content_json")
--ngx.say(wkds_info[1].."*********")
local content_json = wkds_info[1]
 if  content_json == ngx.null then
         ngx.say("{\"success\":false,\"info\":\"没有找到该微课的信息！\"}")    
         return
   else
         local data = cjson.decode(ngx.decode_base64(content_json))

         --视频的列表开始
         local sp_list = "[]";
         if #data.sp_list ~= 0 then
             sp_list = "["
             for i=1,#data.sp_list do
                local  resource_info_id = data.sp_list[i].id
               -- ngx.say("resource_info_id="..resource_info_id)
                
                 local str = "{\"id\":\""..resource_info_id.."\",\"title\":\"##\",\"thumb_id\":\"##\",\"preview_status\":\"##\",\"extension\":\"##\",\"file_id\":\"##\",\"page\":\"##\"}"
                --根据资源的info表id去资源的缓存中取值
                local sp_value = cache:hmget("resource_"..resource_info_id,"resource_title","thumb_id","preview_status","resource_format","file_id","resource_page");
                 for j=1,#sp_value do
                     str = string.gsub(str,"##",sp_value[j],1)
                 end
                 sp_list = sp_list .. str ..","
                 
             end
        sp_list = sp_list.sub(sp_list,0,#sp_list-1)
        sp_list = sp_list.."]"
       end   
     --  ngx.say("sp_list="..sp_list)  
       --视频的列表结束

       --素材附件开始
        local sc_list = "[]";
         if #data.sc_list ~= 0 then
             sc_list = "["
             for i=1,#data.sc_list do
                local  resource_info_id = data.sc_list[i].id
               -- ngx.say("resource_info_id="..resource_info_id)
                
                 local str = "{\"id\":\""..resource_info_id.."\",\"title\":\"##\",\"thumb_id\":\"##\",\"preview_status\":\"##\",\"extension\":\"##\",\"file_id\":\"##\",\"page\":\"##\"}"
                --根据资源的info表id去资源的缓存中取值
                local sc_value = cache:hmget("resource_"..resource_info_id,"resource_title","thumb_id","preview_status","resource_format","file_id","resource_page");
                 for j=1,#sc_value do
                     str = string.gsub(str,"##",sc_value[j],1)
                 end
                 sc_list = sc_list .. str ..","
                 
             end
        sc_list = sc_list.sub(sc_list,0,#sc_list-1)
        sc_list = sc_list.."]"
       end   
     --  ngx.say("sc_list="..sc_list)  
        --素材附件结束

       --学习指导列表开始
         local study_list = "[]";
         if #data.study_list ~= 0 then
             study_list = "["
             for i=1,#data.study_list do
                local  resource_info_id = data.study_list[i].id
               --ngx.say("resource_info_id="..resource_info_id)
              
                 local str = "{\"id\":\""..resource_info_id.."\",\"title\":\"##\",\"thumb_id\":\"##\",\"preview_status\":\"##\",\"extension\":\"##\",\"file_id\":\"##\",\"page\":\"##\"}"
                --根据资源的info表id去资源的缓存中取值
                local study_value = cache:hmget("resource_"..resource_info_id,"resource_title","thumb_id","preview_status","resource_format","file_id","resource_page");
                 for j=1,#study_value do
                     str = string.gsub(str,"##",study_value[j],1)
                 end
                 study_list = study_list .. str ..","
          end
       study_list = study_list.sub(study_list,0,#study_list-1)
       study_list = study_list.."]"
      end   
    --  ngx.say("study_list="..study_list)
       --学习指导列表结束

       --练习附件开始
         local practicer_list = "[]";
         if #data.practicer_list ~= 0 then
             practicer_list = "["
             for i=1,#data.practicer_list do
                local  resource_info_id = data.practicer_list[i].id
                
                  local str = "{\"id\":\""..resource_info_id.."\",\"title\":\"##\",\"thumb_id\":\"##\",\"preview_status\":\"##\",\"extension\":\"##\",\"file_id\":\"##\",\"page\":\"##\"}"
                --根据资源的info表id去资源的缓存中取值
                local practicer_value = cache:hmget("resource_"..resource_info_id,"resource_title","thumb_id","preview_status","resource_format","file_id","resource_page");
                 for j=1,#practicer_value do
                     str = string.gsub(str,"##",practicer_value[j],1)
                 end
                 practicer_list = practicer_list .. str ..","
                 
             end
        practicer_list = practicer_list.sub(practicer_list,0,#practicer_list-1)
        practicer_list = practicer_list.."]"   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
       end   
     --  ngx.say("practicer_list="..practicer_list)
      --练习附件结束
       local wkds_info_json = "{\"success\":\"true\",\"wk_status\":\""..data.wk_status.."\",\"create_or_update\":\""..data.create_or_update.."\",\"subject_id\":\""..data.subject_id.."\",\"parent_structure_name\":\""..data.parent_structure_name.."\",\"structure_id\":\""..data.structure_id.."\",\"scheme_id\":\""..data.scheme_id.."\",\"subject_name\":\""..data.subject_name.."\",\"pid_str\":\""..data.pid_str.."\",\"is_root\":\""..data.is_root.."\",\"wkds_name\":\""..data.wkds_name.."\",\"teacher_name\":\""..data.teacher_name.."\",\"study_instr\":\""..data.study_instr.."\",\"design_instr\":\""..data.design_instr.."\",\"practice_instr\":\""..data.practice_instr.."\",\"downloadable\":\""..data.downloadable.."\",\"sp_list\":"..sp_list..",\"sc_list\":"..sc_list..",\"study_list\":"..study_list..",\"practicer_list\":"..practicer_list.."}"
   --redis放回连接池
        cache:set_keepalive(0,v_pool_size)
       ngx.say(wkds_info_json)
     end
            

 

  
