#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#申健  2015-05-25
#描述：获取推荐的对象信息
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

local paramJson = args["param_json"];
local cjson     = require "cjson";
local paramObj  = cjson.decode(paramJson);
ngx.log(ngx.ERR, "[sj_log] -> [share_auth] -> 参数 -> param_json:[", paramJson, "]");

local recommendModel = require "multi_check.model.Recommend";
local resultTable    = recommendModel: getRecommendByIds(paramObj);

ngx.print(cjson.encode(resultTable));