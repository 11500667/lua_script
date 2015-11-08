--[[
#陈续刚 2015-08-29
#描述：审核注册的学校
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

local orgId         = args["orgId"];
local auditStatus   = args["auditStatus"];
local auditDesc     = args["auditDesc"];

--ngx.log(ngx.ERR, "cxg_log =====>"..pids.."==>");	
if orgId == nil then
    ngx.print("{\"success\":false,\"info\":\"参数 orgId 不能为空！\"}");
    return;
end
if auditStatus == nil then
    ngx.print("{\"success\":false,\"info\":\"参数 auditStatus 不能为空！\"}");
    return;
end

--ngx.log(ngx.ERR, "cxg_log checkLoginName loginName=====>"..loginName.."==>");	
local regModel  = require "registered.ypt.model.register";
local result = regModel.auditOrgInfo(orgId,auditStatus,auditDesc);

local returnjson={}
if result then 
	returnjson.success = true
	returnjson.info = "学校成功通过审核！"
else
	returnjson.success = false
	returnjson.info = "学校审核不通过。"
end
say(cjson.encode(returnjson))