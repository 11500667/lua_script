--级联获取组织 by huyue 2015-08-25
local args = getParams();

--引用模块
local cjson = require "cjson"

local org_id=args["org_id"]

local org_type=args["org_type"]

local orgService = require "base.organization.services.OrgService";

local result  = orgService: getHierarchyChildrenOrgs(org_id,org_type);

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))