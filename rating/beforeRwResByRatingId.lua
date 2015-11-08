local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

local cjson = require "cjson"

--评比ID
if args["rating_id"] == nil or args["rating_id"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"rating_id参数错误！\"}")
    return
end
local rating_id = args["rating_id"]

--学段ID
if args["stage_id"] == nil or args["stage_id"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"stage_id参数错误！\"}")
    return
end
local stage_id = args["stage_id"]

--学科ID
if args["subject_id"] == nil or args["subject_id"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"subject_id参数错误！\"}")
    return
end
local subject_id = args["subject_id"]

--第几页
if args["pageNumber"] == nil or args["pageNumber"] == "" then
    ngx.say("{\"success\":false,\"info\":\"pageNumber参数错误！\"}")
    return
end
local pageNumber = args["pageNumber"]

--一页显示多少
if args["pageSize"] == nil or args["pageSize"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"pageSize参数错误！\"}")
    return
end
local pageSize = args["pageSize"]

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

--创建ssdb连接
local ssdblib = require "resty.ssdb"
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
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

--加码
function encodeURI(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end

local stage_str = ""
if stage_id ~= "-1" then
	stage_str = " AND stage_id="..stage_id
end

local subject_str = ""
if subject_id ~= "-1" then
	subject_str = " AND subject_id="..subject_id
end

local resource_count = mysql_db:query("SELECT count(1) as count FROM t_rating_resource WHERE rating_id = "..rating_id.." AND resource_status = 3 AND award_id=0"..stage_str..subject_str..w_type)
ngx.log(ngx.ERR,"SELECT count(1) as count FROM t_rating_resource WHERE rating_id = "..rating_id.." AND resource_status = 3 AND award_id=0"..stage_str..subject_str..w_type)

local offset = pageSize*pageNumber-pageSize
local limit = pageSize
local totalRow = resource_count[1]["count"]
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

local resource_info = mysql_db:query("SELECT id,resource_info_id,person_name,bureau_name,view_count,vote_count FROM t_rating_resource T1 WHERE rating_id = "..rating_id.." AND resource_status = 3 AND award_id=0"..stage_str..subject_str..w_type.." ORDER BY award_id ASC,view_count,vote_count DESC LIMIT "..offset..","..limit..";")

local resource_tab = {}

if resource_info[1] ~= nil then
	for i=1,#resource_info do
		local resource_res = {}
		local resource_info_id = resource_info[i]["resource_info_id"]
		local person_name = resource_info[i]["person_name"]
		local bureau_name = resource_info[i]["bureau_name"]
		local rating_title = resource_info[i]["rating_title"]
		local award = resource_info[i]["award"]
		local id = resource_info[i]["id"]
		local view_count = resource_info[i]["view_count"]
		local vote_count = resource_info[i]["vote_count"]
		resource_res["id"] = id
		local res_info
		
		if rating_type ==1 then
      --[[res_info = redis_db:hmget("resource_"..resource_info_id,"resource_format","resource_page","resource_size","file_id","thumb_id","preview_status","width","height","resource_title")
      resource_res["resource_format"] = res_info[1]
      resource_res["resource_page"] = res_info[2]
      resource_res["resource_size"] = res_info[3]
      resource_res["file_id"] = res_info[4]
      resource_res["thumb_id"] = res_info[5]
      resource_res["preview_status"] = res_info[6]
      resource_res["width"] = res_info[7]
      resource_res["height"] = res_info[8]
      resource_res["resource_title"] = res_info[9]
      resource_res["url_code"] = encodeURI(res_info[9])]]
	  res_info = ssdb:multi_hget("resource_"..resource_info_id,"resource_format","resource_page","resource_size","file_id","thumb_id","preview_status","width","height","resource_title")
	  resource_res["resource_format"] = res_info[2]
	  resource_res["resource_page"] = res_info[4]
	  resource_res["resource_size"] = res_info[6]		
	  resource_res["file_id"] = res_info[8]
	  resource_res["thumb_id"] = res_info[10]
	  resource_res["preview_status"] = res_info[12]
	  resource_res["width"] = res_info[14]
	  resource_res["height"] = res_info[16]
	  resource_res["resource_title"] = res_info[18]
	  resource_res["url_code"] = encodeURI(res_info[18])
		else
		res_info = redis_db:hmget("wkds_"..resource_info_id,"wkds_id_int","wkds_id_char","scheme_id","structure_id","wkds_name","study_instr","teacher_name","play_count","score_count","create_time","download_count","downloadable","person_id","table_pk","group_id","content_json","wk_type","wk_type_name","type_id","uploader_id")
      resource_res["resource_info_id"] = resource_info_id
      resource_res["wkds_id_int"] = res_info[1]
      resource_res["wkds_id_char"] = res_info[2]
      resource_res["scheme_id_int"] = res_info[3]
      resource_res["structure_id"] = res_info[4]
      resource_res["wkds_name"]  = res_info[5]
      resource_res["study_instr"]  = res_info[6]
      resource_res["teacher_name"]  = res_info[7]
      resource_res["play_count"]  = res_info[8]
      resource_res["score_average"]  = res_info[9]
      resource_res["create_time"]  = res_info[10]
      resource_res["download_count"]  = res_info[11]

      resource_res["downloadable"]  = res_info[12]
      resource_res["person_id"]  = res_info[13]
      resource_res["table_pk"]  = res_info[14]
      resource_res["group_id"]  = res_info[15]
      resource_res["content_json"]  = res_info[16]
      resource_res["wk_type"]  = res_info[17]
      resource_res["wk_type_name"]  = res_info[18]
      resource_res["type_id"]  = res_info[19]
      resource_res["uploader_id"]  = res_info[20]
	  
	  
	  	  local  thumb_id = ""
local content_json = res_info[16]
local aa = ngx.decode_base64(content_json)
local data = cjson.decode(aa)
if #data.sp_list~=0 then

  local resource_info_id = data.sp_list[1].id

  if resource_info_id ~= ngx.null then
    --local thumbid = redis_db:hmget("resource_"..resource_info_id,"thumb_id")
	local thumbid = ssdb:multi_hget("resource_"..resource_info_id,"thumb_id")
    if tostring(thumbid[2]) ~= "userdata: NULL" then
      thumb_id = thumbid[2]
    end
  end
else
  thumb_id = "E6648460-4FFD-E626-1C14-6FBF9F94A23C"
end

if not thumb_id or string.len(thumb_id) == 0 then
  thumb_id = "E6648460-4FFD-E626-1C14-6FBF9F94A23C"
end
resource_res["thumb_id"]  = thumb_id
	  
	  
	  
		end
		resource_res["person_name"] = person_name
		resource_res["org_name"] = bureau_name
		resource_res["rating_title"] = rating_title
		resource_res["view_count"] = view_count
		resource_res["vote_count"] = vote_count		
		resource_tab[i] = resource_res
	end
end

local result = {} 
result["list"] = resource_tab
result["totalRow"] = totalRow
result["totalPage"] = totalPage
result["pageNumber"] = pageNumber
result["pageSize"] = pageSize
result["success"] = true

mysql_db:set_keepalive(0,v_pool_size)
redis_db:set_keepalive(0,v_pool_size)
ssdb:set_keepalive(0,v_pool_size)
cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))



