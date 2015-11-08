#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
@Author cuijinlong
@date 2015-4-24
--]]
local say = ngx.say
local cjson = require "cjson"
--连接mysql数据库
local DBUtil = require "game.util.DBUtil";
local db = DBUtil: getDb();


--  获取request的参数
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then 
	args = ngx.req.get_uri_args(); 
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end
if args["resource_id"] == nil or args["resource_id"]=="" then
	ngx.print("{\"success\":false,\"info\":\"参数resource_id不能为空！\"}");
	return;
end
local game_id = args["game_id"];--游戏id
local ssdb_info = {}
ssdb_info["game_name"] = args["game_name"];--游戏名称
ssdb_info["game_type"] = tonumber(args["game_type"]);--游戏类型  动作 智力  休闲
ssdb_info["game_applicable"] = tonumber(args["game_applicable"]);--游戏适合范围  ngx.localtime()
ssdb_info["censorship_num"] = tonumber(args["censorship_num"]);--游戏的关卡数
ssdb_info["game_rule"] = args["game_rule"];--游戏规则
ssdb_info["xd_id"] = tonumber(args["xd_id"]);--所属学段
ssdb_info["subject_id"] = tonumber(args["subject_id"]);--所属学科
ssdb_info["resource_id"] = args["resource_id"];--游戏资源ID
ssdb_info["game_format"] = args["game_format"];--游戏格式  2d_3d

local gameModel = require "game.model.gameModel";
if not game_id or string.len(game_id)==0 then
	gameModel:g_save(ssdb_info);
else
	gameModel:update();
end


DBUtil.keepDbAlive(db);
