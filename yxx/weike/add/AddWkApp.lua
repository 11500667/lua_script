--[[
@Author cuijinlong
@date 2015-6-17
--]]
--  获取request的参数
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end
local table = {};
table["app_name"] = args["app_name"];--app名称
table["app_version"]  = args["app_version"];--app版本
table["remark"]  = args["remark"];--备注
table["apk_url"]  = args["apk_url"];--URL
table["create_time"] = ngx.localtime();
local WkModel = require "yxx.weike.model.WkModel";
WkModel:app_update_record_add(table);
ngx.say("{\"success\":true,\"info\":\"上传成功\"}");