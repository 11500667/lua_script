--[[
保存游戏
@Author chuzheng
@date 2015-2-13
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
local gamename=args["gamename"]
if not gamename or string.len(gamename)==0 then
	say("{\"success\":false,\"info\":\"游戏名称不能为空！\"}")
    return
end
--学科
local subjectid=args["subjectid"]
if not subjectid or string.len(subjectid)==0 then
	say("{\"success\":false,\"info\":\"学科不能为空！\"}")
    return
end
--游戏分类
local categoryid=args["categoryid"]
if not categoryid or string.len(categoryid)==0 then
	say("{\"success\":false,\"info\":\"游戏分类不能为空！\"}")
    return
end
--游戏适用范围
local applicationrangeid=args["applicationrangeid"]
if not applicationrangeid or string.len(applicationrangeid)==0 then
	say("{\"success\":false,\"info\":\"游戏适用范围不能为空！\"}")
    return
end
--游戏描述
local describe=args["describe"]
if not describe  then
	say("{\"success\":false,\"info\":\"没有游戏描述这个参数！\"}")
    return
end
--游戏缩略图
local thumb=args["thumb"]
if not thumb  then
	say("{\"success\":false,\"info\":\"没有游戏缩略图这个参数！\"}")
    return
end
--游戏路径
local url=args["url"]
if not url or string.len(url)==0 then
	say("{\"success\":false,\"info\":\"游戏url不能为空！\"}")
    return
end
--游戏类型
local gametype=args["gametype"]
if not gametype or string.len(gametype)==0 then
	say("{\"success\":false,\"info\":\"游戏类型不能为空！\"}")
    return
end
--游戏等级
local levels=args["levels"]
if not levels  then
	say("{\"success\":false,\"info\":\"没有游戏等级这个参数！\"}")
    return
end
--游戏版本
local version=args["version"]
if not version  then
	say("{\"success\":false,\"info\":\"没有游戏版本这个参数！\"}")
    return
end
--游戏创建者
local gamecreator=args["gamecreator"]
if not gamecreator  then
	say("{\"success\":false,\"info\":\"没有游戏作者这个参数！\"}")
    return
end
--获取当前上传人
local uploadauthor = ngx.var.cookie_background_person_id

if not uploadauthor or string.len(uploadauthor)==0  then
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
local create_time=os.date("%Y-%m-%d %H:%M:%S")
--保存到ssdb中
ssdb:multi_hset("yxx_game_info_"..gameid,"ID",gameid,"GAME_NAME",gamename,"SUBJECT_ID",subjectid,"CREATE_TIME",create_time,"TS",ts,"UPDATE_TS",update_ts,"GAME_CATEGORY_ID",categoryid,"GAME_APPLICATIONRANGE_ID",applicationrangeid,"GAME_DESCRIBE",describe,"GAME_THUMB",thumb,"GAME_URL",url,"GAME_TYPE",gametype,"GAME_LEVELS",levels,"GAME_VERSION",version,"GAME_CREATOR",gamecreator,"GAME_UPLOADAUTHOR",uploadauthor,"PLAYCOUNT","0")
--保存到数据库中

--游戏信息插入mysql数据库
	local res, err, errno, sqlstate =db:query("insert into t_game_info (ID,GAME_NAME,SUBJECT_ID,CREATE_TIME,TS,UPDATE_TS,GAME_CATEGORY_ID,GAME_APPLICATIONRANGE_ID,GAME_DESCRIBE,GAME_THUMB,GAME_URL,GAME_TYPE,GAME_LEVELS,GAME_VERSION,GAME_CREATOR,GAME_UPLOADAUTHOR) values ("..gameid..",\'"..gamename.."\',\'"..subjectid.."\',\'"..create_time.."\',\'"..ts.."\',\'"..update_ts.."\',"..categoryid..",\'"..applicationrangeid.."\',"..describe..",\'"..thumb.."\',"..url..","..gametype..","..levels..","..version..","..gamecreator..","..uploadauthor..")")
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







