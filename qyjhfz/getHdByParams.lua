--[[
根据条件获取活动列表
@Author  chenxg
@Date    2015-02-08
--]]

local say = ngx.say
--引用模块
local cjson = require "cjson"
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
--local qyjh_id = args["qyjh_id"]
--加载数据的页面，1：区域均衡门户 2：大学区首页 3:协作体首页4:活动首页5：个人中心
local page_type = args["page_type"]
--要加载哪个分类的数据：0：所有，1：培训学习，2：专家讲座，3：集体备课，4：教学观摩，5：交流研讨
local hd_type = args["hd_type"]
--传入的区域均衡Id或者大学区ID或者协作体ID
local path_id = args["path_id"]
local subject_id = args["subject_id"]
--控制显示的数量
local pageSize = args["pageSize"]
local pageNumber = args["pageNumber"]
--登录用户的ID
local person_id = args["person_id"]
--带头人姓名、协作体名称
local keyword = tostring(args["searchTeam"])
--检索范围：-1、全部 1、我组织的 2、我参与的
local scope = ngx.var.arg_Scope

--判断参数是否为空
if not page_type or string.len(page_type) == 0 
	--or not qyjh_id or string.len(qyjh_id) == 0 
	or not hd_type or string.len(hd_type) == 0    
	or not pageSize or string.len(pageSize) == 0 
	or not pageNumber or string.len(pageNumber) == 0 
  then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end
pageSize = tonumber(pageSize)
pageNumber = tonumber(pageNumber)
returnjson.pageSize = pageSize
returnjson.pageNumber = pageNumber
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

--计算offset和limit
local offset = pageSize*pageNumber-pageSize
local limit = pageSize
--设置查询最大匹配的数量
local str_maxmatches = "10000"
--基本查询条件
local searchPamas ="filter=b_delete,0;"
--学科查询条件
local subjectPamas = ""
--活动类型查询条件
local hdlxPamas = ""

--排序条件
local sortPamas ="attr_desc:startts;"

--检索范围：全部，我参与的，我创建的
local scopePamas = ""
--关键字
if keyword=="nil" then
	keyword = ""
else  --如果搜索关键字不为空就把传过来的base64进行编码转成真实的内容
	if #keyword~=0 then
		keyword = ngx.decode_base64(keyword)..";"
	else
		keyword = ""
	end
end
local dxqidPamas = ""
local statrPamas = ""

local hdlist = {}
local hhd  = {}
local hdids = {}
local sphinxStartSql = "SELECT SQL_NO_CACHE id FROM t_qyjh_hd_sphinxse WHERE query=\'filter=b_delete,0;"
local sphinxEndSql = "\';SHOW ENGINE SPHINX  STATUS;"
--门户页不展示未开始的
if page_type == "1" or page_type == "2" or page_type == "3" then
	--展示未开时的活动
	local ts1 = os.date("%Y%m%d%H%M%S")
	statrPamas = "range=startts,19900101010101,"..ts1..";"
end
if page_type == "1" or page_type == "4" then --区域均衡页面加载
	--[[hhd = ssdb:zrrange("qyjh_qyjh_hds_"..path_id,offset,limit)
	for i=1,#hhd,2 do
		table.insert(hdids,hhd[i])
	end]]
	dxqidPamas = "filter=qyjh_id,"..path_id..";"
end
--[[elseif page_type == "2" then --大学区页面加载
	hhd = ssdb:zrrange("qyjh_dxq_hds_"..path_id,offset,limit)
	for i=1,#hhd,2 do
		table.insert(hdids,hhd[i])
	end]]
--elseif page_type == "3" then --协作体页面加载

if page_type == "2" then
	dxqidPamas = "filter=dxq_id,"..path_id..";"
end
if page_type == "3" then
	dxqidPamas = "filter=xzt_id,"..path_id..";"
end
if subject_id ~= "-1" and subject_id ~= nil then
	subjectPamas = "filter=subject_id,"..subject_id..";"
end
if hd_type ~= "-1" then
	hdlxPamas = "filter=lx_id,"..hd_type..";"
end
if page_type == "5" then 
	if scope == "-1" then --全部
		local xzts = ssdb:hget("qyjh_tea_xzts",person_id)
		if xzts[1] and string.len(xzts[1])>2 then
			scopePamas = "filter=xzt_id"..string.sub(xzts[1],0,string.len(xzts[1])-1)..";"
		else
			scopePamas = "filter=xzt_id,-1;"
		end
	elseif scope == "1" then --我组织的
		scopePamas = "filter=person_id,"..person_id..";"
	else--我参与的
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
end

local sphinxSql = sphinxStartSql..keyword..searchPamas..subjectPamas..scopePamas..hdlxPamas..dxqidPamas..statrPamas.."sort="..sortPamas.."maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit..sphinxEndSql
ngx.log(ngx.ERR,"cxg_log********===>"..sphinxSql.."<====*********")
local hd_res = db:query(sphinxSql)
local res1 = db:read_result()
local _,s_str = string.find(res1[1]["Status"],"found: ")
local e_str = string.find(res1[1]["Status"],", time:")
local totalRow = string.sub(res1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)
returnjson.totalRow = totalRow
returnjson.totalPage = totalPage
for i=1,#hd_res do
	local hd_id = hd_res[i]["id"]
	table.insert(hdids, hd_id)
end


local hd = ssdb:multi_hget('qyjh_hd',unpack(hdids));
for i=2,#hd,2 do
	local t = cjson.decode(hd[i])
	local ts = os.date("%Y%m%d%H%M")
	local sdate = t.start_date
	--ngx.log(ngx.ERR,"sdate===========>"..sdate..type(sdate), "====> ", hd[i]);
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
	
	local ssname
	local res_person = ngx.location.capture("/dsideal_yy/dzsb/getSubjectStageById?subject_id="..t.subject_id)
	if res_person.status == 200 then
		ssname = cjson.decode(res_person.body)
	else
		say("{\"success\":false,\"info\":\"查询失败！\"}")
		return
	end

	t.subject_name=ssname.stage_name..ssname.subject_name
	--评论数
	local plCount = ssdb:zget("qyjh_hd_pls",t.hd_id)
	if plCount[1] == "" then
		plCount[1] = 0
	end
	t.plCount = plCount[1]
	--资源数
	local resCount = ssdb:zget("qyjh_hd_uploadcount",t.hd_id)
	if resCount[1] == "" then
		resCount[1] = 0
	end
	t.resCount = resCount[1]
	--参与人数
	t.teaCount = ssdb:hget("qyjh_xzt_tj",t.xzt_id.."_".."js_tj")[1]
	
	hdlist[#hdlist+1] = t
end


returnjson.hd_list = hdlist
returnjson.success = "true"
say(cjson.encode(returnjson))

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0,v_pool_size)
