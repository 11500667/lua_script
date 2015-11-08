--[[
判断当前用户获取所相关的大学区【管理、属于】
@Author  chenxg
@Date    2015-03-02
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
cjson.encode_empty_table_as_object(false);

--获得get请求参数
local person_id = ngx.var.arg_person_id

if not person_id or string.len(person_id) == 0
	then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

--创建ssdb连接
local ssdblib = require "resty.ssdb"
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
--根据分隔符分割字符串
function Split(str, delim, maxNb)   
	-- Eliminate bad cases...   
	if string.find(str, delim) == nil then  
		return { str }  
	end  
	if maxNb == nil or maxNb < 1 then  
		maxNb = 0    -- No limit   
	end  
	local result = {}
	local pat = "(.-)" .. delim .. "()"   
	local nb = 0  
	local lastPos   
	for part, pos in string.gfind(str, pat) do  
		nb = nb + 1  
		result[nb] = part   
		lastPos = pos   
		if nb == maxNb then break end  
	end  
	-- Handle the last field   
	if nb ~= maxNb then  
		result[nb + 1] = string.sub(str, lastPos)   
	end  
	return result
end

local dxqList = {}

local returnjson ={}
returnjson.success = true

--用户管理的大学区
local ismanager = ssdb:hget("qyjh_manager_dxqs",person_id)
--用户在某个大学区
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)
local schID = cache:hget("person_"..person_id.."_"..cookie_identity_id,"xiao")
local owndqxs = ssdb:hget("qyjh_org_dxq", schID)

--ngx.log(ngx.ERR,"====*****>"..ismanager[1].."*"..owndqxs[1].."<*****====")
if string.len(ismanager[1])>1 then
	local dxqids = Split(ismanager[1],",")
	for i=2,#dxqids-1,1 do
		local dxq = ssdb:hget("qyjh_dxq",dxqids[i])
		local t = cjson.decode(dxq[1])
		dxqList[#dxqList+1] = t
	end
	if owndqxs[1] ~= "" and owndqxs[1] ~= "," then
		if string.find(ismanager[1],owndqxs[1]) == nil then
			owndqxs[1] = string.gsub(owndqxs[1],",","")
			local dxq = ssdb:hget("qyjh_dxq",owndqxs[1])
			local t = cjson.decode(dxq[1])
			dxqList[#dxqList+1] = t
		end
	end
else
	if owndqxs[1] ~= "" and owndqxs[1] ~= "," then
		owndqxs[1] = string.gsub(owndqxs[1],",","")
		local dxq = ssdb:hget("qyjh_dxq",owndqxs[1])
		local t = cjson.decode(dxq[1])
		dxqList[#dxqList+1] = t
	end
end
returnjson.dxqList = dxqList

--return
say(cjson.encode(returnjson))

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
cache:set_keepalive(0, v_pool_size)