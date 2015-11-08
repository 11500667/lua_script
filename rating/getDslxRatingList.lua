--[[select * from (select id,RATING_ID from t_rating_resource where bureau_id in (select distinct BUREAU_ID from t_base_organization where province_id='100007')

union all select id,RATING_ID from t_rating_resource where bureau_id in (select distinct org_id from t_dswk_organization where province_id='100007')) a where ID=148



select * from t_rating_resource a where ID=148



]]
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
local rating_str = " and rating_id = "..rating_id
--学段ID
local stage_id = ""
local stage_str = ""
if args["stage_id"] == nil or args["stage_id"] == "" then
  stage_str = ""
else
  stage_id = args["stage_id"]
  stage_str = " and stage_id = "..stage_id
end
--学科ID
local subject_id = ""
local subject_str = ""
if args["subject_id"] == nil or args["subject_id"] == "" then

else
  subject_id = args["subject_id"]
  subject_str = " and subject_id = "..subject_id
end
--省id
local province_id = ""
local column_name = ""
local talbe_name = ""
if args["province_id"] == nil or args["province_id"] == "" then
  column_name ="id,rating_id,rating_title,rating_sub_title,resource_info_id,resource_memo,person_id,person_name,bureau_id,bureau_name,stage_id,subject_id,ts,view_count,vote_count,scorce,expert_rec,award_id,resource_status,scheme_id,sructure_id,structure_id,israting,remark,wk_type,w_type"
  talbe_name = " t_rating_resource "
else
  province_id = args["province_id"]
  column_name = "*"
  talbe_name = "(select id,rating_id,rating_title,rating_sub_title,resource_info_id,resource_memo,person_id,person_name,bureau_id,bureau_name,stage_id,subject_id,ts,view_count,vote_count,scorce,expert_rec,award_id,resource_status,scheme_id,sructure_id,structure_id,israting,remark,wk_type,w_type from t_rating_resource where bureau_id in (select distinct BUREAU_ID from t_base_organization where province_id='"..province_id.."') union all select id,rating_id,rating_title,rating_sub_title,resource_info_id,resource_memo,person_id,person_name,bureau_id,bureau_name,stage_id,subject_id,ts,view_count,vote_count,scorce,expert_rec,award_id,resource_status,scheme_id,sructure_id,structure_id,israting,remark,wk_type,w_type from t_rating_resource where bureau_id in (select distinct org_id from t_dswk_organization where province_id='"..province_id.."')) a "
end
--排序类型 view_count 浏览量 vote_count 得票数  评论数
local sort = ""
local sort_str = ""
if args["sort"] == nil or args["sort"] == "" then

else
  sort = args["sort"]
  sort_str = " order by "..sort.." desc"
end

local resource_status_str = " and resource_status in (3,4,5,6)"


--连接mysql数据库
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


ngx.log(ngx.ERR, "**********东师理想微课大赛*****查询列表开始**********");

local countsql = "select count(*) as count from "..talbe_name.." where 1 = 1 "..rating_str..stage_str..subject_str..resource_status_str..sort_str
ngx.log(ngx.ERR, countsql)
local countsql_res,err,errno,sqlstatus = db:query(countsql)
if not countsql_res then
  ngx.say("{\"success\":\"false\",\"info\":\"查询过程出错！\"}");
  ngx.log(ngx.ERR, "err: ".. err);
end
local offset = pageSize*pageNumber-pageSize
local limit = pageSize
local totalRow = countsql_res[1]["count"]
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)



local querysql = "select "..column_name.." from "..talbe_name.." where 1 = 1 "..rating_str..stage_str..subject_str..resource_status_str..sort_str.."  limit "..offset..","..limit.."; "
ngx.log(ngx.ERR,querysql)
local querysql_res,err,errno,sqlstatus = db:query(querysql);
if not querysql_res then
  ngx.say("{\"success\":\"false\",\"info\":\"查询过程出错！\"}");
  ngx.log(ngx.ERR, "err: ".. err);
end
local resource_tab = {}
for i=1,#querysql_res do
  local resource_res = {}
  resource_res.id=querysql_res[i]["id"]
  resource_res.rating_id=querysql_res[i]["rating_id"]
  resource_res.rating_title=querysql_res[i]["rating_title"]
  resource_res.rating_sub_title=querysql_res[i]["rating_sub_title"]
  resource_res.resource_info_id=querysql_res[i]["resource_info_id"]
  resource_res.resource_memo=querysql_res[i]["resource_memo"]
  resource_res.person_id=querysql_res[i]["person_id"]
  resource_res.person_name=querysql_res[i]["person_name"]
  resource_res.bureau_id=querysql_res[i]["bureau_id"]
  resource_res.bureau_name=querysql_res[i]["bureau_name"]
  resource_res.stage_id=querysql_res[i]["stage_id"]
  resource_res.subject_id=querysql_res[i]["subject_id"]
  resource_res.ts=querysql_res[i]["ts"]
  resource_res.view_count=querysql_res[i]["view_count"]
  resource_res.vote_count=querysql_res[i]["vote_count"]
  resource_res.scorce=querysql_res[i]["scorce"]
  resource_res.expert_rec=querysql_res[i]["expert_rec"]
  resource_res.award_id=querysql_res[i]["award_id"]
  resource_res.resource_status=querysql_res[i]["resource_status"]
  resource_res.scheme_id=querysql_res[i]["scheme_id"]
  resource_res.sructure_id=querysql_res[i]["sructure_id"]
  resource_res.structure_id=querysql_res[i]["structure_id"]
  resource_res.israting=querysql_res[i]["israting"]
  resource_res.remark=querysql_res[i]["remark"]
  resource_res.wk_type=querysql_res[i]["wk_type"]
  resource_res.w_type=querysql_res[i]["w_type"]

  -----------------------------------微课大赛视频信息
  res_info = redis_db:hmget("wkds_"..querysql_res[i]["resource_info_id"],"wkds_id_int","wkds_id_char","scheme_id","structure_id","wkds_name","study_instr","teacher_name","play_count","score_count","create_time","download_count","downloadable","person_id","table_pk","group_id","content_json","wk_type","wk_type_name","type_id","uploader_id")
  resource_res["resource_info_id"] = querysql_res[i]["resource_info_id"]
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
  -----------------------------------微课大赛视频信息






  resource_tab[i] = resource_res
end
local result = {}
result["list"] = resource_tab
result["totalRow"] = totalRow
result["totalPage"] = totalPage
result["pageNumber"] = pageNumber
result["pageSize"] = pageSize
result["success"] = true

db:set_keepalive(0,v_pool_size)
redis_db:set_keepalive(0,v_pool_size)
ssdb:set_keepalive(0,v_pool_size)
cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))
ngx.log(ngx.ERR, "**********东师理想微课大赛*****查询列表结束**********");
