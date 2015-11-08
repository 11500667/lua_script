#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#陈丽月 2015-04-12
#描述：审核通过
]]
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

--参数：id

if args["id"]==nil or args["id"]=="" then
    ngx.say("{\"success\":\"false\",\"info\":\"2参数错误！\"}");
	ngx.log(ngx.ERR, "ERR MSG =====> 参数id不能为空！");
    return
end
local id = tostring(args["id"]);

--参数：checkStatus

if args["checkStatus"]==nil or args["checkStatus"]=="" then
    ngx.say("{\"success\":\"false\",\"info\":\"2参数错误！\"}");
	ngx.log(ngx.ERR, "ERR MSG =====> 参数checkStatus不能为空！");
    return
end
local checkStatus = tostring(args["checkStatus"]);

--参数：checkMsg

if args["checkMsg"]==nil or args["checkMsg"]=="" then
    ngx.say("{\"success\":\"false\",\"info\":\"2参数错误！\"}");
	ngx.log(ngx.ERR, "ERR MSG =====> 参数checkMsg不能为空！");
    return
end
local checkMsg = tostring(args["checkMsg"]);

local cjson = require "cjson"

local ResourceCustomize = require "resource_customize.model.ResourceCustomize";
local typeValueJson, info = ResourceCustomize: check(id, checkStatus, checkMsg);
local reasonCustomize = {};
reasonCustomize.success=typeValueJson;
reasonCustomize.info=info;
ngx.print(cjson.encode(reasonCustomize));

