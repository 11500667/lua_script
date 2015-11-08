--[[
根据当前用户ID,大学区ID获取用户在该大学区下所管理的和所属于的协作体列表
用于个人中心，在大学区页面显示协作体列表
@Author  chenxg
@Date    2015-01-29
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

--判断request类型, 获得请求参数
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
--参数 
local pageInfo = getTotalPageAndOffSet(16,2,3)
say(pageInfo[1])
--创建ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
