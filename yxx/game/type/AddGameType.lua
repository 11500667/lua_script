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
local subject_id = args["subject_id"];
if not subject_id or string.len(subject_id) == 0 then
    ngx.say("{\"success\":false,\"info\":\"subject_id:不能为空！\"}");
    return
end
local game_type_name = args["game_type_name"];
local gameModel = require "yxx.game.model.GameModel";
gameModel:add_type(subject_id,game_type_name);

