--[[
根据区域均衡ID获取大学区列表
@Author  chenxg
@Date    2015-03-01
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"
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
local pageSize = ngx.var.arg_pageSize
local pageNumber = ngx.var.arg_pageNumber
--page_type[1：前台2：后台]
local page_type = ngx.var.arg_page_type


--判断参数是否为空
if not qyjh_id or string.len(qyjh_id) == 0 
	or not pageSize or string.len(pageSize) == 0 
	or not pageNumber or string.len(pageNumber) == 0
	or not page_type or string.len(page_type) == 0
   then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end
pageSize = tonumber(pageSize)
pageNumber = tonumber(pageNumber)

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

--判断是否已经开通
local b, err = ssdb:hexists("qyjh_open", qyjh_id)
if not b then 
	say("{\"success\":false,\"info\":\""..err.."\"}")
	return
end
local returnjson = {}
local list1 = {}
--*****
local tids  = {}
local totalDxqs={}
--计算检索数据的起始和结束为止
function getTotalPageAndOffSet(totalRow,pageSize,pageNumber)   
	local result = {}
	local totalPage = math.floor((totalRow + pageSize - 1) / pageSize)
	returnjson.totalPage = totalPage
	returnjson.totalRow = totalRow
	if pageNumber > totalPage then
		pageNumber = totalPage
	end
	local offset = pageSize*pageNumber-pageSize
	local limit = pageSize*pageNumber
	if limit > totalRow then
		limit = totalRow
	end
	table.insert(result,offset)
	table.insert(result,limit)
	return result
end
totalDxqs = ssdb:zrrange("qyjh_qyjh_dxqs_"..qyjh_id,0,500)
local pageInfo = getTotalPageAndOffSet((#totalDxqs/2),pageSize,pageNumber)
tids = ssdb:zrrange("qyjh_qyjh_dxqs_"..qyjh_id,pageInfo[1],pageInfo[2])
--*****	
	--获取大学区下的教师ID列表开始
	--大学区列表
	local dxqlist, err = ssdb:multi_hget('qyjh_dxq',unpack(tids));
	--大学区下管理员ID列表
	local hpids, err = ssdb:multi_hget('qyjh_dxq_manager',unpack(tids));
	local personids = "-1"
	for i=2,#hpids,2 do
		personids = personids..","..hpids[i]
		local t = cjson.decode(dxqlist[i])
		if page_type == "1" then -- 前台
			local xx_tj = ssdb:hget("qyjh_dxq_tj",t.dxq_id.."_".."xx_tj")
			local xzt_tj = ssdb:hget("qyjh_dxq_tj",t.dxq_id.."_".."xzt_tj")
			local dtsc = ssdb:hget("qyjh_dxq_tj",t.dxq_id.."_dtr_tj")
			--[[local dtrs = ssdb:hget("qyjh_dxq_dtrs",t.dxq_id)
			local dtsc=0
			if string.len(dtrs[1])>2 then 
				dtsc = #Split(dtrs[1],",")
			end]]
			t.orgCount=xx_tj[1]
			t.xztCount=xzt_tj[1]
			t.dtrCount=dtsc[1]
		else--后台
			local b, err = ssdb:hgetall("qyjh_dxq_orgs_"..t.dxq_id)
			if not b then 
				say("{\"success\":false,\"info\":\""..err.."\"}")
				return
			end
			local orgIDs = ""
			for i=2,#b,2 do
				if b[i] ~="," then
					orgIDs = b[i] .. orgIDs
				end
			end
			orgIDs = string.gsub(orgIDs, ",,", ",")
			if string.len(orgIDs)>2 then
				t.hasOrg=true
			else
				t.hasOrg=false
			end
		end
		list1[#list1+1] = t
	end

	--获取person_id详情, 调用lua接口
	local personlist

	local res_person = ngx.location.capture("/dsideal_yy/person/getPersonNameListByIds?ids="..personids)
	if res_person.status == 200 then
		personlist = cjson.decode(res_person.body)
	else
		say("{\"success\":false,\"info\":\"查询失败！\"}")
		return
	end
	--合并list1和personlist
	for i=1,#list1 do
		for j=1,#personlist.list do
			if list1[i].person_id == tostring(personlist.list[j].personID) then
				list1[i].person_name = personlist.list[j].personName
				break
			end
		end
	end
	--获取大学区下的教师ID列表结束


returnjson.list = list1
returnjson.success = "true"
returnjson.pageNumber = pageNumber
returnjson.pageSize = pageSize
say(cjson.encode(returnjson))

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
