--[[
编辑工作室
@Author  feiliming
@Date    2014-11-27
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

local region_id = args["region_id"]
local workroom_id = args["workroom_id"]
local name = ngx.escape_uri(args["name"])
local description = ngx.escape_uri(args["description"])
local logo_url = ngx.escape_uri(args["logo_url"])
if not region_id or string.len(region_id) == 0 
    or not workroom_id or string.len(workroom_id) == 0 
    or not name or string.len(name) == 0 
    or not description or string.len(description) == 0 
    or not logo_url or string.len(logo_url) == 0 then
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

--判断是否已经开通
local b, err = ssdb:hexists("workroom_region", region_id)
if not b then 
	say("{\"success\":false,\"info\":\""..err.."\"}")
	return
end
if b[1] == "0" then
	say("{\"success\":false,\"info\":\"尚未开通！\"}")
	return
end

--base64
--description = ngx.encode_base64(description)
--name = ngx.encode_base64(name)

--更新description
local wkrm, err = ssdb:hget("workroom_workrooms", workroom_id)
if not wkrm then
    say("{\"success\":false,\"info\":\"尚未开通！\"}")
    return
end
wkrm = cjson.decode(wkrm[1])
wkrm.description = description
wkrm.name = name
wkrm.logo_url = logo_url

local ok, err = ssdb:hset("workroom_workrooms", workroom_id, cjson.encode(wkrm))
if not ok then
   say("{\"success\":false,\"info\":\""..err.."\"}")
   return
end

--return
say("{\"success\":true,\"info\":\"保存成功！\"}")

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)