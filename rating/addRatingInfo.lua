local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

local cjson = require "cjson"
local myTs = require "resty.TS"

--评比名称
if args["rating_title"] == nil or args["rating_title"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"rating_title参数错误！\"}")
	return
end
local rating_title = args["rating_title"]

--评比子名称
local rating_sub_title = ""
if args["rating_sub_title"] ~= nil and args["rating_sub_title"] ~= "" then 
	rating_sub_title = args["rating_sub_title"]	
end

--开始时间
if args["start_date"] == nil or args["start_date"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"start_date参数错误！\"}")
	return
end
local start_date = args["start_date"]

--结束时间
if args["end_date"] == nil or args["end_date"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"end_date参数错误！\"}")
	return
end
local end_date = args["end_date"]

--评比介绍
local rating_memo = ""
if args["rating_memo"] ~= nil and args["rating_memo"] ~= "" then 
	rating_memo = args["rating_memo"]	
end

--主办方
local zhubanfang = ""
if args["zhubanfang"] ~= nil and args["zhubanfang"] ~= "" then 
	zhubanfang = args["zhubanfang"]	
end

--承办方
local chengbanfang = ""
if args["chengbanfang"] ~= nil and args["chengbanfang"] ~= "" then 
	chengbanfang = args["chengbanfang"]	
end

--创建该评比活动的单位id
local org_id = tostring(ngx.var.cookie_background_bureau_id)

--参赛对象
local cansaiduixiang = ""
if args["cansaiduixiang"] ~= nil and args["cansaiduixiang"] ~= "" then 
	cansaiduixiang = args["cansaiduixiang"]	
end

--评比方式 1：投票 2：量规 3：推荐
if args["rating_range"] == nil or args["rating_range"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"rating_range参数错误！\"}")
	return
end
local rating_range = args["rating_range"]

--评比投票数
local vote_count = "";
if args["vote_count"] == nil or args["vote_count"] == "" then 
	vote_count = "0"
else
	vote_count = args["vote_count"]
end


--专家人员ID
local experts = ""
if args["experts"] ~= nil and args["experts"] ~= "" then 
	experts = args["experts"]	
end

--一等奖个数
local first_prize_count = 0
if args["first_prize_count"] ~= nil and args["first_prize_count"] ~= "" then 
	first_prize_count = args["first_prize_count"]	
end

--二等奖个数
local two_prize_count = 0
if args["two_prize_count"] ~= nil and args["two_prize_count"] ~= "" then 
	two_prize_count = args["two_prize_count"]	
end

--三等奖个数
local three_prize_count = 0
if args["three_prize_count"] ~= nil and args["three_prize_count"] ~= "" then 
	three_prize_count = args["three_prize_count"]	
end

--四等奖个数
local award_winning_count = 0
if args["award_winning_count"] ~= nil and args["award_winning_count"] ~= "" then 
	award_winning_count = args["award_winning_count"]	
end

--奖项说明
local jiangxiangshuoming = ""
if args["jiangxiangshuoming"] ~= nil and args["jiangxiangshuoming"] ~= "" then 
	jiangxiangshuoming = args["jiangxiangshuoming"]	
end

--评选标准
local pingxuanbiaozhun = ""
if args["pingxuanbiaozhun"] ~= nil and args["pingxuanbiaozhun"] ~= "" then 
	pingxuanbiaozhun = args["pingxuanbiaozhun"]	
end

--资源要求
local ziyuanyaoqiu = ""
if args["ziyuanyaoqiu"] ~= nil and args["ziyuanyaoqiu"] ~= "" then 
	ziyuanyaoqiu = args["ziyuanyaoqiu"]	
end

--活动说明
local huodongshuoming = ""
if args["huodongshuoming"] ~= nil and args["huodongshuoming"] ~= "" then 
	huodongshuoming = args["huodongshuoming"]	
end

