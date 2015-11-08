--获取组织关系 by huyue 2015-09-08
--获取上级单位  by huyue 2015-08-25
local args = getParams();

--引用模块
local cjson = require "cjson"

local org_id=args["org_id"]

local orgService = require "base.organization.services.OrgService";

local result  = orgService: getOrgRelation(org_id);

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))