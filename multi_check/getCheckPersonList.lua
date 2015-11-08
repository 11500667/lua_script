#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#申健 2015-03-07
#描述：获取指定单位的审核人员列表
]]

--  获取request的参数
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["unit_id"] == nil or args["unit_id"]=="" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数unit_id不能为空！\"}");
	return;
elseif args["pageNumber"] == nil or args["pageNumber"]=="" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数pageNumber不能为空！\"}");
	return;	
elseif args["pageSize"] == nil or args["pageSize"]=="" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数pageSize不能为空！\"}");
	return;		
end

for k,v in pairs(args) do
    ngx.log(ngx.ERR, "[sj_log] -> [check_person] -> args: key->[", k, "], val->[", v, "]");
end

local stageId = nil;
if args["stage_id"] ~= nil and args["stage_id"] ~= "" then
    stageId = tonumber(args["stage_id"]);
end

local subjectId = nil;
if args["subject_id"] ~= nil and args["subject_id"] ~= "" then
    subjectId = tonumber(args["subject_id"]);
end

local personKey = nil;
if args["person_key"] ~= nil and args["person_key"] ~= "" then
    personKey = args["person_key"];
end

local unitArrayStr = nil;
local unitArray    = nil;
if args["unit_json"] ~= nil and args["unit_json"] ~= "" then
    unitJson = args["unit_json"];
    ngx.log(ngx.ERR, "[sj_log] -> [check_person] -> unit_json: [", unitJson, "]");
    local cjson = require "cjson";
    unitArray = cjson.decode(unitJson);
end

-- 单位ID
local unitId 	  = tonumber(args["unit_id"]);
local pageNumber  = tonumber(args["pageNumber"]);
local pageSize    = tonumber(args["pageSize"]);

local CheckPerson = require "multi_check.model.CheckPerson";
local personJson  = CheckPerson: getCheckPersonByUnitId(unitId, stageId, subjectId, personKey, unitArray, pageNumber, pageSize);

local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local jsonStr = cjson.encode(personJson);

ngx.print(jsonStr);
