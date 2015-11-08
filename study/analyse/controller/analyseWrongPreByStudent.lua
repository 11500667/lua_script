--
-- 学情分析 -> 按班级进行统计 -> 按学生统计错误知识点的个人错误率和班级错误率
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
elseif args["class_id"] == nil or args["class_id"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数class_id不能为空！\"}");
    return;
elseif args["student_id"] == nil or args["student_id"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数student_id不能为空！\"}");
    return;
elseif args["pageNumber"] == nil or args["pageNumber"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数pageNumber不能为空！\"}");
    return;
elseif args["pageSize"] == nil or args["pageSize"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数pageSize不能为空！\"}");
    return;
end


local subjectId   = tonumber(args["subject_id"]);
local classId     = tonumber(args["class_id"]);
local studentId   = tonumber(args["student_id"]);
local pageNumber  = tonumber(args["pageNumber"]);
local pageSize    = tonumber(args["pageSize"]);
local teacherId   = tonumber(ngx.var.cookie_person_id);


local startTime = nil;
if args["start_time"] ~= nil or args["start_time"] ~= "" then
    startTime = args["start_time"];
end

local endTime = nil;
if args["end_time"] ~= nil or args["end_time"] ~= "" then
    endTime = args["end_time"];
end

local sortField = nil;
if args["sort_field"] ~= nil or args["sort_field"] ~= "" then
    sortField = args["sort_field"];
end

local sortType = nil;
if args["sort_type"] ~= nil or args["sort_type"] ~= "" then
    sortType = tonumber(args["sort_type"]);
end

local analyseService = require "study.analyse.services.StudyAnalyseService";
local resultJsonObj = analyseService: analyseWrongPreByStudent(subjectId, classId, teacherId, studentId, startTime, endTime, pageNumber, pageSize, sortField, sortType);
local cjson = require "cjson";
ngx.print(cjson.encode(resultJsonObj));