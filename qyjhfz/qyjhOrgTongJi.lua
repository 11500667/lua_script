--[[
大学区负责人学校相关统计
@Author  chenxg
@Date    2015-03-21
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

--当前用户
local person_id = args["person_id"]
local keyword = args["keyword"]
local pageSize = ngx.var.arg_pageSize
local pageNumber = ngx.var.arg_pageNumber

--判断参数是否为空
if not person_id or string.len(person_id) == 0 
	or not pageSize or string.len(pageSize) == 0 
	or not pageNumber or string.len(pageNumber) == 0
	then
    say("{\"success\":false,\"info\":\"person_id or pageSize or pageNumber 参数错误！\"}")
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
local ssdblib = require "resty.ssdb"
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--连接mysql数据库
local mysql = require "resty.mysql"
local mysql_db = mysql:new()
mysql_db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024*1024
}
--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local returnjson = {}
local orgList = {}
local xxCount = 0
--获取当前用户所管理的大学区
local dxqs = ssdb:hget("qyjh_manager_dxqs",person_id)
if string.len(dxqs[1])>1 then
	local dxqids = Split(dxqs[1],",")
	for i=2,#dxqids-1,1 do
		local xx_tj = ssdb:hget("qyjh_dxq_tj",dxqids[i].."_xx_tj")
		xxCount = tonumber(xxCount)+tonumber(xx_tj[1])
	end
	
	pageSize = tonumber(pageSize)
	pageNumber = tonumber(pageNumber)
	
	if keyword=="nil" then
	keyword = ""
	else  --如果搜索关键字不为空就把传过来的base64进行编码转成真实的内容
		if #keyword~=0 then
			keyword = ngx.decode_base64(keyword)
		else
			keyword = ""
		end
	end
	
	--获取协作体数量
	local getXztSql = "select qxt.org_id,count(distinct xzt_id) as xzt_count from t_qyjh_xzt_tea qxt where b_use = 1 and qxt.dxq_id in("..string.sub(dxqs[1],2,string.len(dxqs[1])-1)..") group by org_id";
	--ngx.log(ngx.ERR, "=====> 连接数据库失败!"..getXztSql);
	local xzt_res = mysql_db:query(getXztSql)
	
	--获取学校所属协作体
	local getOrgXztSql = "select qxt.org_id,xzt_id from t_qyjh_xzt_tea qxt where b_use = 1 and qxt.dxq_id in("..string.sub(dxqs[1],2,string.len(dxqs[1])-1)..") group by org_id,xzt_id";
	local org_xzt_res = mysql_db:query(getOrgXztSql)
	
	--获取大学区下的学校
	local getSchSql = "select o.org_id,o.org_name from t_qyjh_dxq_org qdo left join t_base_organization o on qdo.org_id = o.org_id where qdo.b_use = 1 and qdo.dxq_id in("..string.sub(dxqs[1],2,string.len(dxqs[1])-1)..") and o.org_name like '%"..keyword.."%' limit "..pageSize*pageNumber-pageSize..","..pageSize.."";
	local org_res = mysql_db:query(getSchSql)
	local orgs = {}
	for i=1,#org_res do
		local org = {}
		local org_id = org_res[i]["org_id"]
		local org_name = org_res[i]["org_name"]
		org.org_id = org_id
		org.org_name = org_name
		org.xzt_count = 0
		--所属区域
		local dxqid = ssdb:hget("qyjh_org_dxq", org_id)
		local hdxq = ssdb:hget("qyjh_dxq", string.gsub(dxqid[1],",",""))
		org.dxq_name = cjson.decode(hdxq[1]).name
		--协作体个数
		for j=1,#xzt_res do
			local xzt_org_id = xzt_res[j]["org_id"]
			local xzt_count = xzt_res[j]["xzt_count"]
			if org_id == xzt_org_id then
				if xzt_count == "" then
					xzt_count = 0
				end
				org.xzt_count = xzt_count
				break
			end
		end
		--带头人个数
		local hdtrids = ssdb:hget("qyjh_dxq_org_dtrs",string.gsub(dxqid[1],",","").."_"..org_id)
		local dtr_count = 0
		if string.len(hdtrids[1])>2 then
			dtr_count = #Split(hdtrids[1],",")-2
		end
		org.dtr_count = dtr_count
		--教师人数
		local getTeaSql = "SELECT COUNT(1) AS TEACOUNT FROM T_BASE_PERSON P WHERE B_USE=1 and IDENTITY_ID=5 and BUREAU_ID = "..org_id.."";
		--ngx.log(ngx.ERR,"---->"..getTeaSql.."<------")
		local tea_res = mysql_db:query(getTeaSql)
		local tea_count = tea_res[1]["TEACOUNT"]
		org.tea_count = tea_count
		--备课资源
		local zy_count = ssdb:zget("qyjh_org_uploadcount",org_id)
		if zy_count[1] == "" then
			zy_count[1] = 0
		end
		org.zy_count = zy_count[1]
		--协作活动
		local hd_count = 0
		for j=1,#org_xzt_res do
			local xzt_id = org_xzt_res[j]["xzt_id"]
			if org_id == org_xzt_res[j]["org_id"] then
				hd_count = hd_count+ tonumber(ssdb:hget("qyjh_xzt_tj",xzt_id.."_hd_tj")[1])
			end
		end
		org.hd_count = hd_count
		orgList[#orgList+1] = org
	end
	returnjson.pageSize = pageSize
	returnjson.pageNumber = pageNumber
	returnjson.totalRow = xxCount
	local totalPage = math.floor((xxCount+pageSize-1)/pageSize)
	returnjson.totalPage = totalPage
end
returnjson.orgList = orgList

returnjson.success = "true"

say(cjson.encode(returnjson))

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
mysql_db:set_keepalive(0,v_pool_size)