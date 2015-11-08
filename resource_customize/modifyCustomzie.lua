#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#陈丽月 2015-4-8
#描述：修改用户定制信息
]]

local personId = tostring(ngx.var.cookie_person_id)
local identityId = tostring(ngx.var.cookie_identity_id)

local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["id"]==nil or args["id"]=="" then
    ngx.say("{\"success\":\"false\",\"info\":\"2参数错误！\"}");
	ngx.log(ngx.ERR, "ERR MSG =====> 参数id不能为空！");
    return
end
local id = tostring(args["id"]);

if args["resType"]==nil or args["resType"]=="" then
    ngx.say("{\"success\":\"false\",\"info\":\"2参数错误！\"}");
	ngx.log(ngx.ERR, "ERR MSG =====> 参数res_Type不能为空！");
    return
end
local resType = tostring(args["resType"]);

if args["resComment"]==nil or args["resComment"]=="" then
    ngx.say("{\"success\":\"false\",\"info\":\"2参数错误！\"}");
	ngx.log(ngx.ERR, "ERR MSG =====> 参数resComment不能为空！");
    return
end
local resComment = tostring(args["resComment"]);

if args["res_msg"]==nil or args["res_msg"]=="" then
    ngx.say("{\"success\":\"false\",\"info\":\"2参数错误！\"}");
	ngx.log(ngx.ERR, "ERR MSG =====> 参数res_msg不能为空！");
    return
end

local res_msg = tostring(args["res_msg"]);
--ngx.log(ngx.ERR, "=============="..resComment);
--ngx.log(ngx.ERR, "---------------------------"..res_msg);
local cjson = require "cjson"

local ResourceCustomize = require "resource_customize.model.ResourceCustomize";
local result, info = ResourceCustomize: modifyCustomizeInfo(id, resType, resComment, res_msg);
local resCustomize = {};
resCustomize.success=result;
resCustomize.info=info;
ngx.print(cjson.encode(resCustomize));



