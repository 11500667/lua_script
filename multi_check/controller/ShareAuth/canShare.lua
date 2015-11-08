#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#申健  2015-05-25
#描述：获取用户是否可以共享试题
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

if args["person_id"] == nil or args["person_id"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数person_id不能为空！\"}");
    return;
elseif args["identity_id"] == nil or args["identity_id"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数identity_id不能为空！\"}");
    return;
elseif args["subject_id"] == nil or args["subject_id"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数subject_id不能为空！\"}");
    return;
end

local cjson      = require "cjson";
local result = {};
result.success  = true;
result.can_share = true;

ngx.print(cjson.encode(result));


--[[ 参数：单位ID
local objType    = 2; -- 1资源，2试题，3试卷，4备课，5微课
local personId   = tonumber(args["person_id"]);
local identityId = tonumber(args["identity_id"]);
local subjectId  = tonumber(args["subject_id"]);
ngx.log(ngx.ERR, "[sj_log] -> [share_auth] -> 参数 -> personId:[", personId, "], identityId:[", identityId, "], subject_id:[", subjectId, "]");

local shareAuthModel = require "multi_check.model.ShareAuth";
local booleanResult  = shareAuthModel: canShare(objType, personId, identityId, subjectId);

local cjson      = require "cjson";
local result = {};
if booleanResult ~= nil then
    result.success  = true;
    result.can_share = booleanResult;
else
    result.success  = false;
    result.info     = "获取信息失败";
end

ngx.print(cjson.encode(result));]]