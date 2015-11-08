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
local game_id = args["game_id"];
local class_id = args["class_id"];
if not game_id or string.len(game_id) == 0 or not class_id or string.len(class_id) == 0 then
    say("{\"success\":false,\"info\":\"game_id、class_id:不能为空！\"}")
    return
end
local gameModel = require "yxx.game.model.GameModel";
local gameListJson = gameModel:get_stu_game_dynamic(game_id,class_id);
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(gameListJson);
say(responseJson);

