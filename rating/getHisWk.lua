#ngx.header.content_type = "text/plain;charset=utf-8"
local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
  args = ngx.req.get_uri_args()
else
  ngx.req.read_body()
  args = ngx.req.get_post_args()
end

--引用模块
local cjson = require "cjson"

-- 获取数据库连接
local mysql = require "resty.mysql";
local db, err = mysql : new();
if not db then
  ngx.log(ngx.ERR, err);
  return;
end

db:set_timeout(1000) -- 1 sec

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

local ok, err, errno, sqlstate = db:connect{
  host = v_mysql_ip,
  port = v_mysql_port,
  database = v_mysql_database,
  user = v_mysql_user,
  password = v_mysql_password,
  max_packet_size = 1024 * 1024 }

if not ok then
  ngx.log(ngx.ERR, "=====> 连接数据库失败!");
  return;
end

--person_id
if args["person_id"] == nil or args["person_id"] == "" then
  ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
  return
end
local person_id = args["person_id"]


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

local res_count = db:query("select count(*) as count from t_his_wk where person_id="..person_id.."")



local offset = pageSize*pageNumber-pageSize
local limit = pageSize
local totalRow = res_count[1]["count"]
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)




--local person_id = tostring(ngx.var.cookie_person_id)
if(person_id == nil or person_id == "" or person_id==ngx.null or person_id == "nil") then
  ngx.say("{\"success\":false,\"info\":\"person_id不存在！\"}")
  return
end

local querysql = "select id,wkds_id_int,update_time,times,re_type,dis_type,wk_id from t_his_wk where  person_id="..person_id.." order by update_time desc LIMIT "..offset..","..limit..";"
local wk, err, errno, sqlstate = db:query(querysql)
ngx.log(ngx.ERR,querysql)
if not wk then
  ngx.log(ngx.ERR, "err: ".. err);
  return
end

local rating_tab = {}
for i=1,#wk do
  local rating_res = {}
  rating_res["id"] = wk[i]["wk_id"]
  rating_res["wkds_id_int"] = wk[i]["wkds_id_int"]
  local querysql = "select id from t_wkds_info where  wkds_id_int="..wk[i]["wkds_id_int"].." ;"
	local wk1, err, errno, sqlstate = db:query(querysql)
	ngx.log(ngx.ERR,querysql)
	if not wk1 then
	ngx.log(ngx.ERR, "err: ".. err);
	return
	end
	local wkds_id_int = wk1[1]["id"]
  rating_res["update_time"] = wk[i]["update_time"]
  rating_res["times"] = wk[i]["times"]
  
  rating_res["re_type"] = wk[i]["re_type"]
  rating_res["dis_type"] = wk[i]["dis_type"]
  
    res_info = redis_db:hmget("wkds_"..wkds_id_int,"wkds_id_int","wkds_id_char","scheme_id","structure_id","wkds_name","study_instr","teacher_name","play_count","score_count","create_time","download_count","downloadable","person_id","table_pk","group_id","content_json","wk_type","wk_type_name","type_id","uploader_id")
      rating_res["resource_info_id"] = resource_info_id
      rating_res["wkds_id_int"] = res_info[1]
      rating_res["wkds_id_char"] = res_info[2]
      rating_res["scheme_id_int"] = res_info[3]
      rating_res["structure_id"] = res_info[4]
      rating_res["wkds_name"]  = res_info[5]
      rating_res["study_instr"]  = res_info[6]
      rating_res["teacher_name"]  = res_info[7]
      rating_res["play_count"]  = res_info[8]
      rating_res["score_average"]  = res_info[9]
      rating_res["create_time"]  = res_info[10]
      rating_res["download_count"]  = res_info[11]

      rating_res["downloadable"]  = res_info[12]
      rating_res["person_id"]  = res_info[13]
      rating_res["table_pk"]  = res_info[14]
      rating_res["group_id"]  = res_info[15]
      rating_res["content_json"]  = res_info[16]
      rating_res["wk_type"]  = res_info[17]
      rating_res["wk_type_name"]  = res_info[18]
      rating_res["type_id"]  = res_info[19]
      rating_res["uploader_id"]  = res_info[20]
    
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
rating_res["thumb_id"]  = thumb_id
  
  rating_tab[i] = rating_res
end

local returnjson = {}
returnjson["list"] = rating_tab
returnjson.success = true
returnjson["totalRow"] = tonumber(totalRow)
returnjson["totalPage"] = tonumber(totalPage)
returnjson["pageNumber"] = tonumber(pageNumber)
returnjson["pageSize"] = tonumber(pageSize)
cjson.encode_empty_table_as_object(false)
db:set_keepalive(0,v_pool_size)
redis_db:set_keepalive(0,v_pool_size)
ssdb:set_keepalive(0,v_pool_size)
ngx.log(ngx.ERR,cjson.encode(returnjson))
ngx.print(cjson.encode(returnjson))