--
-- 学情分析 -> 按性别进行统计 -> 获取按性别统计学情的统计数据
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
elseif args["knowledge_point_id"] == nil or args["knowledge_point_id"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数knowledge_point_id不能为空！\"}");
    return;
end


local subjectId   = tonumber(args["subject_id"]);
local knowledgeId = tonumber(args["knowledge_point_id"]);
local teacherId   = tonumber(ngx.var.cookie_person_id);

local classId   = nil;
if args["class_id"] ~= nil and args["class_id"] ~= "" then
    classId = tonumber(args["class_id"]);
end

local startTime = nil;
if args["start_time"] ~= nil and args["start_time"] ~= "" then
    startTime = args["start_time"];
end

local endTime = nil;
if args["end_time"] ~= nil and args["end_time"] ~= "" then
    endTime = args["end_time"];
end

local analyseService = require "study.analyse.services.StudyAnalyseService";
local resultJsonObj  = analyseService: analyseBySex(subjectId, knowledgeId, teacherId, classId, startTime, endTime)
local cjson          = require "cjson";
ngx.print(cjson.encode(resultJsonObj));