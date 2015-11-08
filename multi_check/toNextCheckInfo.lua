#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#申健 2015-03-13
#描述：获取下一条审核记录信息
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
elseif args["check_id"] == nil or args["check_id"]=="" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数check_id不能为空！\"}");
	return;		
end

-- 单位ID
local unitId 	  	= tonumber(args["unit_id"]);
local objType		= tonumber(args["obj_type"]);
local subjectId		= tonumber(args["subject_id"]);
local schemeId		= tonumber(args["scheme_id"]);
local sourceUnitId	= tonumber(args["source_unit_id"]);
local destUnit		= tonumber(args["dest_unit"]);
local checkStatus	= args["check_status"];
local checkId	  	= tonumber(args["check_id"]);
local personId 	  	= ngx.var.cookie_person_id;
local identityId  	= ngx.var.cookie_identity_id;

-- 逻辑描述：前台：全部科目：subjectId为0
--           后台：全部学段：subject_id为-1， 指定学段下的全部科目:subject_id为-2，stage_id为指定学段的值
local stageId       = -1;
if args["stage_id"] ~= nil and args["stage_id"] ~= "" then
	stageId = tonumber(args["stage_id"]);
end

local multiCheck = require "multi_check.model.MultiCheck";
local success, obj  = multiCheck: getNextCheckInfo(unitId, objType, stageId, subjectId, schemeId, sourceUnitId, destUnit, checkStatus, checkId, personId, identityId);

local resultObj = {};
if success then 
	resultObj.success = true;
	resultObj.check_info = obj;
else
	resultObj.success = false;
	resultObj.info = obj;
end

local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local jsonStr = cjson.encode(resultObj);
ngx.print(jsonStr);






