--[[
根据协作体ID、学校ID获取教师列表
@Author  chenxg
@Date    2015-01-23
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
local xzt_id = args["xzt_id"]
local org_id = args["org_id"]

--判断参数是否为空
if not xzt_id or string.len(xzt_id) == 0 
	or not org_id or string.len(org_id) == 0
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

--获取学校ID列表
local b, err = ssdb:hget("qyjh_xzt_org_teas",xzt_id.."_"..org_id)
if not b then 
	say("{\"success\":false,\"info\":\""..err.."\"}")
	return
end
--**********************
local teaids ={}
local hteaids = Split(b[1],",")
for i=2,#hteaids-1,1 do
	table.insert(teaids,hteaids[i])
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
--**********************

local returnjson = {}
returnjson.orgIds = teaids
returnjson.success = "true"
say(cjson.encode(returnjson))

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
