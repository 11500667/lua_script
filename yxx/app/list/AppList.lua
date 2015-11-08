--[[
@Author cuijinlong
@date 2015-6-10
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
local topic_game = args["topic_game"];
local subject_id = args["subject_id"];
if not topic_game or string.len(topic_game) == 0 then
    say("{\"success\":false,\"info\":\"topic_game不能为空\"}")
    return
end
if tonumber(topic_game) == 2 then
    if not subject_id or string.len(subject_id) == 0 then
        say("{\"success\":false,\"info\":\"subject_id不能为空\"}")
        return
    end
end
local AppModel = require "yxx.app.model.AppModel";
local appListJson = AppModel:app_list(topic_game,subject_id);
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(appListJson);
say(responseJson);