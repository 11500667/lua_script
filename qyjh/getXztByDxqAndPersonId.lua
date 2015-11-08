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
local qyjh_id = args["qyjh_id"]
local dxq_id = args["dxq_id"]
local person_id = args["person_id"]
local limit = args["limit"]

--判断参数是否为空
if not qyjh_id or string.len(qyjh_id) == 0 
	or not dxq_id or string.len(dxq_id) == 0
	or not person_id or string.len(person_id) == 0
	or not limit or string.len(limit) == 0
   then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end
limit = tonumber(limit)

--创建ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
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
local returnjson = {}

--根据person_id判断是否为该大学区的负责人
local dxqid = ssdb:hget("qyjh_manager_dxqs", person_id)
--获取大学区下的协作体
local dxzts = ssdb:hget("qyjh_dxq_xzts",dxq_id)
local dres = Split(dxzts[1],",")

local xztids = {}
if dxqid[1] and string.len(dxqid[1])>0  then --当前用户是该大学区负责人
	if dxqid[1] == dxq_id then
		returnjson.isdxqmanager = 1
		if limit >= #dres-1 then
			limit = #dres-1
		end
		if #dres>2 then
			for i=2,limit,1 do 
				table.insert(xztids, dres[i])
			end
		end
	end
else -- 当前用户是普通人
	returnjson.isdxqmanager = 0
	--获取用户管理的协作体
	local xzts, err = ssdb:hget("qyjh_manager_xzts", person_id)
	if not xzts then
	   say("{\"success\":false,\"info\":\""..err.."\"}")
	   return
	end
	--获取用户所属的协作体
	local ownxzts, err = ssdb:hget("qyjh_tea_xzts", person_id)
	if not ownxzts then
	   say("{\"success\":false,\"info\":\""..err.."\"}")
	   return
	end
	--local uxzts = Split(xzts[1]..ownxzts[1],",")
	local uxzts = ""
	--****************
	
	if ownxzts[1] and string.len(ownxzts[1])>=2 then
		if string.find(ownxzts[1],xzts[1]) ~= nil then
			uxzts = Split(ownxzts[1],",")
		else
			uxzts = Split(xzts[1]..ownxzts[1],",")
		end
	else
		uxzts = Split(","..xzts[1]..",",",")
	end
	
	--****************

	if #dres>2 and  #uxzts>2 then
	
		if limit >= #uxzts-1 then
			limit = #uxzts-1
		end
		for i=2,limit,1 do
			for j=2,#dres-1,1 do
				if uxzts[i] == dres[j] then 
					table.insert(xztids, uxzts[i])
					break
				end
			end
		end
	else
		if limit >= #uxzts-1 then
			limit = #uxzts-1
		end
		for i=2,limit,1 do
 
			table.insert(xztids, uxzts[i])
		end
	end
end


--获取协作体下的教师ID列表开始
local list1 = {}
--协作体列表
local xztlist, err = ssdb:multi_hget('qyjh_xzt',unpack(xztids));
for i=2,#xztlist,2 do
	if cjson.decode(xztlist[i]).b_delete ~=1 then
		local t = cjson.decode(xztlist[i])
		list1[#list1+1] = t
	end	
end

--获取大学区下的教师ID列表结束

returnjson.list = list1
returnjson.success = "true"

say(cjson.encode(returnjson))

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
