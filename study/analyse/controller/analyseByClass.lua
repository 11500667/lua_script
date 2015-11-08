--
-- 学情分析 -> 按班级进行统计
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
end


local subjectId   = tonumber(args["subject_id"]);
local classId     = tonumber(args["class_id"]);
local teacherId   = tonumber(ngx.var.cookie_person_id);

if subjectId == 0 then
    ngx.print("{\"success\":false,\"info\":\"参数subject_id不能为0\"}");
    return;
end

local studentName = nil;
if args["student_name"] ~= nil and args["student_name"] ~= "" then
    studentName = ngx.decode_base64(args["student_name"]);
end

local startTime = nil;
if args["start_time"] ~= nil and args["start_time"] ~= "" then
    startTime = args["start_time"];
end

local endTime = nil;
if args["end_time"] ~= nil and args["end_time"] ~= "" then
    endTime = args["end_time"];
end

local sortField = "knowledge_point_count";
if args["sort_field"] ~= nil or args["sort_field"] ~= "" then
    sortField = args["sort_field"];
end

local sortType = 2; -- 1升序，2降序
if args["sort_type"] ~= nil or args["sort_type"] ~= "" then
    sortType = tonumber(args["sort_type"]);
end

local analyseService = require "study.analyse.services.StudyAnalyseService";
local resultJsonObj  = analyseService: analyseByClass(subjectId, teacherId, classId, studentName, startTime, endTime, sortField, sortType);

local cjson = require "cjson";
ngx.print(cjson.encode(resultJsonObj));