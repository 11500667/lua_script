#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#申健 2014-11-30
#描述：根据用户输入的关键字查询用户
]]

local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["query_key"] == nil or args["query_key"]=="" then
	ngx.say("{\"success\":\"false\",\"info\":\"参数query_key不能为空！\"}");
	return;
elseif args["pageNumber"] == nil or args["pageNumber"]=="" then
	ngx.say("{\"success\":\"false\",\"info\":\"参数pageNumber不能为空！\"}");
	return;
elseif not tonumber(args["pageNumber"]) then
	ngx.say("{\"success\":\"false\",\"info\":\"参数pageNumber不合法！\"}");
	return;
elseif args["pageSize"] == nil or args["pageSize"]=="" then
	ngx.say("{\"success\":\"false\",\"info\":\"参数pageSize不能为空！\"}");
	return;
elseif not tonumber(args["pageSize"]) then
	ngx.say("{\"success\":\"false\",\"info\":\"参数pageSize不合法！\"}");
	return;
end

local queryKey = tostring(args["query_key"]);

--第几页
local pageNumber = tostring(args["pageNumber"]);
--判断是否有第几页的参数
if pageNumber == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"参数错误！\"}")    
    return
end
if pageNumber == "0" then
    pageNumber = "1"
end

--一页显示多少
local pageSize = tostring(args["pageSize"])
--判断是否有一页显示多少条的参数
if pageSize == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"参数错误！\"}")    
    return
end

local offset = pageSize*pageNumber-pageSize
local limit = pageSize

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
    ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}")
	ngx.log(ngx.ERR, "=====> 连接数据库失败!");
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

local sql = "SELECT T1.LOGIN_NAME, T2.PERSON_NAME, T2.PERSON_ID, PROVINCE.PROVINCENAME, T2.PROVINCE_ID, "..
			   "CITY.CITYNAME, T2.CITY_ID, DISTRICT.DISTRICTNAME, T2.DISTRICT_ID, BUREAU.ORG_NAME BUREAU_NAME, T2.BUREAU_ID, "..
			   "ORG.ORG_NAME, T2.ORG_ID "..
			"FROM T_BASE_PERSON T2 "..
			"INNER JOIN T_SYS_LOGINPERSON T1 ON T1.PERSON_ID=T2.PERSON_ID AND T1.IDENTITY_ID=T2.IDENTITY_ID "..
			"LEFT OUTER JOIN T_BASE_ORGANIZATION ORG ON T2.ORG_ID=ORG.ORG_ID "..
			"LEFT OUTER JOIN T_BASE_ORGANIZATION BUREAU ON T2.BUREAU_ID=BUREAU.ORG_ID "..
			"LEFT OUTER JOIN T_GOV_PROVINCE PROVINCE ON T2.PROVINCE_ID=PROVINCE.ID "..
			"LEFT OUTER JOIN T_GOV_CITY CITY ON T2.CITY_ID=CITY.ID "..
			"LEFT OUTER JOIN T_GOV_DISTRICT DISTRICT ON T2.DISTRICT_ID=DISTRICT.ID "..
			"WHERE T2.B_USE=1 AND T2.IDENTITY_ID=5 AND T2.PERSON_NAME LIKE '%".. queryKey .."%' LIMIT "..offset..", "..limit..";" .. 
			"SELECT COUNT(1) AS RESULT_COUNT FROM T_BASE_PERSON T1 INNER JOIN T_SYS_LOGINPERSON T2 ON T1.PERSON_ID=T2.PERSON_ID AND T1.IDENTITY_ID=T2.IDENTITY_ID WHERE T1.B_USE=1 AND T1.IDENTITY_ID=5 AND T1.PERSON_NAME LIKE '%".. queryKey .."%'";

ngx.log(ngx.ERR, "===sql===> " .. sql .. " <===sql===");			

local results, err, errno, sqlstate = db:query(sql);
if not results then
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}");
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    return;
end

--UFT_CODE
local function urlencode(str)
    if (str) then
        str = string.gsub (str, "\n", "\r\n")
        str = string.gsub (str, "([^%w ])",
        function (c) return string.format ("%%%%%02X", string.byte(c)) end)
        --str = string.gsub (str, " ", " ")
    end
    return str
end

--去第二个结果集中的Status中截取总个数
local res1 = db:read_result()
local totalRow = res1[1]["RESULT_COUNT"]
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)


local responseObj = {};
local recordsCollect = {};

for i=1, #results do

	local record = results[i];

	--[[
	local person_name = record.PERSON_NAME;
	local person_id = record.PERSON_ID;	
	local login_name = record.LOGIN_NAME;
	local bureau_id = record.BUREAU_ID;
	local bureau_name = record.BUREAU_NAME;
	local org_id = record.ORG_ID;
	local org_name = record.ORG_NAME;
	local province_id = record.PROVINCE_ID;
	local province_name = record.PROVINCENAME;
	local city_id = record.CITY_ID;
	local city_name = record.CITYNAME;
	local district_id = record.DISTRICT_ID;
	local district_name = record.DISTRICTNAME;]]

	local recordJson = {};
	recordJson.person_name = record.PERSON_NAME;
	recordJson.person_id = record.PERSON_ID;	
	recordJson.login_name = record.LOGIN_NAME;
	recordJson.bureau_id = record.BUREAU_ID;
	recordJson.bureau_name = record.BUREAU_NAME;
	recordJson.org_id = record.ORG_ID;
	recordJson.org_name = record.ORG_NAME;
	recordJson.province_id = record.PROVINCE_ID;
	recordJson.province_name = record.PROVINCENAME;
	recordJson.city_id = record.CITY_ID;
	recordJson.city_name = record.CITYNAME;
	recordJson.district_id = record.DISTRICT_ID;
	recordJson.district_name = record.DISTRICTNAME;
	
	table.insert(recordsCollect, recordJson);
end

responseObj.list = recordsCollect;
responseObj.totalRow = totalRow;
responseObj.totalPage = totalPage;
responseObj.pageNumber = pageNumber;
responseObj.pageSize = pageSize;
responseObj.success = true;

-- 将table对象转换成json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(responseObj);

-- 输出json串到页面
ngx.say(responseJson);

-- 将redis连接归还到连接池
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
	ngx.log(ngx.ERR, "====>将Redis连接归还连接池出错！");
end

-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end







