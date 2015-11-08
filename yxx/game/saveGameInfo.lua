--[[
保存游戏
@Author 周枫
@date 2015-4-7
--]]
local say = ngx.say
--引用模块
local ssdblib = require "resty.ssdb"
local mysql = require "resty.mysql"

--创建ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
--创建mysql连接
local db = mysql:new()
db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024*1024
}
--获取前台传过来的参数
local request_method = ngx.var.request_method
local args,err
if request_method == "GET" then
        args,err = ngx.req.get_uri_args()
else
        ngx.req.read_body()
        args,err = ngx.req.get_post_args()
end

if not args then
        say("{\"success\":false,\"info\":\""..err.."\"}")
         return
end
-- 游戏名称
local game_name=args["game_name"]
if not game_name or string.len(game_name)==0 then
	say("{\"success\":false,\"info\":\"游戏名称不能为空！\"}")
    return
end
--学科
local subject_id=args["subject_id"]
if not subject_id or string.len(subject_id)==0 then
	say("{\"success\":false,\"info\":\"学科不能为空！\"}")
    return
end
--关卡数
local game_total=args["game_total"]
if not game_total or string.len(game_total)==0 then
	say("{\"success\":false,\"info\":\"关卡数不能为空！\"}")
    return
end
--游戏规则
local game_rule=args["game_rule"]
if not game_rule  then
	say("{\"success\":false,\"info\":\"游戏规则不能为空！\"}")
    return
end
--游戏版本
local game_verson=args["game_verson"]
if not game_verson  then
	say("{\"success\":false,\"info\":\"游戏版本不能为空！\"}")
    return
end
--游戏制作人
local game_author=args["game_author"]
if not game_author  then
	say("{\"success\":false,\"info\":\"游戏制作人不能为空！\"}")
    return
end
--游戏制作时间
local game_made_time=args["game_made_time"]
if not game_made_time  then
	say("{\"success\":false,\"info\":\"游戏制作时间不能为空！\"}")
    return
end

--游戏缩略图
local game_thumb=args["game_thumb"]
if not game_thumb  then
	say("{\"success\":false,\"info\":\"没有游戏缩略图这个参数！\"}")
    return
end
--游戏路径
local game_url=args["game_url"]
if not game_url or string.len(game_url)==0 then
	say("{\"success\":false,\"info\":\"游戏url不能为空！\"}")
    return
end
--游戏类型
local game_format=args["game_format"]
if not game_format or string.len(game_format)==0 then
	say("{\"success\":false,\"info\":\"游戏类型不能为空！\"}")
    return
end
--获取当前上传人
local game_upload_author = ngx.var.cookie_background_person_id

if not game_upload_author or string.len(game_upload_author)==0  then
	say("{\"success\":false,\"info\":\"cookie中没有person_id这个参数！\"}")
    return
end

local gameids=ssdb:incr("yxx_gameid_pk")
local gameid=gameids[1]

--获取时间
local t=ngx.now()
local n=os.date("%Y%m%d%H%M%S").."00"..string.sub(t,12,14)
n=n..string.rep("0",19-string.len(n))
local ts=n
local update_ts=n
local game_upload_time=os.date("%Y-%m-%d %H:%M:%S")
--保存到ssdb中
ssdb:multi_hset("yxx_game_info_"..gameid,"GAME_ID",gameid,"GAME_NAME",game_name,"SUBJECT_ID",subject_id,"GAME_TOTAL",game_total,"UPDATE_TS",update_ts,"GAME_RULE",game_rule,"GAME_VERSON",game_verson,"GAME_AUTHOR",game_author,"GAME_MADE_TIME",game_made_time,"GAME_UPLOAD_TIME",game_upload_time,"GAME_UPLOAD_AUTHOR",game_upload_author,"IS_DELETE","1","GAME_FORMAT",game_format,"GAME_THUMB",game_thumb,"GAME_URL",game_url)
--保存到数据库中

--游戏信息插入mysql数据库
	local res, err, errno, sqlstate =db:query("insert into t_game_info (GAME_ID,GAME_NAME,GAME_TOTAL,GAME_RULE,GAME_VERSON,GAME_AUTHOR,GAME_MADE_TIME,GAME_UPLOAD_TIME,GAME_UPLOAD_AUTHOR,SUBJECT_ID,IS_DELETE,GAME_FORMAT,GAME_THUMB,GAME_URL,UPDATE_TS) values ("..gameid..",\'"..game_name.."\',\'"..game_total.."\',\'"..game_rule.."\',\'"..game_verson.."\',\'"..game_author.."\',"..game_made_time..",\'"..game_upload_time.."\',"..game_upload_author..",\'"..subject_id.."\',"..1..","..game_format..","..game_thumb..","..game_url..","..update_ts..")")
	if not res then
    		ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
    		return
	end
	--游戏信息更新mysql数据库
--    local res, err, errno, sqlstate =db:query("update t_game_info set GAME_NAME=\'"..gamename.."\',UPDATE_TS=\'"..update_ts.."\',GAME_CATEGORY_ID="..categoryid..",GAME_APPLICATIONRANGE_ID="..applicationrangeid..",GAME_DESCRIBE=\'"..describe.."\',GAME_THUMB=\'"..thumb.."\',GAME_URL=\'"..url.."\',GAME_TYPE=\'"..gametype.."\',GAME_LEVELS="..levels..",GAME_VERSION=\'"..version.."\',GAME_CREATOR=\'"..gamecreator.."\' where ID="..zy_id)
--    if not res then
--        ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
--        return
--    end
say("{\"success\":true,\"info\":\"保存成功\",\"gameid\":\""..gameid.."\"}")
ssdb:set_keepalive(0,v_pool_size)
db:set_keepalive(0,v_pool_size)







