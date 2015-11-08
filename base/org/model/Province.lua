--[[
	申健	2015-04-22
	局部函数：人员信息基础接口
]]
local _ProvinceModel = {};

--[[
	局部函数： 根据区的ID获取省的信息
	参数：	 provinceId	 省ID
	返回：	 存储单个省信息的Table对象
]]
local function getById(self, provinceId)

	local DBUtil = require "common.DBUtil";
    local sql = "SELECT ID, PROVINCENAME, 1 AS ORGA_TYPE FROM T_GOV_PROVINCE WHERE ID=" .. provinceId;
    local queryResult = DBUtil: querySingleSql(sql);

	if not queryResult then
		return false;
	end
    return queryResult[1];
end

_ProvinceModel.getById = getById;

---------------------------------------------------------------------------
--[[
    局部函数： 根据区的ID获取省的信息
    参数：  provinceId  省ID
    返回：  存储单个省信息的Table对象
]]
local function getByIdFromCache(self, provinceId)

    local CacheUtil = require "common.CacheUtil";
    local result = CacheUtil: hmget("t_gov_province_" .. provinceId, "id", "province_name", "org_type");
    if not result then
        return false;
    end

    if result == ngx.null then
        ngx.log(ngx.ERR, "[sj_log]->[district_model]->从数据库中查询省的信息，省的ID：[", provinceId, "]");
        local result = {};
        local DBUtil = require "common.DBUtil";
        local sql = "SELECT ID, PROVINCENAME, 1 AS ORGA_TYPE FROM T_GOV_PROVINCE WHERE ID=" .. provinceId;
        local queryResult = DBUtil: querySingleSql(sql);

        if not queryResult then
            return false;
        end
        
        result["id"]            = queryResult[1]["ID"];
        result["province_name"] = queryResult[1]["PROVINCENAME"];
        result["org_type"]      = queryResult[1]["ORGA_TYPE"];
        
        CacheUtil: hmset("t_gov_province_" .. provinceId, 
            "id"            , tostring(queryResult[1]["ID"]), 
            "province_name" , tostring(queryResult[1]["PROVINCENAME"]),
            "org_type"      , tostring(queryResult[1]["ORGA_TYPE"])
        );
    end

    return result;
end

_ProvinceModel.getByIdFromCache = getByIdFromCache;

---------------------------------------------------------------------------
--[[
	局部函数： 获取所有省的信息
	返回：	 存储所有省信息的Table对象
]]
local function getAllProvince(self)

	local DBUtil = require "common.DBUtil";
    local sql = "SELECT ID, PROVINCENAME, 1 AS ORGA_TYPE, -1 AS PID FROM T_GOV_PROVINCE";
    local queryResult = DBUtil: querySingleSql(sql);

	if not queryResult then
		return false;
	end
    return queryResult;
end

_ProvinceModel.getAllProvince = getAllProvince;
---------------------------------------------------------------------------


----------------------------------------------------------------------------------
--[[
@author JX
param  null
mothod 获取省函数
]]
local function getProvinceList()
  local _DBUtil = require "common.DBUtil";
  local sql = "select id,provincename from t_gov_province"
  local querysql_res = _DBUtil:querySingleSql(sql)
  local result = {}
  local returnjsonlist = {}
  for i=1,#querysql_res do
    local resList = {}
    resList.id=querysql_res[i]["id"]
    resList.provincename=querysql_res[i]["provincename"]
    returnjsonlist[i] = resList
  end
  result["list"] = returnjsonlist
  return result;
end
_ProvinceModel.getProvinceList = getProvinceList;
----------------------------------------------------------------------------------




return _ProvinceModel;