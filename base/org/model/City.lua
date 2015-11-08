--[[
	申健	2015-04-22
	局部函数：市信息基础接口
]]
local _CityModel = {};

--[[
	局部函数： 根据区的ID获取市的信息
	参数：	 cityId	 市ID
	返回：	 存储单个市信息的Table对象
]]
local function getById(self, cityId)

	local DBUtil = require "common.DBUtil";
    local sql = "SELECT ID, CITYNAME, 2 AS ORGA_TYPE FROM T_GOV_CITY WHERE ID=" .. cityId;
    local queryResult = DBUtil: querySingleSql(sql);

	if not queryResult then
		return false;
	end
    return queryResult[1];
end

_CityModel.getById = getById;

---------------------------------------------------------------------------
--[[
    局部函数： 根据市的ID获取市的信息
    参数：  cityId  省ID
    返回：  存储单个省信息的Table对象
]]
local function getByIdFromCache(self, cityId)

    local CacheUtil = require "common.CacheUtil";
    local result = CacheUtil: hmget("t_gov_city_" .. cityId, "id", "city_name", "org_type");
    if not result then
        return false;
    end

    if result == ngx.null then
        ngx.log(ngx.ERR, "[sj_log]->[district_model]->从数据库中查询市的信息，市ID：[", cityId, "]");
        local result = {};
        local DBUtil = require "common.DBUtil";
        local sql = "SELECT ID, CITYNAME, 2 AS ORGA_TYPE FROM T_GOV_CITY WHERE ID=" .. cityId;
        local queryResult = DBUtil: querySingleSql(sql);
        if not queryResult then
            return false;
        end
        
        result["id"]        = queryResult[1]["ID"];
        result["city_name"] = queryResult[1]["CITYNAME"];
        result["org_type"]  = queryResult[1]["ORGA_TYPE"];

        CacheUtil: hmset("t_gov_city_" .. cityId, 
            "id"        , tostring(queryResult[1]["ID"]), 
            "city_name" , tostring(queryResult[1]["PROVINCENAME"]),
            "org_type"  , tostring(queryResult[1]["ORGA_TYPE"])
        );
    end

    return result;
end

_CityModel.getByIdFromCache = getByIdFromCache;

---------------------------------------------------------------------------
--[[
	局部函数： 获取省下的所有市
	参数：	 provinceId 	 	省ID
	返回：	 存储省下所有市信息的Table对象
]]
local function getByProvinceId(self, provinceId)

	local DBUtil = require "common.DBUtil";
    local sql = "SELECT ID, CITYNAME, 2 AS ORGA_TYPE, PROVINCEID AS PID FROM T_GOV_CITY WHERE PROVINCEID=" .. provinceId;
    local queryResult = DBUtil: querySingleSql(sql);

	if not queryResult then
		return false;
	end
    return queryResult;
end

_CityModel.getByProvinceId = getByProvinceId;
---------------------------------------------------------------------------

return _CityModel;