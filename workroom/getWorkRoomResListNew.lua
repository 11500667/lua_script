local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

local cjson = require "cjson"

--获取教师ID
if args["teacher_id"] == nil or args["teacher_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"teacher_id参数错误！\"}")
    return
end
local teacher_id = args["teacher_id"]

--工作室ID
if args["club_id"] == nil or args["club_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"club_id参数错误！\"}")
    return
end
local club_id = args["club_id"]


--获取res_type
if args["res_type"] == nil or args["res_type"] == "" then
    ngx.say("{\"success\":false,\"info\":\"res_type参数错误！\"}")
    return
end
local res_type = args["res_type"]

--获取res_cascade_type
if args["res_cascade_type"] == nil or args["res_cascade_type"] == "" then
    ngx.say("{\"success\":false,\"info\":\"res_cascade_type参数错误！\"}")
    return
end
local res_cascade_type = args["res_cascade_type"]

--获取每页显示多少条
if args["pageSize"] == nil or args["pageSize"] == "" then
    ngx.say("{\"success\":false,\"info\":\"pageSize参数错误！\"}")
    return
end
local pageSize = args["pageSize"]

--获取每页显示多少条
if args["pageNumber"] == nil or args["pageNumber"] == "" then
    ngx.say("{\"success\":false,\"info\":\"pageNumber参数错误！\"}")
    return
end
local pageNumber = args["pageNumber"]

--判断是哪个项目1唐山项目 2云版项目
if args["type_id"] == nil or args["type_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"type_id参数错误！\"}")
    return
end
local type_id = args["type_id"]

--拼teacher_id条件
local personid_str = "filter=person_id,"..teacher_id..";"
--拼club_id条件
local clubid_str = "filter=pub_target,"..club_id..";"

--拼res_type条件
local restype_str="";
if restype_str ~= "-1" then
     restype_str = "filter=obj_type,"..res_type..";"
end
local myPrime = require "resty.PRIME";
local  app_val_tab = {2,3,5,7,11,13,17};
--拼res_cascade_type条件
local resourcetype_str = ""
if type_id=="1" then
    if res_cascade_type ~= "-1" then
       local search_app_vals = myPrime.getCombineValuesNew(app_val_tab,tonumber(res_cascade_type));
          resourcetype_str = "filter=app_type_id,"..search_app_vals..";"
    end
elseif type_id == "2"  then
     if res_cascade_type ~= "-1" then
          resourcetype_str = "filter=media_type,"..res_cascade_type..";"
    end
elseif  type_id == "3" then
     if res_cascade_type ~= "-1" then
          resourcetype_str = "filter=bk_type,"..res_cascade_type..";"
    end
end
--[[
if type_id==1 then
    if res_cascade_type ~= "-1" then
         resourcetype_str = "filter=resource_type,"..res_cascade_type..";"
    end
end
--]]
--计算offset和limit
local offset = pageSize*pageNumber-pageSize
local limit = pageSize
--设置查询最大匹配的数量
local str_maxmatches = "3000"



--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end
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

