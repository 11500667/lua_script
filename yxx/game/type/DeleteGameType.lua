--[[
@Author cuijinlong
@date 2015-4-24
--]]
local say = ngx.say
--  获取request的参数
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end
local game_type_id = args["game_type_id"];
if not game_type_id or string.len(game_type_id) == 0 then
    say("{\"success\":false,\"info\":\"subject_id:不能为空！\"}")
    return
end
local gameModel = require "yxx.game.model.GameModel";
gameModel:delete_type(game_type_id);

