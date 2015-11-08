--[[
#陈续刚 2015-08-06
#描述：机构群组添加成员
]]
--引用模块
local cjson = require "cjson"
local say = ngx.say
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end
--groupId,currentTime,ts,pids,oids,state_id
local groupId      = getParamToNumber("groupId");

--[[for k,v in pairs(args) do 
	ngx.log(ngx.ERR, "\n name:[", k, "], value:[", v, "]");
end ]]

local pids = getParamByName("pids")
if pids then
	pids = cjson.decode(pids)
end
local oids = getParamByName("oids")
if oids then
	oids = cjson.decode(oids)
end
local state_id = 1
--ngx.log(ngx.ERR, "cxg_log =====>"..pids.."==>");	
if groupId == nil then
    ngx.print("{\"success\":false,\"info\":\"参数groupId不能为空！\"}");
    return;
--[[elseif oids == nil then
    ngx.print("{\"success\":false,\"info\":\"参数oids不能为空！\"}");
    return;]]
end

local currentTime = os.date("%Y-%m-%d %H:%M:%S")
local n = ngx.now();
local ts = os.date("%Y%m%d%H%M%S").."00"..string.sub(n,12,14);
ts = ts..string.rep("0",19-string.len(ts));

local groupModel  = require "base.group.model.groupMember";
local result = groupModel.addMember(groupId,currentTime,ts,pids,oids,state_id);

local returnjson={}
if result  then 
	returnjson.success = true
	returnjson.info = "群组添加成员成功！"
else
	returnjson.success = false
	returnjson.info = "群组添加成员失败！"
end
say(cjson.encode(returnjson))