local cjson = require "cjson"
local _DBUtil = require "common.DBUtil";
local sql = "select id,provincename from t_gov_province where id not in (100032,100033,100034)"
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

result["success"] = true
cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))
