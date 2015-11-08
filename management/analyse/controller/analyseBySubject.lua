#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#申健 2015-04-19
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

if args["gov_id"] == nil or args["gov_id"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数gov_id不能为空！\"}");
    return;
elseif args["stage_id"] == nil or args["stage_id"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数stage_id不能为空！\"}");
    return;
elseif args["plat_id"] == nil or args["plat_id"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数plat_id不能为空！\"}");
    return;
end

local unitId     = tonumber(args["gov_id"]);
local stageId    = tonumber(args["stage_id"]);
local platId     = tonumber(args["plat_id"]);
local startTime  = nil;
local endTime    = nil;
if args["start_time"] ~= nil and args["start_time"] ~= "" then
    startTime  = args["start_time"];
end

if args["end_time"] ~= nil and args["end_time"] ~= "" then
    endTime    = args["end_time"];
end

local personId   = ngx.var.cookie_person_id;
local identityId = ngx.var.cookie_identity_id;

local cpModel = require "multi_check.model.CheckPerson";
local govType = cpModel: getUnitType(unitId);

-- 调用插入数据的接口，将数据保存到数据库中
local AnalyseDataService = require "management.analyse.services.AnalyseDataService";
local resultObj = AnalyseDataService: analyseDataByStage(govType, unitId, platId, stageId, startTime, endTime);

local cjson = require "cjson";
local responseJsonStr = cjson.encode(resultObj);
ngx.print(responseJsonStr);


