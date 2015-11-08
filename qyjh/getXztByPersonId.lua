--[[
根据当前用户ID获取用户所管理的和所属于的协作体列表
@Author  chenxg
@Date    2015-01-24
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
cjson.encode_empty_table_as_object(false);
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
local person_id = args["person_id"]

--判断参数是否为空
if not person_id or string.len(person_id) == 0
   then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
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
--创建ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
--****
--如果该用户是大学区负责人，则先获取他所管理大学区下的所有协作体
local dqxs, err = ssdb:hget("qyjh_manager_dxqs", person_id)
if not dqxs then
   say("{\"success\":false,\"info\":\""..err.."\"}")
   return
end
local newres=""
local mxzts = {}
if dqxs[1] or string.len(dqxs[1])>=1 then
	--
	mxzts = ssdb:hget("qyjh_dxq_xzts",dqxs[1])
	--local xztres = Split(xzts[1],",")
	--say("大学区负责人创建的大学区"..mxzts[1])
end
 
--****


--获取用户管理的协作体
local xzts, err = ssdb:hget("qyjh_manager_xzts", person_id)
if not xzts then
   say("{\"success\":false,\"info\":\""..err.."\"}")
   return
end
--say("该用户管理的协作体"..xzts[1])
--获取用户所属的协作体
local ownxzts, err = ssdb:hget("qyjh_tea_xzts", person_id)
if not ownxzts then
   say("{\"success\":false,\"info\":\""..err.."\"}")
   return
end
--say("该用户所属的协作体"..ownxzts[1])
--local res = Split(xzts[1]..ownxzts[1],",")

--***********************
--大学区下创建的协作体
local ishasdxq = false
--所述的协作体
local isownxzt = false
--所管理的协作体
local isxztm = false

if mxzts[1] or mxzts[1] ~= "," then 
	ishasdxq = true
end
if xzts[1] or xzts[1] ~= "" then 
	isxztm = true
end
if ownxzts[1] or ownxzts[1] ~= "," then 
	isownxzt = true
end

if ishasdxq then
	newres = mxzts[1]
	if isxztm then 
		if string.find(mxzts[1],xzts[1]) == nil then
			newres = mxzts[1]..xzts[1]..","
		end	
	end
	if isownxzt then
		local oxzts = Split(ownxzts[1],",")
		for i=2,#oxzts-1,1 do
			if string.find(mxzts[1],oxzts[i]) == nil then
				newres = newres..oxzts[i]..","
			end
		end
	end
else
	if isownxzt then
		if isxztm then 
			if string.find(ownxzts[1],xzts[1]) == nil then
				newres = ownxzts[1]..xzts[1]..","
			end	
		else
			newres = ownxzts[1]
		end
	else
		if isxztm then 
			newres = xzts[1]
		end
	end
end

newres = Split(newres,",")
--***********************


local tids = {}
for i=1,#newres,1 do
	table.insert(tids, newres[i])
	--ngx.log(ngx.ERR, "aaaaownxzts====>"..newres[i].."<====");
end

--获取大学区下的教师ID列表开始
local list1 = {}
--大学区列表
local xztlist, err = ssdb:multi_hget('qyjh_xzt',unpack(tids));
for i=2,#xztlist,2 do
	if cjson.decode(xztlist[i]).b_delete ~=1 and cjson.decode(xztlist[i]).qyjh_id ==qyjh_id then
		local t = cjson.decode(xztlist[i])
		list1[#list1+1] = t
	end
end

--获取大学区下的教师ID列表结束
local returnjson = {}
returnjson.list = list1
returnjson.success = "true"
say(cjson.encode(returnjson))

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
