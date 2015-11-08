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

local game_id  = args["game_id"];--游戏ID
local GameModel = require "yxx.game.model.GameModel";
GameModel:del_game(game_id);
ngx.say("{\"success\":true,\"info\":\"删除成功\"}")