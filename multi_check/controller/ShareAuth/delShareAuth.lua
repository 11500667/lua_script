#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#申健 2015-05-25
#描述：删除指定的共享权限
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
    ngx.print("{\"success\":false,\"info\":\"参数unit_id不能为空！\"}");
    return;
elseif args["param_json"] == nil or args["param_json"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数param_json不能为空！\"}");
    return;
end

-- 参数：单位ID
local unitId   = tonumber(args["unit_id"]);
ngx.log(ngx.ERR, "[sj_log] -> [share_auth] -> unitId -> type:[", type(unitId), "], value:[", unitId, "]");
-- 参数：审核人员信息参数
local paramJsonStr  = tostring(args["param_json"]);
ngx.log(ngx.ERR, "[sj_log] -> [share_auth] -> paramJson ===> ", paramJsonStr);

local cjson = require "cjson";
local paramJson = cjson.decode(paramJsonStr);

local shareAuthModel = require "multi_check.model.ShareAuth";
local booleanResult  = shareAuthModel: delShareAuth(paramJson);

if booleanResult then
    ngx.print("{\"success\":true,\"info\":\"操作成功！\"}");
else
    ngx.print("{\"success\":false,\"info\":\"操作失败！\"}");
end


