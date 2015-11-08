--获取上级单位  by huyue 2015-08-25
local args = getParams();

--引用模块
local cjson = require "cjson"

local org_id=args["org_id"]

if args["org_id"] == nil or args["org_id"] == "" then
  ngx.say("{\"success\":false,\"info\":\"org_id参数错误！\"}")
  return;
end
local orgService = require "base.organization.services.OrgService";

local result  = orgService: getSupOrgByOrgId(org_id);

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))