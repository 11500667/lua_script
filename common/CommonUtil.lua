
local _CommonUtil = {};

function test()
    return "lua之间调用测试"
end

function tobool(v)
    return (v ~= nil and v ~= false)
end

----------------------------------------------------------------------------------
--[[
@author JX
param  null
mothod 获取省函数
]]
local function getProvince()
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
_CommonUtil.getProvince = getProvince;
----------------------------------------------------------------------------------
--[[
@author JX
param  province_id
mothod 查询省下面有多少个市
]]












----------------------------------------------------------------------------------











-- 返回DBUtil对象
return _CommonUtil;
