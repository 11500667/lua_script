#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#申健 2015-04-10
#描述：删除审核信息
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

if args["param_json"] == nil or args["param_json"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数param_json不能为空！\"}");
    return;
end


-- 参数：待删除的审核信息的ID，格式： { check_ids:[111,222,333,444]}
local paramJsonStr  = tostring(args["param_json"]);
ngx.log(ngx.ERR, "===> paramJson ===> ", paramJsonStr);

local cjson      = require "cjson";
local paramJson  = cjson.decode(paramJsonStr);
local checkIdTab = paramJson.check_ids;

local CheckInfoModel = require "multi_check.model.CheckInfo";
local booleanResult  = CheckInfoModel: batchDelCheckInfo(checkIdTab);

if booleanResult then
	ngx.print("{\"success\":true,\"info\":\"操作成功！\"}");
else
	ngx.print("{\"success\":false,\"info\":\"操作失败！\"}");
end


