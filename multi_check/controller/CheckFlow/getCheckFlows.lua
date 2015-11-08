#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#申健  2015-06-03
#描述：获取指定审核信息的审核流程
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

if args["check_id"] == nil or args["check_id"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数check_id不能为空！\"}");
    return;
end

local checkId = args["check_id"];

ngx.log(ngx.ERR, "[sj_log] -> [multi_check] -> 参数 -> check_id:[", checkId, "]");
local cjson          = require "cjson";
cjson.encode_empty_table_as_object(false);
local checkFlowModel = require "multi_check.model.CheckFlow";
local resultTable    = checkFlowModel: getByCheckId(checkId);

local resultJsonObj = {};
if not resultTable then
    resultJsonObj.success   = false;
    resultJsonObj.flow_list = {};
else
    resultJsonObj.success   = true;
    resultJsonObj.flow_list = resultTable;
end

ngx.print(cjson.encode(resultJsonObj));