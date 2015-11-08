--
-- 学情分析 -> 按性别进行统计 -> 获取指定科目下按错题数倒序的知识点列表，支持分页
-- 请求方式：GET
-- 作者: shenjian
-- 日期: 2015/5/8
--

-- 1.获取参数
local request_method = ngx.var.request_method;
local args;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["subject_id"] == nil or args["subject_id"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数subject_id不能为空！\"}");
    return;
elseif args["pageNumber"] == nil or args["pageNumber"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数pageNumber不能为空！\"}");
    return;
elseif args["pageSize"] == nil or args["pageSize"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数pageSize不能为空！\"}");
    return;
end


local subjectId   = tonumber(args["subject_id"]);
local pageNumber  = tonumber(args["pageNumber"]);
local pageSize    = tonumber(args["pageSize"]);
local teacherId   = tonumber(ngx.var.cookie_person_id);

local classId   = nil;
if args["class_id"] ~= nil and args["class_id"] ~= "" then
    classId = tonumber(args["class_id"]);
end

local zsdName   = nil;
if args["query_key"] ~= nil and args["query_key"] ~= "" then
    zsdName = ngx.decode_base64(args["query_key"]);
end

local startTime = nil;
if args["start_time"] ~= nil and args["start_time"] ~= "" then
    startTime = args["start_time"];
end

local endTime   = nil;
if args["end_time"] ~= nil and args["end_time"] ~= "" then
    endTime = args["end_time"];
end

local sortField = "wrong_count";
if args["sort_field"] ~= nil and args["sort_field"] ~= "" then
    sortField = args["sort_field"];
end

local sortType  = 2; -- 1升序，2降序
if args["sort_type"] ~= nil and args["sort_type"] ~= "" then
    sortType = tonumber(args["sort_type"]);
end

local analyseService = require "study.analyse.services.StudyAnalyseService";
local resultJsonObj  = analyseService: getKnowledgeByPageSort(subjectId, teacherId, classId, startTime, endTime, zsdName, pageNumber, pageSize, sortField, sortType)
local cjson = require "cjson";
ngx.print(cjson.encode(resultJsonObj));