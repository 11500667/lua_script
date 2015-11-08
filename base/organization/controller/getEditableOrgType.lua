--获取可以编辑的单位类型 by huyue 2015-09-11

--引用模块
local cjson = require "cjson"

local orgService = require "base.organization.services.OrgService";
  
local result  = orgService:getEditableOrgType();

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))