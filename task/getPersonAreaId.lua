local args = getParams();
local _DBUtil = require "common.DBUtil";
local person_id = getCookieByName("person_id");
ngx.log(ngx.ERR,person_id);
local querySql = "SELECT DISTRICT_ID,CITY_ID,PROVINCE_ID,BUREAU_ID FROM T_BASE_PERSON ";
local whereSql = " WHERE PERSON_ID="..person_id.."";
querySql = querySql..whereSql;
ngx.log(ngx.ERR,querySql);
local query_dicitem_res = _DBUtil:querySingleSql(querySql);
local district_id = tonumber(query_dicitem_res[1]["DISTRICT_ID"]);
local city_id = tonumber(query_dicitem_res[1]["CITY_ID"]);
local province_id = tonumber(query_dicitem_res[1]["PROVINCE_ID"]);
local bureau_id = tonumber(query_dicitem_res[1]["BUREAU_ID"]);
local querySqlOrg = "SELECT ORG_TYPE,ORG_NAME FROM t_base_organization ";
local whereSqlOrg = " WHERE ORG_ID="..bureau_id.."";
querySqlOrg = querySqlOrg..whereSqlOrg;
ngx.log(ngx.ERR,querySqlOrg);
local query_org_res = _DBUtil:querySingleSql(querySqlOrg);
local org_type = query_org_res[1]["ORG_TYPE"];
local org_name = query_org_res[1]["ORG_NAME"];
local result = {};
local area_id = "";
if district_id == 0 then
	if city_id == 0 then
		area_id=province_id;
	else
		area_id=city_id;
	end
else
	area_id=district_id;
end
result.BUREAU_ID= bureau_id;
result.AREA_ID= area_id;
result.ORG_TYPE=org_type;
result.ORG_NAME=org_name;
result.success= true;
ngx.print(encodeJson(result));