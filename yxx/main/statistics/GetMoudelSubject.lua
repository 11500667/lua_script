--[[
@Author cuijinlong
@date 2015-4-24
--]]
local say = ngx.say;
local cjson = require "cjson";
local StatModel = require "yxx.main.statistics.model.StatModel";
local args = nil;
local request_method = ngx.var.request_method;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end
local student_id = args["student_id"];
local json = StatModel:get_moudel_subject(student_id);
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(json);
say(responseJson);