--UFT_CODE
--[[local function urlEncode(str)
    if (str) then
        str = string.gsub (str, "\n", "\r\n")
        str = string.gsub (str, "([^%w ])",
        function (c) return string.format ("%%%%%02X", string.byte(c)) end)
    end
    return str
end]]
function urlEncode(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end

--计算offset和limit
local offset = pageSize*pageNumber-pageSize
local limit = pageSize
--设置查询最大匹配的数量
local str_maxmatches = "3000"

--ngx.say("SELECT SQL_NO_CACHE ID FROM T_BASE_PUBLISH_SPHINXSE WHERE QUERY='"..clubid_str..personid_str..restype_str..resourcetype_str.."groupby=attr:obj_id_int;groupsort=ts desc;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;");


-- 拼接查询的表
local table_name = "";
if res_type == "3" then
   table_name = "t_base_publish_paper_sphinxse";
elseif res_type == "5" then
   table_name = "t_base_publish_wk_sphinxse";
else 
    table_name ="T_BASE_PUBLISH_SPHINXSE";
end


local res = db:query("SELECT SQL_NO_CACHE ID FROM "..table_name.." WHERE QUERY='"..clubid_str..personid_str..restype_str..resourcetype_str.."filter=b_delete,0;groupby=attr:obj_id_int;groupsort=ts desc;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;");

ngx.log(ngx.ERR,"=======".."SELECT SQL_NO_CACHE ID FROM "..table_name.." WHERE QUERY='"..clubid_str..personid_str..restype_str..resourcetype_str.."filter=b_delete,0;groupby=attr:obj_id_int;groupsort=ts desc;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")
--去第二个结果集中的Status中截取总个数
local res1 = db:read_result()
local _,s_str = string.find(res1[1]["Status"],"found: ")
local e_str = string.find(res1[1]["Status"],", time:")
local totalRow = string.sub(res1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)


local resource_tab= {}

for i=1,#res do
  
   local  res_info_id = cache:hget("publish_"..res[i]["ID"],"obj_info_id");
   if tostring(res_info_id) ~= "userdata: NULL" then
      local  res_tab = {}
	   --如果获得的是微课列表
	   if res_type =="5" then 
	      local thumb_id = "";
	      local wkds_value_null = cache:hmget("wkds_"..res_info_id,"wkds_id_int");
		  if wkds_value_null[1] ~= ngx.null then
		      local wkds_value = cache:hmget("wkds_"..res_info_id,"wkds_id_int","wkds_id_char","scheme_id","structure_id","wkds_name",
			  "study_instr","teacher_name","play_count","score_average","create_time",
			  "download_count","downloadable","person_id","table_pk","group_id","content_json");
			  --获得缩略图id
			   local content_json = wkds_value[16]
                       local aa = ngx.decode_base64(content_json)
                       local data = cjson.decode(aa)
                       if #data.sp_list~=0 then

                          local resource_info_id = data.sp_list[1].id
                          if resource_info_id ~= ngx.null then
                           local thumbid = cache:hmget("resource_"..resource_info_id,"thumb_id")
                           thumb_id = thumbid[1]
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
	   
			  res_tab["id"]=res_info_id;
			  res_tab["wkds_id_int"]=wkds_value[1];
			  res_tab["wkds_id_char"]=wkds_value[2];
			  res_tab["scheme_id_int"]=wkds_value[3];
			  res_tab["structure_id"]=wkds_value[4];
			  res_tab["wkds_name"]=wkds_value[5];
			  res_tab["study_instr"]=wkds_value[6];
			  res_tab["teacher_name"]=wkds_value[7];
			  res_tab["play_count"]=wkds_value[8];
			  res_tab["score_average"]=wkds_value[9];
			  res_tab["create_time"]=wkds_value[10];
			  res_tab["download_count"]=wkds_value[11];
			  res_tab["thumb_id"]=thumb_id;
			  res_tab["downloadable"]=wkds_value[12];
			  res_tab["person_id"]=wkds_value[13];
			  res_tab["table_pk"]=wkds_value[14];
			  res_tab["group_id"]=wkds_value[15];
			  res_tab["content_json"]=wkds_value[16];
			  res_tab["parent_structure_name"]=curr_path;
		  end
	   
	   else   
           --如果是查询试卷列表	   
		   if res_type == "3" then
			 res_info_id = cache:hget("paper_"..res_info_id,"resource_info_id");
		   end
		   --ngx.log(ngx.ERR,"RES_INFO_ID----------------------"..res_info_id);
			--local  res_info = cache:hmget("resource_"..res_info_id,"resource_title","resource_type_name","resource_size","create_time","down_count","file_id","width","height","resource_format","resource_page","thumb_id","preview_status","for_urlencoder_url","for_iso_url","resource_size_int","beike_type")
			local  res_info = ssdb:multi_hget("resource_"..res_info_id,"resource_title","resource_type_name","resource_size","create_time","down_count","file_id","width","height","resource_format","resource_page","thumb_id","preview_status","for_urlencoder_url","for_iso_url","resource_size_int","beike_type")
			res_tab["iid"] = res_info_id;      
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
	   end
        resource_tab[i] = res_tab
  end
end

--返回的table
local result = {}

result["success"] = true
result["totalRow"] = totalRow
result["totalPage"] = totalPage
result["pageNumber"] = pageNumber
result["pageSize"] = pageSize
result["list"] = resource_tab

--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0,v_pool_size)
--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false)
ngx.say(tostring(cjson.encode(result)))
