--获取分校和组织的接口 by huyue 2015-07-17

local args = getParams();

--引用模块
local cjson = require "cjson"


if args["org_id"] == nil or args["org_id"] == "" then
	--org_id = tostring(ngx.var.cookie_background_bureau_id);
	 ngx.say("{\"success\":false,\"info\":\"org_id参数错误！\"}")
	return
else
  org_id = args["org_id"]

end

local org_id_arr=Split(org_id,",");
local orgService = require "base.organization.services.OrgService";
local result={};
local res={};
local m=1;
for index=1,#org_id_arr do
	local check_res = orgService:checkHaveBranchSchool(org_id_arr[index]);
	if check_res then	
		local branch_school_res = orgService:getBranchSchoolAndOrg(org_id_arr[index]);		
		for j=1,#branch_school_res do
			local orgTab = {};
			orgTab["id"]=branch_school_res[j]["id"];	
			orgTab["name"]=branch_school_res[j]["name"];
			orgTab["pId"] = branch_school_res[j]["pId"];
			orgTab["open"] = true;
			res[m]=orgTab;
			m=m+1;
		end
		
	end
end
	result.success=true;
	result.table_List=res;

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))