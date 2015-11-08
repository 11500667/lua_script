--[[
@Author cuijinlong
@date 2015-4-24
--]]
--  获取request的参数
local ParameterUtil = require "yxx.tool.ParameterUtil"
local table = {};
table["topic_name"]  = ParameterUtil:getStrParam("topic_name","");--游戏名称
table["stage_id"] = ParameterUtil:getNumParam("stage_id",-1);--学段
table["subject_id"] = ParameterUtil:getNumParam("subject_id",-1);--学科
table["quality_goods"]  = 1;--精品
table["type_id"]  = ParameterUtil:getNumParam("type_id",-1);--类型
table["view_count"]  = 0;--URL
table["down_count"] = 0;
table["score"] = 0;
table["html_url"] = "";
table["create_time"] = ngx.localtime();
table["swf_version"] = ParameterUtil:getStrParam("swf_version","");
table["ios_version"] = ParameterUtil:getStrParam("ios_version","");
table["android_version"] = ParameterUtil:getStrParam("android_version","");
local swf_url  = ParameterUtil:getStrParam("swf_url","");
local swf_url_ext  = ParameterUtil:getStrParam("swf_url_ext","")
local ios_url  = ParameterUtil:getStrParam("ios_url","");
local ios_url_ext  = ParameterUtil:getStrParam("ios_url_ext","");
local android_url  = ParameterUtil:getStrParam("android_url","");
local android_url_ext  = ParameterUtil:getStrParam("android_url_ext","");
local thumb_url  = ParameterUtil:getStrParam("thumb_url","");
local thumb_url_ext  = ParameterUtil:getStrParam("thumb_url_ext","");
if swf_url ~= '' and swf_url_ext ~='' then
    table["swf_url"] = swf_url.."."..swf_url_ext;
else
    table["swf_url"] = '';
end
if ios_url ~= '' and ios_url_ext ~='' then
    table["ios_url"] = ios_url.."."..ios_url_ext;
else
    table["ios_url"] = '';
end
if android_url ~= '' and android_url_ext ~='' then
    table["android_url"] = android_url.."."..android_url_ext;
else
    table["android_url"] = '';
end
if thumb_url ~= '' and thumb_url_ext ~='' then
    table["thumb_url"] = thumb_url.."."..thumb_url_ext;
else
    table["thumb_url"] = '';
end
local TopicModel = require "yxx.topic.model.TopicModel";
TopicModel:upload_topic(table)
ngx.say("{\"success\":true,\"info\":\"上传成功\"}")