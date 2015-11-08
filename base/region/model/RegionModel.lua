--[[
    #申健   2015-04-18
    #描述： 统计信息数据的Model类
]]

local _RegionModel = {};

--------------------------------------------------------------------------------------------
--[[
	局部函数：向组织机构（省、市、区）-下级单位统计表中插入数据
	作者：    申健 	        2015-04-18
	参数1：   recordTable  	装载数据对象的table
	返回值1： SQL语句
]]
local function getCityByProvince(self, provinceId)
	
    local DBUtil = require "common.DBUtil";
    local db     = DBUtil: getDb();
    
    local sql = "SELECT ID, CITYNAME FROM T_GOV_CITY WHERE PROVINCEID=" .. provinceId;
    local queryResult, err, errno, sqlstate = db: query(sql);
    
    if not queryResult or queryResult == nil then
		ngx.log(ngx.ERR, "===> sql语句执行出错：[err]-> [", err, "], [errno]-> [", errno, "], [sqlstate]->[", sqlstate, "]");
		return false, nil;
	end
    
    local resultTable = {};
    for index = 1, #queryResult do
        local record = {};
        record["city_id"]   = queryResult[index]["ID"]
        record["city_name"] = queryResult[index]["CITYNAME"]
        
        table.insert(resultTable, record);
    end
    return true, resultTable;
end

_RegionModel.getCityByProvince = getCityByProvince;

--------------------------------------------------------------------------------------------
return _RegionModel;