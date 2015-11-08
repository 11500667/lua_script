--[[
根据条件获取活动列表
@Author  chenxg
@Date    2015-02-08
--]]

local say = ngx.say
--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"
cjson.encode_empty_table_as_object(false);

local returnjson = {}
returnjson.isXztManager = false;
returnjson.isDxqManager = false;

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
--加载数据的页面，1：区域均衡门户 2：大学区首页 3:协作体首页
local page_type = args["page_type"]
--要加载哪个分类的数据：0：所有，1：培训学习，2：专家讲座，3：集体备课，4：教学观摩，5：交流研讨
local hd_type = args["hd_type"]
--传入的区域均衡Id或者大学区ID或者协作体ID
local path_id = args["path_id"]
--控制显示的数量
local pageSize = args["pageSize"]
local pageNumber = args["pageNumber"]
--登录用户的ID
local person_id = args["person_id"]

--判断参数是否为空
if not page_type or string.len(page_type) == 0 
	or not hd_type or string.len(hd_type) == 0 
	or not path_id or string.len(path_id) == 0 
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


local hdlist = {}
local hhd  = {}
local hdids = {}
local totalHds={}
if page_type == "1" then --区域均衡页面加载
	if hd_type == "0" then --检索全部的活动
		totalHds = ssdb:zrrange("qyjh_qyjh_hds_"..path_id,0,100000)
		local pageInfo = getTotalPageAndOffSet((#totalHds/2),pageSize,pageNumber)
		hhd = ssdb:zrrange("qyjh_qyjh_hds_"..path_id,pageInfo[1],pageInfo[2])
	else--按照活动分类检索活动
		totalHds = ssdb:zrrange("qyjh_qyjh_hds_"..path_id.."_"..hd_type,0,100000)
		local pageInfo = getTotalPageAndOffSet((#totalHds/2),pageSize,pageNumber)
		hhd = ssdb:zrrange("qyjh_qyjh_hds_"..path_id.."_"..hd_type,pageInfo[1],pageInfo[2])
	end
elseif page_type == "2" then --大学区页面加载
	if person_id  then
		local dxqs, err = ssdb:hget("qyjh_manager_dxqs", person_id)
		
		if string.len(dxqs[1]) > 0 then
			if dxqs[1] == path_id then
				returnjson.isDxqManager = true
			end
		end
	end

	if hd_type == "0" then --检索全部的活动
		totalHds = ssdb:zrrange("qyjh_dxq_hds_"..path_id,0,100000)
		local pageInfo = getTotalPageAndOffSet((#totalHds/2),pageSize,pageNumber)
		hhd = ssdb:zrrange("qyjh_dxq_hds_"..path_id,pageInfo[1],pageInfo[2])
	else--按照活动分类检索活动
		totalHds = ssdb:zrrange("qyjh_dxq_hds_"..path_id.."_"..hd_type,0,100000)
		local pageInfo = getTotalPageAndOffSet((#totalHds/2),pageSize,pageNumber)
		hhd = ssdb:zrrange("qyjh_dxq_hds_"..path_id.."_"..hd_type,pageInfo[1],pageInfo[2])
	end
elseif page_type == "3" then --协作体页面加载
	if person_id  then
		local xzts, err = ssdb:hget("qyjh_manager_xzts", person_id)
		
		if string.len(xzts[1]) > 0 then
			if xzts[1] == path_id then
				returnjson.isXztManager = true
			end
		end
	end
	if hd_type == "0" then --检索全部的活动
		totalHds = ssdb:zrrange("qyjh_xzt_hds_"..path_id,0,100000)
		local pageInfo = getTotalPageAndOffSet((#totalHds/2),pageSize,pageNumber)
		hhd = ssdb:zrrange("qyjh_xzt_hds_"..path_id,pageInfo[1],pageInfo[2])
	else--按照活动分类检索活动
		totalHds = ssdb:zrrange("qyjh_xzt_hds_"..path_id.."_"..hd_type,0,100000)
		local pageInfo = getTotalPageAndOffSet((#totalHds/2),pageSize,pageNumber)
		hhd = ssdb:zrrange("qyjh_xzt_hds_"..path_id.."_"..hd_type,pageInfo[1],pageInfo[2])
	end
end
if hhd or #hhd>=2 then
	for i=1,#hhd,2 do
		table.insert(hdids,hhd[i])
	end
	local hd = ssdb:multi_hget('qyjh_hd',unpack(hdids));
	for i=2,#hd,2 do
		local t = cjson.decode(hd[i])
		local ts = os.date("%Y%m%d%H%M")
		local sdate = t.start_date
		ngx.log(ngx.ERR,"sdate===========>"..sdate..type(sdate), "====> ", hd[i]);
		sdate = string.gsub(sdate,"-","")
		sdate = string.gsub(sdate,":","")
		sdate = string.gsub(sdate," ","")
		local stonum = sdate--string.gsub(string.gsub(string.gsub(sdate,"-",""),":","")," ","")
		
		local edate = t.end_date
		edate = (string.gsub(edate,"-",""))
		edate = (string.gsub(edate,":",""))
		edate = (string.gsub(edate," ",""))
		local etonum = edate--string.gsub(string.gsub(string.gsub(edate,"-",""),":","")," ","")
		if stonum <= ts and etonum >= ts then
			t.statu = "2"--进行中
		elseif stonum > ts then
			t.statu = "1"--未开时
		elseif etonum < ts then
			t.statu = "3"--已结束
		end
		hdlist[#hdlist+1] = t
	end
end

returnjson.hd_list = hdlist
returnjson.success = "true"
say(cjson.encode(returnjson))


--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
