--[[
@Author cuijinlong
@date 2015-6-10
--]]
local say = ngx.say
local cjson = require "cjson"
--  获取request的参数
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end
local id = args["id"];
if not id or string.len(id) == 0 then
    say("{\"success\":false,\"info\":\"id不能为空\"}")
    return
end
local AppModel = require "yxx.app.model.AppModel";
AppModel:app_del(id);
say("{\"success\":true,\"info\":\"删除成功!\"}")