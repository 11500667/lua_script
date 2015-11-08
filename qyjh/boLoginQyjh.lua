--[[
根据当前用户判断是否可以登录区域均衡，是否可以往区域均衡发布资源
@Author  chenxg
@Date    2015-02-07
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"


--获得get请求参数
--local person_id = ngx.var.arg_person_id
local person_id = ngx.var.arg_person_id
if not person_id or string.len(person_id) == 0 then
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

-- 获取redis链接
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local cookie_identity_id = tostring(ngx.var.cookie_identity_id)
local quid = {}
local sheng = cache:hget("person_"..person_id.."_"..cookie_identity_id,"sheng")
local shi = cache:hget("person_"..person_id.."_"..cookie_identity_id,"shi")
local qu = cache:hget("person_"..person_id.."_"..cookie_identity_id,"qu")
table.insert(quid,sheng)
table.insert(quid,shi)
table.insert(quid,qu)
--判断region_id是否存在, 存在则返回qyjh_id,b_use,b_open,name
local returnjson = {}

for i=1,#quid,1 do
	local qyjh, err = ssdb:hget("qyjh_open", quid[i])
	if not qyjh then
		say("{\"success\":false,\"info\":\""..err.."\"}")
		return
	end
	if string.len(qyjh[1]) == 0 then
		returnjson.loginsuccess = false
		returnjson.dxqsuccess = false
		returnjson.success = false
	else
		local qyjhs = ssdb:hget("qyjh_qyjhs",quid[i])
		local temp = cjson.decode(qyjhs[1])
		if temp.b_use == "0" then
			returnjson.loginsuccess = false
			returnjson.dxqsuccess = false
			returnjson.success = false
		else
			returnjson.success = true
			returnjson.loginsuccess = true
			returnjson.dxqsuccess = false
			returnjson.qyjh_id = quid[i]
			--判断用户是否有所属于的大学区
			local dqxs, err = ssdb:hget("qyjh_manager_dxqs", person_id)
			local schID = cache:hget("person_"..person_id.."_"..cookie_identity_id,"xiao")
			local owndqxs, err = ssdb:hget("qyjh_org_dxq", schID)
			if string.len(owndqxs[1])>=2 or string.len(dqxs[1]) > 0 then
				returnjson.dxqsuccess = true
			end
			break
		end
	end
end

--return
say(cjson.encode(returnjson))

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)