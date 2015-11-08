--[[
#陈续刚 2015-08-31
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

local Ptype         = args["Ptype"];
local loginName     = args["loginName"];
local tel           = args["tel"];
local pwd           = args["pwd"];

--ngx.log(ngx.ERR, "cxg_log =====>"..pids.."==>");	
if Ptype == nil then
    ngx.print("{\"success\":false,\"info\":\"参数 Ptype 不能为空！\"}");
    return;
end
if tel == nil then
    ngx.print("{\"success\":false,\"info\":\"参数 tel 不能为空！\"}");
    return;
end
if pwd == nil then
    ngx.print("{\"success\":false,\"info\":\"参数 pwd 不能为空！\"}");
    return;
end
if tonumber(Ptype)==2 then
	if loginName == nil then
		ngx.print("{\"success\":false,\"info\":\"参数 loginName 不能为空！\"}");
		return;
	end
end

--ngx.log(ngx.ERR, "cxg_log checkLoginName loginName=====>"..loginName.."==>");	
local regModel  = require "registered.ypt.model.register";
pwd = ngx.md5(pwd)
local result = regModel.setPwdByparams(Ptype,loginName,tel,pwd);

local returnjson={}
if result then 
	returnjson.success = true
	returnjson.info = "修改密码成功！"
else
	returnjson.success = false
	returnjson.info = "修改密码失败。"
end
say(cjson.encode(returnjson))