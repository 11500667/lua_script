--获取组织根据parent_id
local args = getParams();

--引用模块
local cjson = require "cjson"


if args["org_id"] == nil or args["org_id"] == "" then
  ngx.say("{\"success\":false,\"info\":\"org_id参数错误！\"}")
  return;
end
local org_id=args["org_id"]

local org_type=args["org_type"]

local orgService = require "base.organization.services.OrgService";

local result  = orgService: getChildrenOrgs(org_id,org_type);

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))