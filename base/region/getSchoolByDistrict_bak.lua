#ngx.header.content_type = "text/plain;charset=utf-8"
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["district_id"] == nil or args["district_id"]=="" then
	ngx.say("{\"success\":\"false\",\"info\":\"参数district_id不能为空！\"}");
	return;
elseif not tonumber(args["district_id"]) then
	ngx.say("{\"success\":\"false\",\"info\":\"参数district_id只能为数字！\"}");
	return;
elseif args["stage_id"]==nil or args["stage_id"]=="" then
	ngx.say("{\"success\":\"false\",\"info\":\"参数stage_id不能为空！\"}");
	return;
elseif not tonumber(args["stage_id"]) then
	ngx.say("{\"success\":\"false\",\"info\":\"参数stage_id只能为数字！\"}");
	return;
end

local districtId = args["district_id"];
-- 学校类型：0全部，1小学，2初中，3高中
local stageId = args["stage_id"];

if not tonumber(stageId) then
	ngx.say("{\"success\":\"false\",\"info\":\"参数stage_id只能为数字！\"}");
	return;
end

local stageIdNum = tonumber(stageId);
if not (stageIdNum == 0 or stageIdNum == 4 or stageIdNum == 5 or stageIdNum == 6) then
	ngx.say("{\"success\":\"false\",\"info\":\"参数stage_id不合法！\"}");
	return;
end

-- 获取数据库连接
local mysql = require "resty.mysql";
local db, err = mysql : new();
if not db then 
	ngx.log(ngx.ERR, err);
	return;
end

db:set_timeout(1000) -- 1 sec

local ok, err, errno, sqlstate = db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024 * 1024 }

if not ok then
    ngx.say("failed to connect: ", err, ": ", errno, " ", sqlstate);
	ngx.log(ngx.ERR, "=====> 连接数据库失败!");
    return;
end


local sql = "SELECT T1.ORG_ID, T1.ORG_NAME, T2.STAGE_ID FROM T_BASE_ORGANIZATION T1 INNER JOIN T_BASE_ORG_STAGE T2 ON T1.ORG_ID=T2.ORG_ID WHERE T1.DISTRICT_ID=" .. districtId .. " AND T1.ORG_TYPE=2 AND T1.EDU_TYPE=1";


if stageIdNum ~= 0  then
	sql = sql .. " AND T2.STAGE_ID=" .. tostring(stageIdNum);
end

ngx.log(ngx.ERR, "===>sql===> ".. sql .. "<===sql<===");

local results, err, errno, sqlstate = db:query(sql);
if not results then
    ngx.say("{\"success\":\"false\",\"info\":\"查询过程出错！\"}");
	ngx.log(ngx.ERR, "err: ".. err);
    return
end

--[[if #results == 0 then
	ngx.say("{\"success\":\"true\",\"table_list\":[]}");
	ngx.log(ngx.ERR, "该区（县）下没有查询到区（县）");
    return
end]]

local responseObj = {};
local recordsCollect = {};

for i=1, #results do
	local temp_schoolId = results[i]["ORG_ID"];
	local temp_schoolName = results[i]["ORG_NAME"];
	local temp_stageId = results[i]["STAGE_ID"];
	
	local record = {};
	record.school_id = temp_schoolId;
	record.school_name = temp_schoolName;
	record.stage_id = temp_stageId;
	
	table.insert(recordsCollect, record);
end

responseObj.success = true;
responseObj.table_list = recordsCollect;

-- 将table对象转换成json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(responseObj);

-- 输出json串到页面
ngx.say(responseJson);

-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end







