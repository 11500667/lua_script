#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#申健 2015-03-09
#描述：获取审核列表
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
elseif args["obj_type"] == nil or args["obj_type"]=="" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数obj_type不能为空！\"}");
	return;
elseif args["subject_id"] == nil or args["subject_id"]=="" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数subject_id不能为空！\"}");
	return;	
elseif args["scheme_id"] == nil or args["scheme_id"]=="" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数scheme_id不能为空！\"}");
	return;
elseif args["dest_unit"] == nil or args["dest_unit"]=="" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数scheme_id不能为空！\"}");
	return;	
elseif args["check_status"] == nil or args["check_status"]=="" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数check_status不能为空！\"}");
	return;	
elseif args["pageNumber"] == nil or args["pageNumber"]=="" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数pageNumber不能为空！\"}");
	return;	
elseif args["pageSize"] == nil or args["pageSize"]=="" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数pageSize不能为空！\"}");
	return;	
elseif args["recommend_status"] == nil or args["recommend_status"]=="" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数recommend_status不能为空！\"}");
	return;		
end

-- 单位ID
local unitId 	  	  = tonumber(args["unit_id"]);
local objType		  = tonumber(args["obj_type"]);
ngx.log(ngx.ERR, "===> 多级审核的参数：obj_type -> [", objType, "]");
local subjectId       = tonumber(args["subject_id"]);
local schemeId        = tonumber(args["scheme_id"]);
local sourceUnitId    = tonumber(args["source_unit_id"]);
local destUnit        = tonumber(args["dest_unit"]);
local checkStatus     = args["check_status"];
local pageNumber      = tonumber(args["pageNumber"]);
local pageSize        = tonumber(args["pageSize"]);
local personId        = ngx.var.cookie_person_id;
local identityId      = ngx.var.cookie_identity_id;
local recommendStatus = tonumber(args["recommend_status"]);

-- 逻辑描述：前台：全部科目：subjectId为0
--           后台：全部学段：subject_id为-1， 指定学段下的全部科目:subject_id为-2，stage_id为指定学段的值
local stageId       = -1;
if args["stage_id"] ~= nil and args["stage_id"] ~= "" then
	stageId = tonumber(args["stage_id"]);
end

local sharePerName  = args["share_person_name"];
if sharePerName ~= nil and sharePerName ~= "" then
    sharePerName  = ngx.decode_base64(sharePerName);
end

local multiCheck = require "multi_check.model.MultiCheck";
local resultJson = multiCheck: getCheckObjList(unitId, objType, stageId, subjectId, schemeId, sourceUnitId, destUnit, checkStatus, pageNumber, pageSize, personId, identityId, sharePerName, recommendStatus);

local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local jsonStr = cjson.encode(resultJson);

ngx.print(jsonStr);






