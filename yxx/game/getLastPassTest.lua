--[[
@Author cuijinlong
@date 2015-4-10
--]]
--定义函数
local say = ngx.say;
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end
local game_id = args["game_id"]
local student_id = ngx.var.cookie_person_id
if not game_id or string.len(game_id) == 0 then
    say("{\"success\":false,\"info\":\"game_id不能为空！\"}")
    return
end
--通过班级id和游戏id获得该班级学生的玩游戏过关数
local gameModel = require "yxx.game.model.GameModel";
local last_pass_test = gameModel:get_last_game_result(game_id,student_id);
say("{\"success\":true,\"last_pass_test\":"..last_pass_test.."}");















