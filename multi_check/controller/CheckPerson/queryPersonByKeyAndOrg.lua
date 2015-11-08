#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#申健 2015-03-09
#描述：获取教师用户的特殊功能列表
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
elseif args["page"] == nil or args["page"]=="" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数page不能为空！\"}");
	return;	
elseif args["rows"] == nil or args["rows"]=="" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数rows不能为空！\"}");
	return;		
end

-- 单位ID
local unitId 		= tonumber(args["unit_id"]);
-- ngx.log(ngx.ERR, "===> args[\"searchTerm\"]-------------> [", args["searchTerm"], "]");
local queryKey  	= ngx.unescape_uri(args["searchTerm"]);
-- ngx.log(ngx.ERR, "===> queryKey urldecode -------------> [", queryKey, "]");
queryKey = ngx.decode_base64(queryKey);
-- ngx.log(ngx.ERR, "===> queryKey base64 decode-------------> [", queryNameKey, "]");
local pageNumber  	= tonumber(args["page"]);
local pageSize    	= tonumber(args["rows"]);

local CheckPerson = require "multi_check.model.CheckPerson";
local resultJson = CheckPerson: queryPersonByKeyAndOrg(unitId, queryKey, pageNumber, pageSize);

local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local jsonStr = cjson.encode(resultJson);

ngx.print(jsonStr);