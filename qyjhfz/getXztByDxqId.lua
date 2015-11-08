--[[
根据大学区ID获取协作体列表,用于大学区页面展示
@Author  chenxg
@Date    2015-01-23
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
local dxq_id = args["dxq_id"]
local pageSize = ngx.var.arg_pageSize
local pageNumber = ngx.var.arg_pageNumber


--判断参数是否为空
if not dxq_id or string.len(dxq_id) == 0 
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

local list1 = {}
local xzts = ssdb:zrrange("qyjh_xzt_sort_"..dxq_id,0,2000) 
local pageInfo = getTotalPageAndOffSet((#xzts/2),pageSize,pageNumber)
local hxzt = ssdb:zrrange("qyjh_xzt_sort_"..dxq_id,pageInfo[1],pageInfo[2])
local tids = {}

for i=1,#hxzt,2 do
	table.insert(tids, res[i])
end
--获取协作体下的教师ID列表开始

--协作体列表
local xztlist, err = ssdb:multi_hget('qyjh_xzt',unpack(tids));
--协作体下管理员ID列表
local hpids, err = ssdb:multi_hget('qyjh_xzt_manager',unpack(tids));
local person_ids = {}
local personids = "-1"
for i=2,#hpids,2 do
	table.insert(person_ids, hpids[i])
	personids = personids..","..hpids[i]
	local t = cjson.decode(xztlist[i])
	list1[#list1+1] = t
end

--获取person_id详情, 调用java接口
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
	for j=1,#personlist do
		if list1[i].person_id == tostring(personlist[j].personID) then
			list1[i].person_name = personlist[j].personName
			break
		end
	end
end

--获取协作体下的教师ID列表结束
local returnjson = {}
returnjson.list = list1
returnjson.success = "true"
returnjson.totalRow = totalRow
returnjson.totalPage = totalPage
returnjson.pageNumber = pageNumber
returnjson.pageSize = pageSize
say(cjson.encode(returnjson))


--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
