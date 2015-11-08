--[[
@Author cuijinlong
@date 2015-4-24
--]]
--  获取request的参数
local say = ngx.say;
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end
local student_id = args["student_id"];
local class_id = args["class_id"];
local game_id = args["game_id"];
local game_result = args["game_result"];
if not student_id or string.len(student_id) == 0
        or not class_id or string.len(class_id) == 0
            or not game_id or string.len(game_id) == 0 then
    say("{\"success\":false,\"info\":\"student_id、class_id、game_id:不能为空！\"}")
    return
end
local table = {};
table["game_id"] = game_id;
table["student_id"] = student_id;
table["class_id"] = class_id;
table["game_result"] = game_result;
table["last_game_result"] = game_result;
table["favorite"] = 0;
table["recommend"] = 0;
table["last_game_time"] = ngx.localtime();
local gameModel = require "yxx.game.model.GameModel";
local table = gameModel:get_game_reslut(table);
gameModel:add_game_student(table);
--gameModel:add_game_student(student_id,class_id,game_id);
say("{\"success\":true}")
