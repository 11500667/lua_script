#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#申健 2015-04-18
#描述：插入统计数据的记录
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

if args["stage_id"] == nil or args["stage_id"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数stage_id不能为空！\"}");
    return;
elseif args["subject_id"] == nil or args["subject_id"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数subject_id不能为空！\"}");
    return;
elseif args["plat_id"] == nil or args["plat_id"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数plat_id不能为空！\"}");
    return;
elseif args["count"] == nil or args["count"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数count不能为空！\"}");
    return;
elseif args["size"] == nil or args["size"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数size不能为空！\"}");
    return;
end

local stageId    = args["stage_id"];
local subjectId  = args["subject_id"];
local platId     = args["plat_id"];
local count      = args["count"];
local size       = args["size"];

local personId   = ngx.var.cookie_person_id;
local identityId = ngx.var.cookie_identity_id;

-- 调用插入数据的接口，将数据保存到数据库中
local AnalyseDataService = require "management.analyse.services.AnalyseDataService";
local result = AnalyseDataService: insertAnalyseData(stageId, subjectId, platId, personId, identityId, count, size);

if result then
   ngx.print("{\"success\":true,\"info\":\"操作成功！\"}");
else
   ngx.print("{\"success\":false,\"info\":\"操作失败！\"}");
end

