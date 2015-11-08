--[[
个人中心：大学区管理员登录，获取所属和所管理的大学区
@Author  chenxg
@Date    2015-03-19
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
cjson.encode_empty_table_as_object(false);
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
local pageSize = ngx.var.arg_pageSize
local pageNumber = ngx.var.arg_pageNumber

--判断参数是否为空
if not person_id or string.len(person_id) == 0
	or not qyjh_id or string.len(qyjh_id) == 0
	or not pageSize or string.len(pageSize) == 0 
	or not pageNumber or string.len(pageNumber) == 0
   then
    say("{\"success\":false,\"info\":\"person_id or qyjh_id or pageSize or pageNumber 参数错误！\"}")
    return
end
pageSize = tonumber(pageSize)
pageNumber = tonumber(pageNumber)
--创建ssdb连接
local ssdblib = require "resty.ssdb"
local ssdb = ssdblib:new()
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
local returnjson = {}
returnjson.pageSize = pageSize
returnjson.pageNumber = pageNumber
--获取用户管理的大学区
local dqxs, err = ssdb:hget("qyjh_manager_dxqs", person_id)
if not dqxs then
   say("{\"success\":false,\"info\":\""..err.."\"}")
   return
end
--ngx.log(ngx.ERR,"========>"..dqxs[1].."<===========")

--获取用户所属于的大学区开始
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)

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

--计算检索数据的起始和结束为止
function getTotalPageAndOffSet(totalRow,pageSize,pageNumber)  
	local result = {}
	local totalPage = math.floor((totalRow + pageSize - 1) / pageSize)
	returnjson.totalPage = totalPage
	returnjson.totalRow = totalRow
	if pageNumber > totalPage then
		pageNumber = totalPage
	end
	local offset = pageSize*pageNumber-pageSize+2
	local limit1 = pageSize*pageNumber+2
	if limit1 > totalRow+1 then
		limit1 = totalRow+1
	end
	table.insert(result,offset)
	table.insert(result,limit1)
	return result
end

local schID = cache:hget("person_"..person_id.."_"..cookie_identity_id,"xiao")
--ngx.log(ngx.ERR,"========>"..schID.."<===========")

local owndqxs, err = ssdb:hget("qyjh_org_dxq", schID)
if not owndqxs then
   say("{\"success\":false,\"info\":\""..err.."\"}")
   return
end
local res = ""
if dqxs[1] or string.len(dqxs[1])>=2 then
	if string.find(dqxs[1],owndqxs[1]) ~= nil then
		res = Split(dqxs[1],",")
	elseif owndqxs[1] ~="nil" or string.len(owndqxs[1])>0 then
		local ids = string.gsub(dqxs[1]..owndqxs[1], ",,", ",")
		res = Split(ids,",")
	else
		res = Split(dqxs[1],",")
	end
else
	res = Split(owndqxs[1],",")
end

local tids = {}
local pageInfo = getTotalPageAndOffSet(#res-2,pageSize,pageNumber)

for i=pageInfo[1],pageInfo[2],1 do
	table.insert(tids, res[i])
end

--获取大学区下的教师ID列表开始
local list1 = {}
--大学区列表
local dxqlist, err = ssdb:multi_hget('qyjh_dxq',unpack(tids));
for i=2,#dxqlist,2 do
	local t = cjson.decode(dxqlist[i])
	t.isdxqmanager=false
	if t.person_id == person_id then
		t.isdxqmanager=true
	end

	--****************
	--获取person_id详情, 调用lua接口
	local personlist

	local res_person = ngx.location.capture("/dsideal_yy/person/getPersonNameListByIds?ids="..t.person_id)
	if res_person.status == 200 then
		personlist = cjson.decode(res_person.body)
	else
		say("{\"success\":false,\"info\":\"查询失败！\"}")
		return
	end
	
	t.person_name = personlist.list[1].personName
	--****************
	--获取大学区统计信息开始
	local xzt_tj = ssdb:hget("qyjh_dxq_tj",t.dxq_id.."_xzt_tj")
	local xx_tj = ssdb:hget("qyjh_dxq_tj",t.dxq_id.."_xx_tj")
	local js_tj = ssdb:hget("qyjh_dxq_tj",t.dxq_id.."_js_tj")
	local hd_tj = ssdb:hget("qyjh_dxq_tj",t.dxq_id.."_hd_tj")
	local zy_tj = ssdb:hget("qyjh_dxq_tj",t.dxq_id.."_zy_tj")
	local dtr_tj = ssdb:hget("qyjh_dxq_tj",t.dxq_id.."_dtr_tj")
	t.xzt_tj = xzt_tj[1]
	t.xx_tj = xx_tj[1]
	t.js_tj = js_tj[1]
	t.hd_tj = hd_tj[1]
	t.zy_tj = zy_tj[1]
	t.dtr_tj = dtr_tj[1]
	list1[#list1+1] = t	
end

--获取大学区下的教师ID列表结束

returnjson.list = list1
returnjson.success = "true"
say(cjson.encode(returnjson))

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
-- 将redis连接归还到连接池
cache: set_keepalive(0, v_pool_size)
