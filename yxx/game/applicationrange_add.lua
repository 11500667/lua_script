--[[
增加游戏的适用范围
@Author chuzheng
@date 2015-2-13
--]]
local say = ngx.say

--引用模块
local ssdblib = require "resty.ssdb"

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


local applicationrangename = args["applicationrangename"]

if not applicationrangename or string.len(applicationrangename) == 0  then
        say("{\"success\":false,\"info\":\"参数错误！\"}")
        return
end

--创建ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--自增获取categoryid

local applicationrange_id=ssdb:incr("applicationrangename_pk")

ssdb:hset("yxx_game_applicationrange",applicationrange_id[1] ,applicationrangename)

say("{\"success\":true,\"info\":\"保存成功\"}")

ssdb:set_keepalive(0,v_pool_size)
