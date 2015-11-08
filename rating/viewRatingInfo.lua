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
	ngx.print("{\"success\":false,\"info\":\"rating_id参数错误！\"}")
	return
end
local rating_id = args["rating_id"]

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

local rating_info = mysql_db:query("SELECT rating_title,rating_sub_title,start_date,end_date,rating_memo,zhubanfang,chengbanfang,cansaiduixiang,rating_range,first_prize_count,two_prize_count,three_prize_count,award_winning_count,jiangxiangshuoming,pingxuanbiaozhun,ziyuanyaoqiu,huodongshuoming,houdongfujian,vote_count,rating_type,rating_status FROM t_rating_info WHERE id="..rating_id)

local rating_res = {}

if rating_info[1] ~= nil  then
rating_res["rating_title"] = rating_info[1]["rating_title"]
rating_res["rating_sub_title"] = rating_info[1]["rating_sub_title"]
rating_res["start_date"] = string.sub(rating_info[1]["start_date"],0,10)
rating_res["end_date"] = string.sub(rating_info[1]["end_date"],0,10)
rating_res["rating_memo"] = rating_info[1]["rating_memo"]
rating_res["zhubanfang"] = rating_info[1]["zhubanfang"]
rating_res["chengbanfang"] = rating_info[1]["chengbanfang"]
rating_res["cansaiduixiang"] = rating_info[1]["cansaiduixiang"]
rating_res["rating_range"] = rating_info[1]["rating_range"]
rating_res["first_prize_count"] = rating_info[1]["first_prize_count"]
rating_res["two_prize_count"] = rating_info[1]["two_prize_count"]
rating_res["three_prize_count"] = rating_info[1]["three_prize_count"]
rating_res["award_winning_count"] = rating_info[1]["award_winning_count"]
rating_res["jiangxiangshuoming"] = rating_info[1]["jiangxiangshuoming"]
rating_res["pingxuanbiaozhun"] = rating_info[1]["pingxuanbiaozhun"]
rating_res["ziyuanyaoqiu"] = rating_info[1]["ziyuanyaoqiu"]
rating_res["huodongshuoming"] = rating_info[1]["huodongshuoming"]
rating_res["houdongfujian"] = rating_info[1]["houdongfujian"]
rating_res["vote_count"] = rating_info[1]["vote_count"]
rating_res["rating_type"]=rating_info[1]["rating_type"]
rating_res["rating_status"]=rating_info[1]["rating_status"]

local expert_res = mysql_db:query("SELECT ifnull(GROUP_CONCAT(person_name),'无') AS expert_name FROM t_rating_expert WHERE RATING_ID = "..rating_id)
rating_res["expert_name"]=expert_res[1]["expert_name"]

rating_res["success"]=true
else
rating_res["success"]=false
rating_res["info"]="没有大赛记录"
end


mysql_db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(rating_res))

