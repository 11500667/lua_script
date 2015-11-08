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
local subject_ids = args["subject_ids"];
if not subject_ids or string.len(subject_ids) == 0 then
    say("{\"success\":false,\"info\":\"subject_id不能为空\"}")
    return
end
local subject_id_arr = Split(subject_ids,",");
local AppModel = require "yxx.app.model.AppModel";
local appListJson = AppModel:app_list_by_subject(subject_id_arr);
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(appListJson);
say(responseJson);