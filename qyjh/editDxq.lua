--[[
保存编辑后的大学区
@Author  chenxg
@Date    2015-01-19
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
local dxq_id = args["dxq_id"]
local name = args["name"]
local description = args["description"]
local logo_url = args["logo_url"]
local person_id = args["person_id"]

--判断参数是否为空
if not dxq_id or string.len(dxq_id) == 0  
  or not name or string.len(name) == 0 
  or not description or string.len(description) == 0 
  or not logo_url or string.len(logo_url) == 0
  or not person_id or string.len(person_id) == 0 
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

--base64
--description = ngx.decode_base64(description)
--name = ngx.decode_base64(name)

--存储详细信息
local hdxq = ssdb:hget("qyjh_dxq",dxq_id)
local dxq = cjson.decode(hdxq[1])
--删除原管理员
ssdb:hdel("qyjh_manager_dxqs", dxq.person_id)
dxq.name = name
dxq.description = description
dxq.logo_url = logo_url
dxq.person_id = person_id

local ok, err = ssdb:hset("qyjh_dxq", dxq_id, cjson.encode(dxq))
if not ok then
   say("{\"success\":false,\"info\":\""..err.."\"}")
   return
end
--设置大学区和管理员的对应关系
ssdb:hset("qyjh_dxq_manager", dxq_id, person_id)
ssdb:hset("qyjh_manager_dxqs", person_id, dxq_id)
--return
say("{\"success\":true,\"dxq_id\":\""..dxq_id.."\",\"name\":\""..name.."\",\"info\":\"大学区信息修改成功！\"}")

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
