--[[
根据条件获取协作体列表
@Author  chenxg
@Date    2015-03-01
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
--在哪个页面检索协作体1:门户协作体首页 2：个人中心我的协作体 3：查询统计页面
local page_type = args["page_type"]
local subject_id = args["subject_id"]
local pageSize = ngx.var.arg_pageSize
local pageNumber = ngx.var.arg_pageNumber
local person_id = ngx.var.arg_person_id
--带头人姓名、协作体名称
local keyword = tostring(args["searchTeam"])
--检索范围：1、全部 2、我是带头人 3、我是参与人
local scope = ngx.var.arg_Scope

local returnjson = {}
--判断参数是否为空
if not qyjh_id or string.len(qyjh_id) == 0 
	or not page_type or string.len(page_type) == 0 
	or not pageSize or string.len(pageSize) == 0 
	or not pageNumber or string.len(pageNumber) == 0
	or not subject_id or string.len(subject_id) == 0
   then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
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
--连接mysql数据库
local mysql = require "resty.mysql"
local db = mysql:new()
db:connect{
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


--*******通过sphinx获取协作体ID开始
--计算offset和limit
local offset = pageSize*pageNumber-pageSize
local limit = pageSize
--设置查询最大匹配的数量
local str_maxmatches = "10000"
--基本查询条件
local searchPamas ="filter=b_delete,0;filter=qyjh_id,"..qyjh_id..";"
--学科查询条件
local subjectPamas = ""
if subject_id ~= "-1" then
	subjectPamas = "filter=subject_id,"..subject_id..";"
end
--排序条件
local sortPamas ="attr_desc:ts;"

--检索范围：全部，我参与的，我创建的
local scopePamas = ""

if page_type == "2" then--个人中心
	if scope == "1" then --全部
		--******
		--用户管理的大学区
		local ismanager = ssdb:hget("qyjh_manager_dxqs",person_id)
		if string.len(ismanager[1])>1 then
			local dxqids = Split(ismanager[1],",")
			for i=2,#dxqids-1,1 do
				scopePamas = scopePamas.." IF(dxq_id="..dxqids[i]..",1,0) OR"
			end
		end
		--****
		local xzts = ssdb:hget("qyjh_tea_xzts",person_id)
		if xzts[1] and string.len(xzts[1])>2 then
			local xztids = Split(xzts[1],",")
			for i=2,#xztids-1,1 do
				scopePamas = scopePamas.." IF(xzt_id="..xztids[i]..",1,0) OR"
			end
			--scopePamas = "filter=xzt_id"..string.sub(xzts[1],0,string.len(xzts[1])-1)..";"
		elseif string.len(ismanager[1])<1 then
			scopePamas = scopePamas .."IF(xzt_id=-1,1,0) OR"
		end
		scopePamas="select=("..string.sub(scopePamas,0,string.len(scopePamas)-3)..") as match_qq;filter= match_qq, 1;"
		
	elseif scope == "2" then --我是带头人
		scopePamas = "filter=person_id,"..person_id..";"
	else--我是参与人
		local xztPamas = ""
		local xzts = ssdb:hget("qyjh_tea_xzts",person_id)
		if xzts[1] and string.len(xzts[1])>2 then
			--say(string.sub(xzts[1],0,string.len(xzts[1])-1))
			xztPamas = "filter=xzt_id"..string.sub(xzts[1],0,string.len(xzts[1])-1)..";"
		else
			xztPamas = "filter=xzt_id,-1;"
		end
		scopePamas = "!filter=person_id,"..person_id..";"..xztPamas
	end
elseif page_type == "3" then--统计
	local ismanager = ssdb:hget("qyjh_manager_dxqs",person_id)
	if string.len(ismanager[1])>1 then
		local dxqids = Split(ismanager[1],",")
		for i=2,#dxqids-1,1 do
			scopePamas = scopePamas.." IF(dxq_id="..dxqids[i]..",1,0) OR"
		end
		scopePamas="select=("..string.sub(scopePamas,0,string.len(scopePamas)-3)..") as match_qq;filter= match_qq, 1;"
	end
end

--base64
--description = ngx.decode_base64(description)
--name = ngx.decode_base64(name)
--ngx.log(ngx.ERR,"********===>"..qyjh_id.."*"..searchTeam.."<====*********")
if keyword=="nil" then
	keyword = ""
else  --如果搜索关键字不为空就把传过来的base64进行编码转成真实的内容
	if #keyword~=0 then
		keyword = ngx.decode_base64(keyword)..";"
	else
		keyword = ""
	end
end


local sphinxSql = "SELECT SQL_NO_CACHE id FROM t_qyjh_xzt_sphinxse WHERE query=\'"..keyword..searchPamas..subjectPamas..scopePamas.."sort="..sortPamas.."maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;"
ngx.log(ngx.ERR,"********===>"..sphinxSql.."<====*********")
local xzt_res = db:query(sphinxSql)

local res1 = db:read_result()
local _,s_str = string.find(res1[1]["Status"],"found: ")
local e_str = string.find(res1[1]["Status"],", time:")
local totalRow = string.sub(res1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)
returnjson.totalRow = totalRow
returnjson.totalPage = totalPage
--***结束

local tids = {}
for i=1,#xzt_res do
	local xzt_id = xzt_res[i]["id"]
	table.insert(tids, xzt_id)
end
--获取协作体下的教师ID列表开始
local list1 = {}
--协作体列表
local xztlist, err = ssdb:multi_hget('qyjh_xzt',unpack(tids));
--协作体下管理员ID列表
--local hpids, err = ssdb:multi_hget('qyjh_xzt_manager',unpack(tids));
local personids = "-1"
for i=2,#xztlist,2 do
	local t = cjson.decode(xztlist[i])
	personids = personids..","..t.person_id
	
	
	local js_tj = ssdb:hget("qyjh_xzt_tj",t.xzt_id.."_js_tj")
	local hd_tj = ssdb:hget("qyjh_xzt_tj",t.xzt_id.."_hd_tj")
	local zy_tj = ssdb:hget("qyjh_xzt_tj",t.xzt_id.."_zy_tj")
	local wk_tj = ssdb:hget("qyjh_xzt_tj",t.xzt_id.."_wk_tj")
	t.js_tj = js_tj[1]
	t.hd_tj = hd_tj[1]
	t.zy_tj = zy_tj[1]
	t.wk_tj = wk_tj[1]
	local ssname
	local res_person = ngx.location.capture("/dsideal_yy/dzsb/getSubjectStageById?subject_id="..t.subject_id)
	if res_person.status == 200 then
		ssname = cjson.decode(res_person.body)
	else
		say("{\"success\":false,\"info\":\"查询失败！\"}")
		return
	end
	
	t.subject_name=ssname.stage_name..ssname.subject_name
	
	
	
	list1[#list1+1] = t
end
if #xztlist>0 then
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
		for j=1,#personlist.list do
			if list1[i].person_id == tostring(personlist.list[j].personID) then
				list1[i].person_name = personlist.list[j].personName
				break
			end
		end
	end
end
--获取协作体下的教师ID列表结束

returnjson.list = list1
returnjson.success = "true"
returnjson.pageNumber = pageNumber
returnjson.pageSize = pageSize
say(cjson.encode(returnjson))


--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0,v_pool_size)
