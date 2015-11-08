--[[
#陈续刚 2015-08-27
#描述：检验用户名是否存在，[支持添加和编辑时校验]
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

local personId      = args["personId"];
local loginName     = args["loginName"];

--ngx.log(ngx.ERR, "cxg_log =====>"..pids.."==>");	
if loginName == nil then
    ngx.print("{\"success\":false,\"info\":\"参数 loginName 不能为空！\"}");
    return;
end

--ngx.log(ngx.ERR, "cxg_log checkLoginName loginName=====>"..loginName.."==>");	
local regModel  = require "registered.ypt.model.register";
local result = regModel.checkLoginName(personId,loginName);

local returnjson={}
if result then 
	returnjson.success = true
	returnjson.info = "该账号未被注册，可以使用。"
else
	returnjson.success = false
	returnjson.info = "该账号已被注册。"
end
say(cjson.encode(returnjson))