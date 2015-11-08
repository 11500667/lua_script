#ngx.header.content_type = "text/plain;charset=utf-8"
local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)
local cookie_token = tostring(ngx.var.cookie_token)

--[[判断是否有person_id的cookie信息
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
--]]

local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--科目号
--local subject_id = tostring(args["subject_id"])
--if subject_id == "nil" then
--    ngx.say("{\"success\":false,\"info\":\"subject_id参数错误！\"}")
--    return
--end

--按谁排序  1：教师  2：播放次数  3：平均分 4：时间 5：下载次数
local sort_type = tostring(args["sort_type"])
--判断是否有排序的参数
if sort_type == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"sort_type参数错误！\"}")
    return
end

--升序还是降序   1：ASC   2:DESC
local sort_num = tostring(args["sort_order"])
--判断是否有排序的参数
if sort_num == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"sort_num参数错误！\"}")
    return
end

local  limit = tostring(args["limit"])

if limit == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"limit参数错误！\"}")
    return
end

--升序还是降序
local asc_desc = ""
if sort_num=="1" then
    asc_desc = "asc"
else
    asc_desc = "desc"
end 

--  拼接排序的语句
local sort_filed = ""

    if sort_type=="1" then
       sort_filed = "groupsort=teacher_name_py "..asc_desc..";"
    elseif sort_type=="2" then
      sort_filed = "groupsort=play_count "..asc_desc..";"
    elseif sort_type=="3" then
      sort_filed = "groupsort=score_average "..asc_desc..";"
    elseif sort_type=="4" then
      sort_filed = "groupsort=ts "..asc_desc..";" 
    elseif sort_type=="5" then
      sort_filed = "groupsort=download_count "..asc_desc..";"      
    end
--local subject_id_str = "filter=subject_id,"..subject_id..";";

    -- ngx.log(ngx.ERR,"SELECT SQL_NO_CACHE id FROM t_wkds_info_sphinxse  WHERE query=\'filter=group_id,1;filter=isdraft,0;filter=check_status,0,1;filter=b_delete,0;groupby=attr:wkds_id_int;"..sort_filed.."limit="..limit.."\'");
   --ngx.say("SELECT SQL_NO_CACHE id FROM t_wkds_info_sphinxse  WHERE query=\'"..subject_id_str.."filter=group_id,1;filter=isdraft,0;filter=check_status,0,1;filter=b_delete,0;groupby=attr:wkds_id_int;"..sort_filed.."limit="..limit.."\'")

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
local wkds = ""
wkds = db:query("SELECT SQL_NO_CACHE id FROM t_wkds_info_sphinxse  WHERE query=\'filter=type,2;filter=type_id,6;filter=isdraft,0;filter=check_status,0,1;filter=b_delete,0;groupby=attr:wkds_id_int;"..sort_filed.."limit="..limit.."\'");
ngx.log(ngx.ERR, "SELECT SQL_NO_CACHE id FROM t_wkds_info_sphinxse  WHERE query=\'filter=type,2;filter=type_id,6;filter=isdraft,0;filter=check_status,0,1;filter=b_delete,0;groupby=attr:wkds_id_int;"..sort_filed.."limit="..limit.."\'")
local cjson = require "cjson"
local wkds_info = ""
for i=1,#wkds do
  --      local cbanba = wkds[i]["id"]
      local str = "{\"id\":\""..wkds[i]["id"].."\",\"wkds_id_int\":\"##\",\"wkds_id_char\":\"##\",\"scheme_id_int\":\"##\",\"structure_id\":\"##\",\"wkds_name\":\"##\",\"study_instr\":\"##\",\"teacher_name\":\"##\",\"play_count\":\"##\",\"score_average\":\"##\",\"create_time\":\"##\",\"download_count\":\"##\",\"thumb_id\":\"##\",\"downloadable\":\"##\",\"person_id\":\"##\",\"table_pk\":\"##\",\"group_id\":\"##\"}"

      local wkds_value_null = cache:hmget("wkds_"..wkds[i]["id"],"wkds_id_int")
    if wkds_value_null[1] ~=ngx.null then

       local wkds_value = cache:hmget("wkds_"..wkds[i]["id"],"wkds_id_int","wkds_id_char","scheme_id","structure_id","wkds_name","study_instr","teacher_name","play_count","score_average","create_time","download_count","thumb_id","downloadable","person_id","table_pk","group_id","content_json")
         local  thumb_id = ""
       for j=1,#wkds_value do
        
          if j==12 then 
            --解析json数据获得第一个视频的缩略图，如果没有显示默认的缩略图
            local content_json = wkds_value[17]
                       local aa = ngx.decode_base64(content_json)
                       local data = cjson.decode(aa)
                       if #data.sp_list~=0 then

                          local resource_info_id = data.sp_list[1].id
                          if resource_info_id ~= ngx.null then
                            --ngx.log(ngx.ERR,"==========="..resource_info_id)
                           local thumbid = cache:hmget("resource_"..resource_info_id,"thumb_id")
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
               str = string.gsub(str,"##",thumb_id,1)
           else
              -- ngx.log(ngx.ERR,"+++++++++"..wkds_value[j])
               str = string.gsub(str,"##",wkds_value[j],1)
           end
        
       end     
       wkds_info = wkds_info..str..","
end
end
--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0,v_pool_size)

wkds_info = string.sub(wkds_info,0,#wkds_info-1)
ngx.say("{\"success\":\"true\",\"list\":["..wkds_info.."]}")
