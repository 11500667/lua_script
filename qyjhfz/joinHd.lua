--[[
根据活动ID进入活动
@Author  chenxg
@Date    2015-02-09
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"
local returnjson={}

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
local hd_id = args["hd_id"]
local person_id = args["person_id"]
local pwd = args["pwd"]


--判断参数是否为空
if not hd_id or string.len(hd_id) == 0 
	or not person_id or string.len(person_id) == 0 
	or not pwd or string.len(pwd) == 0 
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
--获取详细信息
local hd = ssdb:hget("qyjh_hd",hd_id)
local t = cjson.decode(hd[1])
local page_type = t.page_type
local hd_confid = t.hd_confid

local ts = os.date("%Y%m%d%H%M")
local sdate = t.start_date
local edate = t.end_date
local stonum = string.gsub(string.gsub(string.gsub(sdate,"-",""),":","")," ","")
local etonum = string.gsub(string.gsub(string.gsub(edate,"-",""),":","")," ","")
if etonum < ts then
	--say("{\"success\":false,\"info\":\"活动已经结束，不可以进入！\"}")
	returnjson.success = false
	returnjson.info = "活动已经结束，不可以进入！"
    return
else
	local personlist
	local res_person = ngx.location.capture("/dsideal_yy/person/getPersonNameListByIds?ids="..person_id)
	if res_person.status == 200 then
		personlist = cjson.decode(res_person.body)
	else
		--say("{\"success\":false,\"info\":\"获取用户信息失败！\"}")
		returnjson.success = false
		returnjson.info = "获取用户信息失败！"
		return
	end
	local show_name = personlist.list[1].personName
	
	--进入活动
	local res_hd, err = ngx.location.capture("/joinHDForGBT", {
		args = {hd_confid = hd_confid,show_name = show_name,con_pass = pwd}
	})
	if res_hd.status == 200 then
		local conf = Split(res_hd.body,"***")[1]
		local url = Split(res_hd.body,"***")[2]
		returnjson.success = true
		returnjson.conf = conf
		returnjson.url = url
	else
		returnjson.success = false
		returnjson.info = "连接高百特进入活动失败！"
		return	
	end
	
end

say(cjson.encode(returnjson))

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
