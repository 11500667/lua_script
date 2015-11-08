--[[
@Author cuijinlong
@date 2015-4-24
--]]
local say = ngx.say;
local cjson = require "cjson";
local args = nil;
local request_method = ngx.var.request_method;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end
local student_id = args["student_id"];
local model_id = args["model_id"];
local SSDBUtil = require "yxx.tool.SSDBUtil";
local ssdb = SSDBUtil:getDb();
local remind_state = ssdb:get("moudel_remind_"..student_id.."_"..model_id);
SSDBUtil:keepAlive();
if string.len(remind_state[1]) > 0 then
    say("{\"remind_state\":false}");
else
    say("{\"remind_state\":true}");
end

