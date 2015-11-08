--获取所有的组织 by huyue 2015-08-05
--[[

select  case org_id when 100001 then 'true'
                        when 100002 then 'true' 
                        else 'false'
  end as aaaa from t_base_organization

]]
--1.获得参数方法
local args = getParams();
-- 获取数据库连接
local _DBUtil = require "common.DBUtil";
local selected_role_org_id = args["selected_role_org_id"];

local query_sql="";
if selected_role_org_id == nil or selected_role_org_id == "" then
	
else
 
 local role_org_id_arr=Split(selected_role_org_id,",");
 
end


--一页显示多少
if args["pageSize"] == nil or args["pageSize"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"pageSize参数错误！\"}")
    return
end
local pageSize = args["pageSize"]

if args["pageNumber"] == nil or args["pageNumber"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"pageNumber参数错误！\"}")
    return
end
local pageNumber = args["pageNumber"]

local offset = pageSize*pageNumber-pageSize
local limit = pageSize

local query_condition = " where 1=1"
--组织名称
if args["org_name"] == nil or args["org_name"] == "" then

else 
	query_condition = query_condition.." and org_name like '%"..args["org_name"].."%'";
end

query_sql="select ORG_ID,ORG_NAME from t_base_organization"..query_condition.." LIMIT "..offset..","..limit;
ngx.log(ngx.ERR,query_sql);
local query_res = _DBUtil:querySingleSql(query_sql);

local query_count_sql="select count(1) as COUNT from t_base_organization";

local res_count =  _DBUtil:querySingleSql(query_count_sql);
local totalRow = res_count[1]["COUNT"]
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

local result = {} ;
result["table_List"] = query_res;
result["success"] = true;
result["totalRow"] = tonumber(totalRow)
result["totalPage"] = tonumber(totalPage)
result["pageNumber"] = tonumber(pageNumber)
result["pageSize"] = tonumber(pageSize)
ngx.print(encodeJson(result));
