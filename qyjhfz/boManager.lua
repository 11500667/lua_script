--[[
判断当前用户是否为大学区或者协作体管理员
@Author  chenxg
@Date    2015-03-02
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
cjson.encode_empty_table_as_object(false);

--获得get请求参数
local person_id = ngx.var.arg_person_id
--1：大学区2：协作体
local page_type = ngx.var.arg_page_type
local path_id = ngx.var.arg_path_id
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
local xztList = {}
local returnjson ={}
returnjson.success = true

if not page_type then
	--判断是否是大学区管理员，是则返回所管理的大学区列表
	--local dxqs = ssdb:zrrange("qyjh_manager_dxqs_"..person_id,0,20)
	--用户管理的大学区
	local ismanager = ssdb:hget("qyjh_manager_dxqs",person_id)
	--用户在某个大学区是带头人
	local dxqdtr = ssdb:hget("qyjh_dtr_dxq",person_id)
	
	if string.len(ismanager[1])>1 then
		returnjson.isDxqManager = true
		local dxqids = Split(ismanager[1],",")
		for i=2,#dxqids-1,1 do
			local dxq = ssdb:hget("qyjh_dxq",dxqids[i])
			local t = cjson.decode(dxq[1])
			dxqList[#dxqList+1] = t
		end
		if dxqdtr[1] ~= "" then
			if string.find(ismanager[1],dxqdtr[1]) == nil then
				local dxq = ssdb:hget("qyjh_dxq",dxqdtr[1])
				local t = cjson.decode(dxq[1])
				dxqList[#dxqList+1] = t
			end
		end
	else
		if dxqdtr[1] ~= "" then
			local dxq = ssdb:hget("qyjh_dxq",dxqdtr[1])
			local t = cjson.decode(dxq[1])
			dxqList[#dxqList+1] = t
		else
			returnjson.isDxqManager = false
		end
	end
	returnjson.dxqList = dxqList
	--判断是否是协作体管理员，是则返回所管理的协作体列表
	local isdtr = ssdb:hget("qyjh_dtr_dxq",person_id)
	if string.len(isdtr[1])>0 then
		returnjson.isXztManager = true
		returnjson.dxq_id = isdtr[1]
		local xzts = ssdb:hget("qyjh_manager_xzts",person_id)
		if string.len(xzts[1])>1 then
			local xztids = Split(xzts[1],",")
			for i=2,#xztids-1,1 do
				local xzt = ssdb:hget("qyjh_xzt",xztids[i])
				local t = cjson.decode(xzt[1])
				xztList[#xztList+1] = t
			end
		end
	else
		returnjson.isXztManager = false
	end
	returnjson.xztList = xztList
else
	if page_type == "1" then--传入大学区ID，判断该用户的身份
		--判断是否为大学区管理员
		local dxqmanager = ssdb:hget("qyjh_dxq_manager",path_id)
		if dxqmanager and dxqmanager[1] == person_id then
			returnjson.isDxqManager = true
		else
			returnjson.isDxqManager = false
		end
		--判断是否为协作体带头人
		local alldtrs = ssdb:hget("qyjh_dxq_dtrs",path_id)
		if string.find(alldtrs[1],person_id) ~= nil then
			returnjson.isXztManager = true
		else
			returnjson.isXztManager = false
		end	
	elseif page_type == "2" then--判断是否为协作体管理员
		local xztgtr = ssdb:hget("qyjh_xzt_manager",path_id)
		if xztgtr and xztgtr[1]== person_id then
			returnjson.isXztManager = true
		else
			returnjson.isXztManager = false
		end
	end
end
if returnjson.isXztManager then
	local cookie_identity_id = tostring(ngx.var.cookie_identity_id)
	local sheng = cache:hget("person_"..person_id.."_"..cookie_identity_id,"sheng")
	local shi = cache:hget("person_"..person_id.."_"..cookie_identity_id,"shi")
	local qu = cache:hget("person_"..person_id.."_"..cookie_identity_id,"qu")
	local xiao = cache:hget("person_"..person_id.."_"..cookie_identity_id,"xiao")
	returnjson.sheng = sheng
	returnjson.shi = shi
	returnjson.qu = qu
	returnjson.xiao = xiao
end
--return
say(cjson.encode(returnjson))

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
cache:set_keepalive(0, v_pool_size)