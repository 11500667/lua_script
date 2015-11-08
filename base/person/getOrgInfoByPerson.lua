#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#申健 2015-03-07
#描述：获取用户所在的机构信息
]]

-- 1.获取参数
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["person_id"] == nil or args["person_id"]=="" then
    ngx.say("{\"success\":false,\"info\":\"参数person_id不能为空！\"}");
    return;
elseif args["identity_id"] == nil or args["identity_id"]=="" then
    ngx.say("{\"success\":false,\"info\":\"参数identity_id不能为空！\"}");
    return;
elseif args["type"] == nil or args["type"]=="" then 
    ngx.say("{\"success\":false,\"info\":\"参数type不能为空！\"}");
    return;
end

local personId   = tostring(args["person_id"]);
local identityId = tostring(args["identity_id"]);
-- typeId : 0获取所有，1获取所在省，2获取所在市, 3获取所在区，4获取所在学校， 5获取所在部门
local typeId     = tonumber(args["type"]);

--[[
	局部函数：获取数据库连接
]]
function getDb()
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
		ngx.print("{\"success\":false,\"info\":\"查询数据失败！\"}")
		ngx.log(ngx.ERR, "=====> 连接数据库失败!");
		return false;
	end
	
	return db;
end

--[[
	局部函数：获取redis连接
]]
local function getCache()
	-- 获取redis链接
	local redis   = require "resty.redis"
	local cache   = redis:new()
	local ok, err = cache:connect(v_redis_ip,v_redis_port)
	if not ok then
		ngx.print("{\"success\":false,\"info\":\""..err.."\"}")
		return false;
	end
	
	return cache;
end

local db = getDb();
if not db then
	return;
end;

local cache = getCache();
if not cache then
	return;
end


local sql = "";

local provinceId 	= "-1";
local provinceName 	= "-1";
local cityId 		= "-1";
local cityName 		= "-1";
local districtId 	= "-1";
local districtName 	= "-1";
local schoolId 		= "-1";
local schoolName 	= "-1";
local orgId 		= "-1";
local orgName	 	= "-1";

if typeId == 0 then -- 全部
	local sql = "SELECT PERSON.PERSON_ID, PERSON.IDENTITY_ID, PERSON.PERSON_NAME, "..
				"PROVINCE.ID AS PROVINCE_ID, PROVINCE.PROVINCENAME AS PROVINCE_NAME, "..
				"CITY.ID AS CITY_ID, CITY.CITYNAME AS CITY_NAME, "..
				"DISTRICT.ID AS DISTRICT_ID, DISTRICT.DISTRICTNAME AS DISTRICT_NAME, "..
				"SCHOOL.ORG_ID AS SCHOOL_ID, SCHOOL.ORG_NAME AS SCHOOL_NAME, "..
				"ORG.ORG_ID, ORG.ORG_NAME "..
				"FROM T_BASE_PERSON PERSON "..
				"INNER JOIN T_GOV_PROVINCE PROVINCE ON PERSON.PROVINCE_ID=PROVINCE.ID "..
				"INNER JOIN T_GOV_CITY CITY ON PERSON.CITY_ID=CITY.ID "..
				"INNER JOIN T_GOV_DISTRICT DISTRICT ON PERSON.DISTRICT_ID=DISTRICT.ID "..
				"INNER JOIN T_BASE_ORGANIZATION SCHOOL ON PERSON.BUREAU_ID=SCHOOL.ORG_ID "..
				"INNER JOIN T_BASE_ORGANIZATION ORG ON PERSON.ORG_ID=ORG.ORG_ID "..
				"WHERE PERSON.PERSON_ID=" ..  personId .. " AND PERSON.IDENTITY_ID=".. identityId;
	ngx.log(ngx.ERR, " ===> sql语句 ===> ", sql);
	local cjson = require "cjson";
	local res, err, errno, sqlstate = db:query(sql);
	ngx.log(ngx.ERR, " ===> res 的json ===> ", cjson.encode(res));
	provinceId 	 = res[1]["PROVINCE_ID"];
	provinceName = res[1]["PROVINCE_NAME"];
	cityId 		 = res[1]["CITY_ID"];
	cityName 	 = res[1]["CITY_NAME"];
	districtId 	 = res[1]["DISTRICT_ID"];
	districtName = res[1]["DISTRICT_NAME"];
	schoolId 	 = res[1]["SCHOOL_ID"];
	schoolName 	 = res[1]["SCHOOL_NAME"];
	orgId 		 = res[1]["ORG_ID"];
	orgName	 	 = res[1]["ORG_NAME"];
	
elseif typeId == 1 then -- 省
	
	provinceId = cache:hget("person_" .. personId .. "_" .. identityId, "sheng");
	sql = "SELECT PROVINCENAME FROM T_GOV_PROVINCE WHERE ID=".. provinceId;
	local res, err, errno, sqlstate = db:query(sql);
	provinceName = res[1]["PROVINCENAME"];
	
elseif typeId == 2 then -- 市
	
	cityId = cache:hget("person_" .. personId .. "_" .. identityId, "shi");
	sql = "SELECT CITYNAME FROM T_GOV_CITY WHERE ID=".. cityId;
	local res, err, errno, sqlstate = db:query(sql);
	cityName = res[1]["CITYNAME"];
	
elseif typeId == 3 then -- 区
	
	districtId = cache:hget("person_" .. personId .. "_" .. identityId, "qu");
	sql = "SELECT DISTRICTNAME FROM T_GOV_DISTRICT WHERE ID=".. districtId;
	local res, err, errno, sqlstate = db:query(sql);
	districtName = res[1]["DISTRICTNAME"];
	
elseif typeId == 4 then -- 校
	
	schoolId = cache:hget("person_" .. personId .. "_" .. identityId, "xiao");
	sql = "SELECT ORG_NAME FROM T_BASE_ORGANIZATION WHERE ORG_ID=".. schoolId;
	local res, err, errno, sqlstate = db:query(sql);
	schoolName = res[1]["ORG_NAME"];
	
elseif typeId == 5 then -- 部门
	
	orgId = cache:hget("person_" .. personId .. "_" .. identityId, "bm");
	sql = "SELECT ORG_NAME FROM T_BASE_ORGANIZATION WHERE ORG_ID=" .. orgId;
	local res, err, errno, sqlstate = db:query(sql);
	orgName = res[1]["ORG_NAME"];
	
end

local orgInfoObj = {};
orgInfoObj.success   	 = true; 			
orgInfoObj.province_id 	 = provinceId; 			
orgInfoObj.province_name = provinceName;	
orgInfoObj.city_id 		 = cityId;			
orgInfoObj.city_name 	 = cityName; 			
orgInfoObj.district_id 	 = districtId; 			
orgInfoObj.district_name = districtName;		
orgInfoObj.school_id 	 = schoolId;			
orgInfoObj.school_name 	 = schoolName;			
orgInfoObj.org_id 		 = orgId;				
orgInfoObj.org_name	 	 = orgName; 			

local cjson = require "cjson";
ngx.print(cjson.encode(orgInfoObj));

-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

-- 将redis连接归还到连接池
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
	ngx.log(ngx.ERR, "====>将Redis连接归还连接池出错！");
end
