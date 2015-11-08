#获取大赛获奖者名单 by huyue 2015-06-12
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


ngx.log(ngx.ERR, args["stage_id"] == tostring(-1));
ngx.log(ngx.ERR, type(args["stage_id"]));

--学段ID
local stage_str
if args["stage_id"] == nil or args["stage_id"] == "" or args["stage_id"] == tostring(-1) then
	stage_str = ""
else
	stage_str = " AND tre.stage_id="..tostring(args["stage_id"])   
end


--学科ID
local subject_str
if args["subject_id"] == nil or args["subject_id"] == "" or args["subject_id"] == tostring(-1) then
	subject_str = ""
else
  subject_str = " AND tre.subject_id="..tostring(args["subject_id"])
end

--奖项
local award_str
if args["award_id"] == nil or args["award_id"] == "" or args["award_id"] == tostring(-1) then
	award_str = ""
else
  award_str = " AND tre.award_id="..tostring(args["award_id"])
end

--第几页
if args["pageNumber"] == nil or args["pageNumber"] == ""  then
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

--一页显示多少
if args["rating_type"] == nil or args["rating_type"] == "" then
  ngx.say("{\"success\":\"false\",\"info\":\"rating_type参数错误！\"}")
  return
end
local rating_type = args["rating_type"]

local w_type
if args["w_type"] == nil or args["w_type"] == "" then
  w_type = ""
else
  w_type = " AND tre.w_type="..args["w_type"]
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
local wherequery = "where twi.ID=tre.RESOURCE_INFO_ID and tre.rating_id = tri.id and tre.award_id in(1,2,3,4) and tre.rating_id="..rating_id.."  AND tre.stage_id=tds.stage_id AND tre.subject_id=tdj.subject_id and  tri. rating_type="..rating_type..""..stage_str..subject_str..award_str..w_type.." order by tre.stage_id,tre.award_id "
local querycount = "select count(*) as count  from t_rating_resource tre ,t_rating_info tri,t_wkds_info twi,t_dm_stage tds, t_dm_subject tdj "..wherequery
ngx.log(ngx.ERR,querycount)
local count1 = mysql_db:query(querycount)
local offset = pageSize*pageNumber-pageSize
local limit = pageSize
local totalRow = count1[1]["count"]
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

local querysql = "select tre.id,tre.stage_id,tre.subject_id,twi.wkds_id_int,tre.person_id,tre.person_name,tre.award_id,tre.resource_memo,tre.bureau_name,tre.rating_title,twi.wkds_name,twi.id as resource_info_id,tds.stage_name,tdj.subject_name  from t_rating_resource tre ,t_rating_info tri,t_wkds_info twi,t_dm_stage tds, t_dm_subject tdj  "..wherequery.." LIMIT "..offset..","..limit..";"
local winner_list = mysql_db:query(querysql)

ngx.log(ngx.ERR,querysql)
local winner_tab = {}
local result = {}
local title = ""
if winner_list[1] ~= nil then
  for i=1,#winner_list do
    local winner_res = {}
    winner_res["person_name"] = winner_list[i]["person_name"]
    winner_res["person_id"] = winner_list[i]["person_id"]
    winner_res["award_id"] = winner_list[i]["award_id"]
    winner_res["resource_memo"] =  winner_list[i]["resource_memo"]
    winner_res["bureau_name"] =  winner_list[i]["bureau_name"]
	title =  winner_list[i]["rating_title"]
	winner_res["wkds_id_int"] =  winner_list[i]["wkds_id_int"]
	winner_res["stage_id"] =  winner_list[i]["stage_id"]
	winner_res["subject_id"] =  winner_list[i]["subject_id"]
	winner_res["award_id"] =  winner_list[i]["award_id"]
	winner_res["wkds_name"] =  winner_list[i]["wkds_name"]
	winner_res["id"] =  winner_list[i]["id"]
	winner_res["resource_info_id"] =  winner_list[i]["resource_info_id"]
	winner_res["stage_name"] =  winner_list[i]["stage_name"]
	winner_res["subject_name"] =  winner_list[i]["subject_name"]
    winner_tab[i] = winner_res
  end
	result["list"] = winner_tab
	result["totalRow"] = totalRow
	result["totalPage"] = totalPage
	result["pageNumber"] = pageNumber
	result["pageSize"] = pageSize
	result["rating_title"] = title
	result["success"] = true
else
	local winner_res1 = {}
	result["list"] = winner_res1
	result["totalRow"] = totalRow
	result["totalPage"] = totalPage
	result["pageNumber"] = pageNumber
	result["pageSize"] = pageSize
	result["rating_title"] = title
	result["success"] = true
  
end

mysql_db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false);

ngx.print(cjson.encode(result))



























