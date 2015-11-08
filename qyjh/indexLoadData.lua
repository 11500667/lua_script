--[[
首页点击加载数据（区域均衡门户/大学区门户下加载大学区、协作体、学校、教师数据）
@Author  chenxg
@Date    2015-01-31
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
local returnjson = {}
--参数 
--加载数据的页面，1：区域均衡门户 2：大学区首页 3:协作体首页
local page_type = args["page_type"]
--要加载哪个栏目的数据：1：大学区，2：协作体，3：学校，4：教师
local data_source = args["data_source"]
--传入的区域均衡Id或者大学区ID
local path_id = args["path_id"]
--控制显示的数量
local limit = args["limit"]

--判断参数是否为空
if not page_type or string.len(page_type) == 0 
	or not data_source or string.len(data_source) == 0 
	or not path_id or string.len(path_id) == 0 
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
if page_type == "1" then--区域均衡首页加载数据
	if data_source == "1" then--大学区数据 
		--根据区域均衡ID获取按照点击量排行的前6个大学区开始
		local tdxqids = ssdb:zrrange("qyjh_dxq_djl_"..path_id,0,limit)
		local dxqids = {}
		local dxqs = {}
		if #tdxqids>=2 then
			for i=1,#tdxqids,2 do
				table.insert(dxqids,tdxqids[i])
			end
			local dxqlist, err = ssdb:multi_hget('qyjh_dxq',unpack(dxqids));
			for i=2,#dxqlist,2 do
				--table.insert(dxqs,dxqlist[i])
				local t = cjson.decode(dxqlist[i])
				dxqs[#dxqs+1] = t
			end
		end
		returnjson.dxq_list = dxqs
		--根据区域均衡ID获取按照点击量排行的前6个大学区结束
	elseif data_source == "2"  then--协作体数据 
		--根据区域均衡ID获取按照点击量排行的前6个协作体开始
		local txztids = ssdb:zrrange("qyjh_qyjh_xzt_djl_"..path_id,0,limit)
		local xztids = {}
		local xzts = {}
		if #txztids>=2 then
			for i=1,#txztids,2 do
				table.insert(xztids,txztids[i])
			end
			local xztlist, err = ssdb:multi_hget('qyjh_xzt',unpack(xztids));
			for i=2,#xztlist,2 do
				--table.insert(xzts,xztlist[i])
				local t = cjson.decode(xztlist[i])
				xzts[#xzts+1] = t
			end
		end
		returnjson.xzt_list = xzts

		--根据区域均衡ID获取按照点击量排行的前6个协作体结束
	elseif data_source == "3"  then--学校数据 
		--根据上传数量获取前N个学校列表开始
		local torgids = ssdb:zrrange("qyjh_qyjh_org_uploadcount_"..path_id,0,limit)
		local orgids = "-1"
		local orgs = {}
		if #torgids>=2 then
			for i=1,#torgids,2 do
				orgids = torgids[i] ..","..orgids
			end
			local res_org = ngx.location.capture("/dsideal_yy/org/getSchoolNameByIds?ids=".. orgids)
			if res_org.status == 200 then
				orgs = (cjson.decode(res_org.body))
			else
				say("{\"success\":false,\"info\":\"查询学校数据失败！\"}")
				--return
			end
			returnjson.org_list = orgs.list
		else
			returnjson.org_list = orgs
		end
		--根据上传数量获取前N个学校列表结束
	elseif data_source == "4"  then--教师数据
		--根据上传数量获取前N个教师列表开始
		local tteaids = ssdb:zrrange("qyjh_qyjh_tea_uploadcount_"..path_id,0,limit)
		local teaids  = "-1"
		local teas = {}
		if #tteaids>=2 then
			for i=1,#tteaids,2 do
				teaids = tteaids[i]..","..teaids
			end
			local res_person = ngx.location.capture("/dsideal_yy/person/getPersonNameListByIds?ids="..teaids)
			ngx.log(ngx.ERR, "aaaaownxzts====>"..teaids.."<====");
			if res_person.status == 200 then
				teas = cjson.decode(res_person.body)
			else
				say("{\"success\":false,\"info\":\"查询教师数据失败！\"}")
				return
			end
			returnjson.tea_list = teas.list
		else
			returnjson.tea_list = teas
		end
		--根据上传数量获取前N个教师列表结束
	end
elseif page_type == "2" then--大学区门户页加载数据
	if data_source == "2" then--大学区下协作体数据
		--根据大学区ID获取按照点击量排行的前6个协作体开始
		local txztids = ssdb:zrrange("qyjh_dxq_xzt_djl_"..path_id,0,limit)
		local xztids = {}
		local xzts = {}
		if #txztids>=2 then
			for i=1,#txztids,2 do
				table.insert(xztids,txztids[i])
			end
			local xztlist, err = ssdb:multi_hget('qyjh_xzt',unpack(xztids));
			for i=2,#xztlist,2 do
				--table.insert(xzts,xztlist[i])
				local t = cjson.decode(xztlist[i])
				xzts[#xzts+1] = t
			end
		end
		returnjson.xzt_list = xzts
		--根据大学区ID获取按照点击量排行的前6个协作体结束
	elseif data_source == "3"  then--学校数据 
		--根据上传数量获取前N个学校列表开始
		local torgids = ssdb:zrrange("qyjh_dxq_org_uploadcount_"..path_id,0,limit)
		local orgids = "-1"
		local orgs = {}
		if #torgids>=2 then
			for i=1,#torgids,2 do
				orgids = torgids[i] ..","..orgids
			end
			local res_org = ngx.location.capture("/dsideal_yy/org/getSchoolNameByIds?ids=".. orgids)
			if res_org.status == 200 then
				orgs = (cjson.decode(res_org.body))
			else
				say("{\"success\":false,\"info\":\"查询学校数据失败！\"}")
				--return
			end
			returnjson.org_list = orgs.list
		else
			returnjson.org_list = orgs
		end
--根据上传数量获取前N个学校列表结束
	elseif data_source == "4"  then--教师数据 
		--根据上传数量获取前N个教师列表开始
		local tteaids = ssdb:zrrange("qyjh_dxq_tea_uploadcount_"..path_id,0,limit)
		local teaids = "-1"
		local teas = {}
		if #tteaids>=2 then
			for i=1,#tteaids,2 do
				teaids = tteaids[i]..","..teaids
			end
			local res_person = ngx.location.capture("/dsideal_yy/person/getPersonNameListByIds?ids="..teaids)
			if res_person.status == 200 then
				teas = cjson.decode(res_person.body)
			else
				say("{\"success\":false,\"info\":\"查询教师数据失败！\"}")
				return
			end
			returnjson.tea_list = teas.list
		else
			returnjson.tea_list = teas
		end
		--根据上传数量获取前N个教师列表结束
	end
else--协作体首页
	if data_source == "4"  then--教师数据 
		--根据上传数量获取前N个教师列表开始
		local tteaids = ssdb:zrrange("qyjh_xzt_tea_uploadcount_"..path_id,0,limit)
		local teaids = "-1"
		local teas = {}
		if #tteaids>=2 then
			for i=1,#tteaids,2 do
				teaids = tteaids[i]..","..teaids
			end
			local res_person = ngx.location.capture("/dsideal_yy/person/getPersonNameListByIds?ids="..teaids)
			if res_person.status == 200 then
				teas = cjson.decode(res_person.body)
			else
				say("{\"success\":false,\"info\":\"查询教师数据失败！\"}")
				return
			end
			returnjson.tea_list = teas.list
		else
			returnjson.tea_list = teas
		end
		--根据上传数量获取前N个教师列表结束
	end
end

returnjson.success = "true"

say(cjson.encode(returnjson))
--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)