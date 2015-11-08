--[[
@Author cuijinlong
@date 2015-6-17
--]]
local say = ngx.say
local cjson = require "cjson"
--  获取request的参数
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end
local page_size = tonumber(args["page_size"]);
local page_number = tonumber(args["page_number"]);
local WkModel = require "yxx.weike.model.WkModel";
--学生获得我的错题列表
local return_list = WkModel:app_update_record_list(page_size,page_number);
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(return_list);
say(responseJson);