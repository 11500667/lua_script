#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#申健 2015-03-08
#描述：获取指定UNIT_ID的组织机构树
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

if args["root_id"] == nil or args["root_id"]=="" then
    ngx.say("{\"success\":false,\"info\":\"参数root_id不能为空！\"}");
    return;
end

-- 根节点组织机构的ID
local rootId   = tonumber(args["root_id"]);
local unitType = nil;
local unitId   = nil;
local getRoot  = false;

local checkPerson = require "multi_check.model.CheckPerson";
local DBUtil	  = require "multi_check.model.DBUtil";

if args["id"] == nil or args["id"]=="" then -- 如果参数中的id为空，表示获取根节点
    getRoot = true;
	unitType = checkPerson: getUnitType(rootId);
else -- 如果参数中的id不为空，则获取id的下一级单位
	unitId = tonumber(args["id"]);
	unitType = checkPerson: getUnitType(unitId);
end

-- 3. 获取数据库连接
local db = DBUtil: getDb();

if not db then
    ngx.print("{\"success\":\"false\",\"info\":\"查询数据失败！\"}")
	ngx.log(ngx.ERR, "=====> 连接数据库失败!");
    return;
end

local sql = "";

if getRoot then
	if unitType == 1 then -- 查询省
		sql = "SELECT T1.ID AS UNIT_ID, T1.PROVINCENAME AS UNIT_NAME, -1 AS PARENT_ID, 1 AS UNIT_TYPE, IF(T2.ID IS NULL, 1, 0) AS IS_LEAF FROM T_GOV_PROVINCE T1  LEFT OUTER JOIN T_GOV_CITY T2 ON T1.ID=T2.PROVINCEID WHERE T1.ID=" .. rootId .. " GROUP BY T1.ID";
	elseif unitType == 2 then -- 查询市
		sql = "SELECT T1.ID AS UNIT_ID, T1.CITYNAME AS UNIT_NAME, -1 AS PARENT_ID, 2 AS UNIT_TYPE, IF(T2.ID IS NULL, 1, 0) AS IS_LEAF FROM T_GOV_CITY T1 LEFT OUTER JOIN T_GOV_DISTRICT T2 ON T1.ID=T2.CITYID WHERE T1.ID=" .. rootId .. " GROUP BY T1.ID";
	elseif unitType == 3 then -- 查询区
		sql = "SELECT T1.ID AS UNIT_ID, T1.DISTRICTNAME AS UNIT_NAME, -1 AS PARENT_ID, 3 AS UNIT_TYPE, IF(T2.ORG_ID IS NULL, 1, 0) AS IS_LEAF FROM T_GOV_DISTRICT T1 LEFT OUTER JOIN T_BASE_ORGANIZATION T2 ON T1.ID=T2.DISTRICT_ID WHERE  T1.ID=" .. rootId .. " GROUP BY T1.ID";
	elseif unitType == 4 then -- 查询学校
		sql = "SELECT ORG_ID AS UNIT_ID, ORG_NAME AS UNIT_NAME, -1 AS PARENT_ID, 4 AS UNIT_TYPE, 1 AS IS_LEAF FROM T_BASE_ORGANIZATION WHERE ORG_TYPE IN (1,2) AND ORG_ID=" .. rootId;
	elseif unitType == 5 then -- 查询分校
		sql = "SELECT ORG_ID AS UNIT_ID, ORG_NAME AS UNIT_NAME, -1 AS PARENT_ID, 5 AS UNIT_TYPE, 1 AS IS_LEAF FROM T_BASE_ORGANIZATION WHERE ORG_TYPE=3 AND ORG_ID=" .. rootId;
	end
else
	if unitType == 1 then -- 查询省下面的市
		
		sql = "SELECT T1.ID AS UNIT_ID, CITYNAME AS UNIT_NAME, PROVINCEID AS PARENT_ID, 2 AS UNIT_TYPE, IF(T2.ID IS NULL, 1, 0) AS IS_LEAF FROM T_GOV_CITY T1 LEFT OUTER JOIN T_GOV_DISTRICT T2 ON T1.ID=T2.CITYID WHERE  T1.PROVINCEID=" .. unitId .. " GROUP BY T1.ID ";
	elseif unitType == 2 then -- 查询市下面的区（县）
	
		sql = "SELECT T1.ID AS UNIT_ID, T1.DISTRICTNAME AS UNIT_NAME, T1.CITYID AS PARENT_ID, 3 AS UNIT_TYPE, IF(T2.ORG_ID IS NULL, 1, 0) AS IS_LEAF FROM T_GOV_DISTRICT T1 LEFT OUTER JOIN T_BASE_ORGANIZATION T2 ON T1.ID=T2.DISTRICT_ID AND T2.ORG_TYPE IN (1,2) WHERE T1.CITYID=" .. unitId .." GROUP BY T1.ID ";
		
	elseif unitType == 3 then -- 查询区下面的学校和教育局
	
		sql = "SELECT ORG_ID AS UNIT_ID, ORG_NAME AS UNIT_NAME, DISTRICT_ID AS PARENT_ID, 4 AS UNIT_TYPE, 1 AS IS_LEAF FROM T_BASE_ORGANIZATION WHERE ORG_TYPE IN (1,2) AND DISTRICT_ID=" .. unitId .. " AND ORG_ID<>" .. unitId;
		
	elseif unitType == 4 then -- 查询学校（教育局）下的部门
	
		sql = "SELECT ORG_ID AS UNIT_ID, ORG_NAME AS UNIT_NAME, PARENT_ID, 5 AS UNIT_TYPE FROM T_BASE_ORGANIZATION WHERE ORG_TYPE=3 AND PARENT_ID=" .. unitId;
		
	end
end

ngx.log(ngx.ERR, "===> 获取组织机构的sql语句： ===> ", sql );

local result, err, errno, sqlstate = db: query(sql);
if not result then
	ngx.print("{\"success\":\"false\",\"info\":\"获取编号为" .. ((unitId==nil and rootId) or unitId) .. "的子节点失败！\"}");
	ngx.log(ngx.ERR, "===> 错误信息 ===>");
	ngx.exit(ngx.HTTP_OK);
end

local listObj = {}

for i=1, #result do
	local unitObj = result[i];
	local tempUnitId   = unitObj["UNIT_ID"];
	local tempUnitName = unitObj["UNIT_NAME"];
	local tempParentId = unitObj["PARENT_ID"];
	local tempUnitType = unitObj["UNIT_TYPE"];
	local tempIsLeaf   = unitObj["IS_LEAF"];
	
	local listItem = {};
	listItem.id    	   = tempUnitId;
	listItem.name 	   = tempUnitName;
	listItem.unit_type = tempUnitType;
	listItem.pId 	   = tempParentId;
	-- ngx.log(ngx.ERR, "===> tempUnitType == 5 ===>", type(tempUnitType))
	if tempUnitType == "4" then
		listItem.isParent = false;
	elseif tempIsLeaf ~=nil and tempIsLeaf==1 then
		listItem.isParent = false;
	else
		listItem.isParent = true;
	end
	
	table.insert(listObj, listItem);
end

local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
-- local responseObj = {};
-- responseObj.success = true;
-- responseObj.list    = listObj;
local responseStr = cjson.encode(listObj);
ngx.print(responseStr);

-- 将mysql连接归还到连接池
DBUtil: keepDbAlive(db);



