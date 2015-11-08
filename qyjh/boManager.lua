--[[
判断当前用户是否为大学区或者协作体管理员
@Author  chenxg
@Date    2015-01-22
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"


--获得get请求参数
local person_id = ngx.var.arg_person_id
local path_id = ngx.var.arg_path_id
if not person_id or string.len(person_id) == 0
	then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

--创建ssdb连接
local ssdb = ssdblib:new()
ssdb:set_timeout(3000) --不设置也可以, 默认2000
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--判断region_id是否存在, 存在则返回qyjh_id,b_use,b_open,name
local bDxqM, err = ssdb:hget("qyjh_manager_dxqs", person_id)
if not bDxqM then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local bXztM, err = ssdb:hget("qyjh_manager_xzts", person_id)
if not bXztM then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
--say(#ab) --返回1, 即使键值不存在table里也存了一个空串"", 类型为string, cjson.encode()后也是string, 所以可以用string.len()
local returnjson ={}
returnjson.success = true
if string.len(bDxqM[1]) == 0 or bDxqM[1] == path_id then
	returnjson.isDxqManager = false
else
	returnjson.isDxqManager = true
end
if string.len(bXztM[1]) == 0 or bXztM[1] == path_id then
	returnjson.isXztManager = false
else
	returnjson.isXztManager = true
end

--return
say(cjson.encode(returnjson))

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)