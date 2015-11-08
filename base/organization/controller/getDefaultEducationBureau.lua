--获取默认的教育局 by huyue 2015-09-11
local args = getParams();
--引用模块
local cjson = require "cjson"

--国标码
local area_id = args["area_id"];
if area_id == nil or area_id == "" then
	ngx.say("{\"success\":false,\"info\":\"area_id参数错误！\"}");
	return;
else
  area_id = args["area_id"];
end


local orgService = require "base.organization.services.OrgService";
  
local result  = orgService:getDefaultEducationBureau(area_id);


cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))