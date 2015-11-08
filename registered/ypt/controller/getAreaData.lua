--[[
#陈续刚 2015-08-28
#描述：获取省市区
]]
--引用模块
local cjson = require "cjson"
local say = ngx.say
local args = nil;
local request_method = ngx.var.request_method
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

local parentId   = args["parentId"];
local typeId     = args["typeId"];

--ngx.log(ngx.ERR, "cxg_log =====>"..parentId.."==>");	
if parentId == nil then
    ngx.print("{\"success\":false,\"info\":\"参数 parentId 不能为空！\"}");
    return;
end
if typeId == nil then
    ngx.print("{\"success\":false,\"info\":\"参数 typeId 不能为空！\"}");
    return;
end

local _Register  = require "registered.ypt.model.register";
local returnjson = _Register.getAreaData(parentId,typeId);

say(cjson.encode(returnjson))