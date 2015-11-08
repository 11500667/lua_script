--[[
	局部函数：区信息基础接口
]]
local _DistrictModel = {};

---------------------------------------------------------------------------
--[[
	局部函数： 根据区的ID获取区的信息
	参数：	 districtId	 区ID
	返回：	 存储单个区信息的Table对象
]]
local function getById(self, districtId)

	local DBUtil = require "common.DBUtil";
    local sql = "SELECT ID, DISTRICTNAME, 3 AS ORGA_TYPE, CITYID AS PID FROM T_GOV_DISTRICT WHERE ID=" .. districtId;
    local queryResult = DBUtil: querySingleSql(sql);

	if not queryResult then
		return false;
	end
    return queryResult[1];
end

_DistrictModel.getById = getById;

---------------------------------------------------------------------------
--[[
    局部函数： 根据区的ID获取区的信息
    参数：  districtId  区ID
    返回：  存储单个区信息的Table对象
]]
local function getByIdFromCache(self, districtId)

    local CacheUtil = require "common.CacheUtil";
    local result = CacheUtil: hmget("t_gov_district_" .. districtId, "id", "district_name", "org_type");
    if not result then
        return false;
    end

    if result == ngx.null then
        ngx.log(ngx.ERR, "[sj_log]->[district_model]->从数据库中查询区的信息，区ID：[", districtId, "]");
        local result = {};
        local DBUtil = require "common.DBUtil";
        local sql = "SELECT ID, DISTRICTNAME, 3 AS ORGA_TYPE, CITYID AS PID FROM T_GOV_DISTRICT WHERE ID=" .. districtId;
        local queryResult = DBUtil: querySingleSql(sql);

        if not queryResult then
            return false;
        end
        
        result["id"]           = queryResult[1]["ID"];
        result["distrct_name"] = queryResult[1]["DISTRICTNAME"];
        result["org_type"]     = queryResult[1]["ORGA_TYPE"];

        CacheUtil: hmset("t_gov_district_" .. districtId, 
            "id"            , tostring(queryResult[1]["ID"]), 
            "district_name" , tostring(queryResult[1]["DISTRICTNAME"]),
            "org_type"      , tostring(queryResult[1]["ORGA_TYPE"])
        );
    end

    return result;
end

_DistrictModel.getByIdFromCache = getByIdFromCache;

---------------------------------------------------------------------------
--[[
	局部函数： 获取市下的所有区
	参数：	 cityId 	 	市ID
	返回：	 存储市下所有区的信息的Table对象
]]
local function getByCityId(self, cityId)

	local DBUtil = require "common.DBUtil";
    local sql = "SELECT ID, DISTRICTNAME, 3 AS ORGA_TYPE, CITYID AS PID FROM T_GOV_DISTRICT WHERE CITYID=" .. cityId;
    local queryResult = DBUtil: querySingleSql(sql);

	if not queryResult then
		return false;
	end
    return queryResult;
end

_DistrictModel.getByCityId = getByCityId;
---------------------------------------------------------------------------

return _DistrictModel;