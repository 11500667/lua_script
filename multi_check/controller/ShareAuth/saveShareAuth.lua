#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#申健  2015-05-25
#描述：保存共享权限
]]

-- 1.获取参数
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["unit_id"] == nil or args["unit_id"]=="" then
    ngx.say("{\"success\":false,\"info\":\"参数unit_id不能为空！\"}");
    return;
elseif args["param_json"] == nil or args["param_json"]=="" then
    ngx.say("{\"success\":false,\"info\":\"参数param_json不能为空！\"}");
    return;
end

-- 参数：单位ID
local unitId   = tonumber(args["unit_id"]);
ngx.log(ngx.ERR, "[sj_log] -> [share_auth] ->  unitId ===> type: [", type(unitId), "], ===> value : [", unitId, "]");
-- 参数：共享权限参数
local paramJson  = tostring(args["param_json"]);
ngx.log(ngx.ERR, "[sj_log] -> [share_auth] ->  paramJson ===> [", paramJson, "]");

local cjson = require "cjson";
local paramObj = cjson.decode(paramJson);
paramObj.unit_id = unitId;

local shareAuthModel = require "multi_check.model.ShareAuth";
local result = shareAuthModel: saveShareAuth(paramObj);

if result then
    ngx.print("{\"success\":true,\"info\":\"保存成功\"}");
else 
    ngx.print("{\"success\":true,\"info\":\"保存失败\"}");
end
