#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#申健 2015-04-23
#描述： 插入统计数据的记录
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
elseif args["dest_org_id"] == nil or args["dest_org_id"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数dest_org_id不能为空！\"}");
    return;
end

local unitId     = tonumber(args["gov_id"]);
local destOrgId  = tonumber(args["dest_org_id"]);
ngx.log(ngx.ERR, "[sj_log] -> [management_analyse] -> destOrgId ===> ", destOrgId);

local startTime  = nil; -- 开始时间
if args["start_time"] ~= nil and args["start_time"] ~= "" then
    startTime = args["start_time"];
end

local endTime    = nil; -- 结束时间
if args["end_time"] ~= nil and args["end_time"] ~= "" then
    endTime   = args["end_time"];
end

local strucId = nil; -- 当前节点的ID
if args["structure_id"] ~= nil and args["structure_id"] ~= "" then
    strucId   = tonumber(args["structure_id"]);
end

local hasChild = 0; -- 0不包含子节点，1包含子节点
if args["has_child"] ~= nil and args["has_child"] ~= "" then
    hasChild  = tonumber(args["has_child"]);
end

local cpModel    = require "multi_check.model.CheckPerson";
local govType    = cpModel: getUnitType(unitId);

-- 调用插入数据的接口，将数据保存到数据库中
local AnalyseDataService = require "management.analyse.services.AnalyseDataService";
local resultObj = AnalyseDataService: analyseDataByStructure(govType, unitId, destOrgId, strucId, hasChild, startTime, endTime);

local cjson = require "cjson";
local responseJsonStr = cjson.encode(resultObj);
-- ngx.log(ngx.ERR, "[sj_log]-> [management_analyse] -> 按节点统计的返回值：[[[", responseJsonStr, "]]]");
ngx.print(responseJsonStr);


