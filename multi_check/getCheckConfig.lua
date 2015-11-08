#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#申健 2014-12-22
#描述：获取地区的审核配置
]]

local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["unit_id"] == nil or args["unit_id"]=="" then
  ngx.say("{\"success\":\"false\",\"info\":\"参数unit_id不能为空！\"}");
  return;
end

local unitId = tostring(args["unit_id"]);

local CheckConfig = require "multi_check.model.CheckConfig";
local autoPass, checkWay, forceCheck = CheckConfig: getConfig(unitId);

local configJson = {};
configJson.success      = true;
configJson.auto_pass    = autoPass;
configJson.check_way    = checkWay;
configJson.force_check  = forceCheck;

local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJsonStr = cjson.encode(configJson);

ngx.say(responseJsonStr);

