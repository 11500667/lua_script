--[[
@Author cuijinlong
@date 2015-4-24
--]]
--  获取request的参数
local ParameterUtil = require "yxx.tool.ParameterUtil"
local table = {};
table["game_name"]  = ParameterUtil:getStrParam("game_name","");--游戏名称
table["stage_id"] = ParameterUtil:getNumParam("stage_id",-1);--学段
table["subject_id"] = ParameterUtil:getNumParam("subject_id",-1);--学科
table["type_id"]  =  ParameterUtil:getNumParam("type_id",-1);--类型
table["sort_type"]  = ParameterUtil:getNumParam("sort_type",-1);--排名方式  1、关卡 2、分数
table["quality_goods"]  = ParameterUtil:getNumParam("quality_goods",1);--精品
table["user_count"]  =  ParameterUtil:getNumParam("user_count",0);
table["create_time"] = ngx.localtime();
local url_web = ParameterUtil:getStrParam("url_web","");
local url_web_ext = ParameterUtil:getStrParam("url_web_ext","");
local url_ios = ParameterUtil:getStrParam("url_ios","");
local url_ios_ext = ParameterUtil:getStrParam("url_ios_ext","");
local url_android = ParameterUtil:getStrParam("url_android","");
local url_android_ext = ParameterUtil:getStrParam("url_android_ext","");
local thumb_url = ParameterUtil:getStrParam("thumb_url","");
local thumb_url_ext = ParameterUtil:getStrParam("thumb_url_ext","");
table["web_version"] = ParameterUtil:getStrParam("web_version","");
table["ios_version"] = ParameterUtil:getStrParam("ios_version","");
table["android_version"] = ParameterUtil:getStrParam("android_version","");
if url_web ~= '' and url_web_ext ~= '' then
    table["url_web"] = url_web.."."..url_web_ext;
else
    table["url_web"] = "";
end
if url_ios ~= '' and url_ios_ext ~= '' then
    table["url_ios"] = url_ios.."."..url_ios_ext;
else
    table["url_ios"] = "";
end
if url_android ~= '' and url_android_ext ~= '' then
    table["url_android"] = url_android.."."..url_android_ext;
else
    table["url_android"] = "";
end
if thumb_url ~= '' and thumb_url_ext ~= '' then
    table["thumb_url"] = thumb_url.."."..thumb_url_ext;
else
    table["thumb_url"] = "";
end

local gameModel = require "yxx.game.model.GameModel";
gameModel:upload_game(table);
ngx.say("{\"success\":true,\"info\":\"上传成功\"}")