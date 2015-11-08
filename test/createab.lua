--[[
开通区域均衡
@Author  chenxg
@Date    2015-01-08
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
local region_id = args["region_id"]
local name = "name"--args["name"]
local description = "description"--args["description"]
local logo_url = "logo_url"--args["logo_url"]
local level = "level"--args["level"]

--判断参数是否为空
if not region_id or string.len(region_id) == 0 
  or not name or string.len(name) == 0 
  or not description or string.len(description) == 0 
  or not logo_url or string.len(logo_url) == 0 
  or not level or string.len(level) == 0 then
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
local b, err = ssdb:hexists("qyjh_open", region_id)
if not b then 
	say("{\"success\":false,\"info\":\""..err.."\"}")
	return
end
if b[1] == "1" then
	say("{\"success\":false,\"info\":\"已经开通！\"}")
	return
end

--base64
description = ngx.encode_base64(description)
name = ngx.encode_base64(name)

--取id
local qyjh_id = region_id;--ssdb:incr("workroom_pk")

--(1)地区工作室
local region = {}
region.qyjh_id = qyjh_id[1]
region.b_use = "1"

local ok, err = ssdb:hset("qyjh_open", region_id, cjson.encode(region))
if not ok then
   say("{\"success\":false,\"info\":\""..err.."\"}")
   return
end

--工作室
local qyjh = {}
qyjh.id = ab_id[1]
qyjh.region_id = region_id
qyjh.name = name
qyjh.description = description
qyjh.logo_url = logo_url

local ok, err = ssdb:hset("qyjh_qyjhs", qyjh_id[1], cjson.encode(qyjh))
if not ok then
   say("{\"success\":false,\"info\":\""..err.."\"}")
   return
end

--工作室最新
local ts = os.date("%Y%m%d%H%M%S")
ssdb:zset("qyjh_"..level.."_w_new", qyjh_id[1], ts)

--return
say("{\"success\":true,\"qyjh_id\":\""..qyjh_id[1].."\",\"name\":\""..name.."\",\"b_use\":\""..region.b_use.."\",\"info\":\"开通成功！\"}")

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
