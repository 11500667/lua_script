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
if not args["game_id"] or string.len(args["game_id"]) == 0 then
    say("{\"success\":false,\"info\":\"game_id不能为空！\"}")
    return
end
local table = {};
table["game_id"]  = args["game_id"];--游戏名称
table["game_name"]  = args["game_name"];--游戏名称
table["stage_id"] = tonumber(args["stage_id"]);--学段
table["subject_id"] = tonumber(args["subject_id"]);--学科
table["type_id"]  = args["type_id"];--类型
table["sort_type"]  = args["sort_type"];--排名方式  1、关卡 2、分数
if args["url_web"] and args["url_web_ext"] then
    table["url_web"] = args["url_web"].."."..args["url_web_ext"];
end
if args["url_ios"] and args["url_ios_ext"] then
    table["url_ios"] = args["url_ios"].."."..args["url_ios_ext"];
end
if args["url_android"] and args["url_android_ext"] then
    table["url_android"] = args["url_android"].."."..args["url_android_ext"];
end
if args["thumb_url"] and args["thumb_url_ext"] then
    table["thumb_url"] = args["thumb_url"].."."..args["thumb_url_ext"];
end
table["web_version"] = args["web_version"];
table["ios_version"] = args["ios_version"];
table["android_version"] = args["android_version"];
local gameModel = require "yxx.game.model.GameModel";
gameModel:edit_game(table)
ngx.say("{\"success\":true,\"info\":\"编辑成功\"}")