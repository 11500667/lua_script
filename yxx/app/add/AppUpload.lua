--[[
@Author cuijinlong
@date 2015-4-24
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
if tonumber(args["topic_game"]) == "nil" then
    ngx.say("{\"success\":false,\"info\":\"class_id,teacher_id,question_id,content 参数错误\"}");
    return
end
local table = {};
table["topic_game"] = tonumber(args["topic_game"]);--topic or game  1 or 2
table["subject_id"] = args["subject_id"]; --学科
table["url_apk"] = args["url_apk"]; --Android URL
table["apk_version"] = args["apk_version"];--Android版本
table["url_ios"] = args["url_ios"];--Ios URL
table["ios_version"] = args["ios_version"];--Ios版本
table["create_time"] = ngx.localtime();
--table["topic_game"] = 1;--topic or game  1 or 2
--table["subject_id"] = -1; --学科
--table["url_apk"] = "sff2323423"; --Android URL
--table["apk_version"] = "sff2323423";--Android版本
--table["url_ios"] = "sff2323fdgdgsdfgsdfgsd423";--Ios URL
--table["ios_version"] = "sff2323fdgdgsdfgsdfgsd423";--Ios版本
local appModel = require "yxx.app.model.AppModel";
appModel:upload_app(table);
ngx.say("{\"success\":true,\"info\":\"上传成功\"}")