--活动附件
local houdongfujian = ""
if args["houdongfujian"] ~= nil and args["houdongfujian"] ~= "" then 
	houdongfujian = args["houdongfujian"]	
end

--评比状态    1：未开始  2：已开始  3：公示期  4：已结束
local rating_status = 1

--是否可用  1：正常，2：删除，3：彻底删除
local b_use = 1

--评比类型 1:资源大赛，2.3.4.5.6.7.8.9:微课大赛
local rating_type = "NULL"
if args["rating_type"] ~= nil and args["rating_type"] ~= "" then 
	rating_type = args["rating_type"]	
end

local ts = myTs.getTs()

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

local person_id = tostring(ngx.var.cookie_background_person_id)

local res = mysql_db:query("INSERT INTO t_rating_info (person_id,rating_title,rating_sub_title,start_date,end_date,rating_memo,zhubanfang,chengbanfang,org_id,cansaiduixiang,rating_range,first_prize_count,two_prize_count,three_prize_count,award_winning_count,jiangxiangshuoming,pingxuanbiaozhun,ziyuanyaoqiu,huodongshuoming,houdongfujian,rating_status,b_use,TS,vote_count,rating_type) VALUES ('"..person_id.."','"..rating_title.."','"..rating_sub_title.."','"..start_date.."','"..end_date.."','"..rating_memo.."','"..zhubanfang.."','"..chengbanfang.."','"..org_id.."','"..cansaiduixiang.."','"..rating_range.."','"..first_prize_count.."','"..two_prize_count.."','"..three_prize_count.."','"..award_winning_count.."','"..jiangxiangshuoming.."','"..pingxuanbiaozhun.."','"..ziyuanyaoqiu.."','"..huodongshuoming.."','"..houdongfujian.."','"..rating_status.."','"..b_use.."','"..ts.."','"..vote_count.."',"..rating_type..")")

 ngx.log(ngx.ERR,"INSERT INTO t_rating_info (person_id,rating_title,rating_sub_title,start_date,end_date,rating_memo,zhubanfang,chengbanfang,org_id,cansaiduixiang,rating_range,first_prize_count,two_prize_count,three_prize_count,award_winning_count,jiangxiangshuoming,pingxuanbiaozhun,ziyuanyaoqiu,huodongshuoming,houdongfujian,rating_status,b_use,TS,vote_count,rating_type) VALUES ('"..person_id.."','"..rating_title.."','"..rating_sub_title.."','"..start_date.."','"..end_date.."','"..rating_memo.."','"..zhubanfang.."','"..chengbanfang.."','"..org_id.."','"..cansaiduixiang.."','"..rating_range.."','"..first_prize_count.."','"..two_prize_count.."','"..three_prize_count.."','"..award_winning_count.."','"..jiangxiangshuoming.."','"..pingxuanbiaozhun.."','"..ziyuanyaoqiu.."','"..huodongshuoming.."','"..houdongfujian.."','"..rating_status.."','"..b_use.."','"..ts.."','"..vote_count.."',"..rating_type..")");

local rating_id = res.insert_id

--获取专家
if string.len(experts) ~= 0 then
	local person_ids = Split(experts,",")
	for i=1,#person_ids do
		local person_id = person_ids[i]			
			local person_info = mysql_db:query("SELECT T1.person_name,T2.bureau_id,T2.org_name AS bureau_name FROM t_base_person T1 INNER JOIN t_base_organization T2 ON T1.BUREAU_ID=T2.ORG_ID WHERE T1.PERSON_ID = "..person_id)			
			if #person_info> 0 then			
				mysql_db:query("INSERT INTO t_rating_expert (rating_id,person_id,person_name,bureau_id,bureau_name) VALUES ("..rating_id..",'"..person_id.."','"..person_info[1]["person_name"].."',"..person_info[1]["bureau_id"]..",'"..person_info[1]["bureau_name"].."')")
			end
	end
end

--放回连接池
mysql_db:set_keepalive(0,v_pool_size)

local result = {} 
result["success"] = true

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))






