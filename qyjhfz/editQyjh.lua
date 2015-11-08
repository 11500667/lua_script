--[[
保存编辑后的区域均衡信息
@Author  chenxg
@Date    2015-03-01
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
local name = args["name"]
local description = args["description"]
local logo_url = args["logo_url"]

--判断参数是否为空
if not region_id or string.len(region_id) == 0 
  or not name or string.len(name) == 0 
  or not description or string.len(description) == 0 
  or not logo_url or string.len(logo_url) == 0 
  then
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

--base64
--description = ngx.decode_base64(description)
--name = ngx.decode_base64(name)

--取id
--local qyjh_id = region_id;--ssdb:incr("workroom_pk")


--存储详细信息
local qyjh = ssdb:hget("qyjh_qyjhs",region_id)
local temp = cjson.decode(qyjh[1])
temp.name = name
temp.description = description
temp.logo_url = logo_url

local ok, err = ssdb:hset("qyjh_qyjhs", region_id, cjson.encode(temp))
if not ok then
   say("{\"success\":false,\"info\":\""..err.."\"}")
   return
end

--return
say("{\"success\":true,\"qyjh_id\":\""..region_id.."\",\"name\":\""..name.."\",\"b_use\":1,\"info\":\"编辑成功！\"}")

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
