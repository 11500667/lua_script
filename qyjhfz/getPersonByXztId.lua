--[[
根据协作体ID获取教师列表
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
local pageSize = ngx.var.arg_pageSize
local pageNumber = ngx.var.arg_pageNumber


--判断参数是否为空
if not xzt_id or string.len(xzt_id) == 0 
	or not pageSize or string.len(pageSize) == 0 
	or not pageNumber or string.len(pageNumber) == 0
   then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end
pageSize = tonumber(pageSize)
pageNumber = tonumber(pageNumber)
--创建ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local hteaids = ssdb:hget("qyjh_xzt_teas",xzt_id)
local res = Split(hteaids[1],",")

if #res <= 2 then
	local returnjson = {}
	returnjson.list = ""
	returnjson.success = "true"
	returnjson.totalRow = 0
	returnjson.totalPage = 0
	returnjson.pageNumber = pageNumber
	returnjson.pageSize = pageSize
	say(cjson.encode(returnjson))
	return
end

local totalRow = #res-2--t_totalRow
local totalPage = math.floor((totalRow + pageSize - 1) / pageSize)
if pageNumber > totalPage then
	pageNumber = totalPage
end
local offset = pageSize*pageNumber-pageSize+2
local limit = pageSize*pageNumber+1
if limit > totalRow then
	limit = totalRow+1
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

local teaids = {}
for i=offset,limit,1 do
	table.insert(teaids, res[i])
end
--获取person_id详情, 调用java接口
local personlist
local res_person = ngx.location.capture("/getTeaDetailInfo", {
	args = { person_id = table.concat(teaids,",") }
})
if res_person.status == 200 then
	personlist = cjson.decode(res_person.body)
else
	say("{\"success\":false,\"info\":\"查询失败！\"}")
	return
end
--合并list1和personlist
--[[for i=1,#list1 do
		for j=1,#personlist do
			if list1[i].person_id == tostring(personlist[j].person_id) then
				list1[i].person_name = personlist[j].person_name
				break
			end
		end
	end]]
--获取大学区下的教师ID列表结束
local returnjson = {}
returnjson.list = personlist
returnjson.success = "true"
returnjson.totalRow = totalRow
returnjson.totalPage = totalPage
returnjson.pageNumber = pageNumber
returnjson.pageSize = pageSize
say(cjson.encode(returnjson))


--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
