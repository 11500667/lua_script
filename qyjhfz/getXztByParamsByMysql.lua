--[[
根据条件获取协作体列表[mysql版]
@Author  chenxg
@Date    2015-06-03
--]]

local say = ngx.say
local quote = ngx.quote_sql_str
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
--在哪个页面检索协作体1:门户协作体首页 2：个人中心我的协作体
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

--加码
function encodeURI(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end

--通过mysql直接查询表开始==============================
--根据学科过滤
local subjectPamas = ""
if subject_id ~= "-1" and subject_id ~= "undefined" then
	subjectPamas = " and subject_id="..subject_id
end
--检索范围：全部，我参与的，我创建的
local scopePamas = ""
if page_type == "2" then--个人中心
	if scope == "1" then --全部
		--判断是否是大学区负责人[2015.06.12添加]
		local dxq_sql = "select d.dxq_id from t_qyjh_dxq d where b_delete=0 and b_use=1 and person_id = "..person_id
		local has_result, err, errno, sqlstate = db:query(dxq_sql);
		if not has_result then
			ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
			return;
		end
		if #has_result >= 1 then
			scopePamas = " and (dxq_id in("..dxq_sql.."))"
		else
			local query_sql = "select xzt_id from t_qyjh_xzt_tea where b_use=1 and tea_id="..person_id
			scopePamas = " and (xzt_id in("..query_sql..") or createueer_id = "..person_id..")"
		end
		
	
	elseif scope == "2" then --我是带头人
		scopePamas = " and person_id="..person_id
	else--我是参与人
		local xztPamas = ""
		local query_sql = "select distinct xzt_id from t_qyjh_xzt_tea where b_use=1 and tea_id="..person_id
		xztPamas = " and xzt_id in("..query_sql..")"
		scopePamas = " and person_id !="..person_id..xztPamas
	end
end


if page_type == "3" then--统计
	--判断是否是大学区负责人[2015.06.12添加]
	local dxq_sql = "select d.dxq_id from t_qyjh_dxq d where b_delete=0 and b_use=1 and person_id = "..person_id
	local has_result, err, errno, sqlstate = db:query(dxq_sql);
	if not has_result then
		ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
		return;
	end
	if #has_result >= 1 then
		scopePamas = " and (dxq_id in("..dxq_sql.."))"
	else
		local query_sql = "select xzt_id from t_qyjh_xzt_tea where b_use=1 and tea_id="..person_id
		scopePamas = " and (xzt_id in("..query_sql..") or createueer_id = "..person_id..")"
	end
end


if keyword=="nil" then
	keyword = ""
else  --如果搜索关键字不为空就把传过来的base64进行编码转成真实的内容
	if #keyword~=0 then
		keyword = ngx.decode_base64(keyword)..""
	else
		keyword = ""
	end
end


local countSql = "select count(1) as xztsum from t_qyjh_xzt where (xzt_name like "..quote("%"..keyword.."%").." or person_name like "..quote("%"..keyword.."%")..") and b_delete=0 and qyjh_id="..qyjh_id..subjectPamas..scopePamas;
local countresults, err, errno, sqlstate = db:query(countSql);
    --ngx.log(ngx.ERR, "cxg_log===countsql===>"..countSql.."<====countsql");
if not countresults then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
    return;
end
local totalRow = tonumber(countresults[1]["xztsum"])
local totalPage = math.floor((totalRow + pageSize - 1) / pageSize)
returnjson.totalPage = totalPage
returnjson.totalRow = totalRow


--设置偏移量
local limitPamas = " order by ts desc limit "..pageSize*pageNumber-pageSize..","..pageSize
local querySql = "select qyjh_id,dxq_id,xzt_id,xzt_name as name,subject_id,person_name,ts,person_id,createUeer_id,description,district_id,city_id,province_id,createtime,logo_url,org_id,js_tj,hd_tj,zy_tj,wk_tj,is_init from t_qyjh_xzt where (xzt_name like "..quote("%"..keyword.."%").." or person_name like "..quote("%"..keyword.."%")..") and b_delete=0 and qyjh_id="..qyjh_id..subjectPamas..scopePamas..limitPamas;
local xzt_result, err, errno, sqlstate = db:query(querySql);
	--ngx.log(ngx.ERR, "cxg_log==querySql===>"..querySql.."<====querySql");
if not xzt_result then
	--ngx.log(ngx.ERR, "countsql===>"..countSql.."<====countsql");
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	return;
end
--通过mysql直接查询表结束==============================
local xzt_id = "0"
for i=1,#xzt_result,1 do
	xzt_id = xzt_result[i]["xzt_id"]..","..xzt_id
end
local zy_sql = "select xzt_id,count(distinct obj_id_int) as zy_tj from t_base_publish where b_delete=0 and pub_type=3 and xzt_id in("..xzt_id..") group by xzt_id"
local wk_sql = "select xzt_id,count(distinct obj_id_int) as wk_tj from t_base_publish where b_delete=0 and pub_type=3 and obj_type=5 and xzt_id in("..xzt_id..") group by xzt_id"
local zy_result, err, errno, sqlstate = db:query(zy_sql);
local wk_result, err, errno, sqlstate = db:query(wk_sql);
if not zy_result then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	return;
end

local list1 = {}

local person_ids = {}
local personids = "-1"
for i=1,#xzt_result,1 do
	table.insert(person_ids, xzt_result[i]["person_id"])
	personids = personids..","..xzt_result[i]["person_id"]
	local temp = {}
	temp.qyjh_id = xzt_result[i]["qyjh_id"]
	temp.dxq_id = xzt_result[i]["dxq_id"]
	temp.xzt_id = xzt_result[i]["xzt_id"]
	temp.name = xzt_result[i]["name"]
	temp.person_id = xzt_result[i]["person_id"]
	temp.person_name = "未知"--xzt_result[i]["person_name"]
	temp.description = xzt_result[i]["description"]
	temp.district_id = xzt_result[i]["district_id"]
	temp.city_id = xzt_result[i]["city_id"]
	temp.province_id = xzt_result[i]["province_id"]
	temp.createtime = xzt_result[i]["createtime"]
	temp.logo_url = xzt_result[i]["logo_url"]
	temp.b_use = xzt_result[i]["b_use"]
	temp.createUeer_id = xzt_result[i]["createUeer_id"]
	temp.subject_id = xzt_result[i]["subject_id"]
	temp.b_delete = xzt_result[i]["b_delete"]
	temp.org_id = xzt_result[i]["org_id"]
	temp.js_tj = xzt_result[i]["js_tj"]
	temp.hd_tj = xzt_result[i]["hd_tj"]
	temp.is_init = xzt_result[i]["is_init"]
	temp.zy_tj = 0
	temp.wk_tj = 0
	for j=1,#zy_result,1 do
		if temp.xzt_id == zy_result[j]["xzt_id"] then
			temp.zy_tj = zy_result[j]["zy_tj"]
			break
		end
	end
	for j=1,#wk_result,1 do
		if temp.xzt_id == wk_result[j]["xzt_id"] then
			temp.wk_tj = wk_result[j]["wk_tj"]
			break
		end
	end
	local ssname
	local res_person = ngx.location.capture("/dsideal_yy/dzsb/getSubjectStageById?subject_id="..xzt_result[i]["subject_id"])
	if res_person.status == 200 then
		ssname = cjson.decode(res_person.body)
	else
		say("{\"success\":false,\"info\":\"查询失败！\"}")
		return
	end
	
	temp.subject_name=ssname.stage_name..ssname.subject_name

	list1[#list1+1] = temp
end



if #person_ids>0 then
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
			if tostring(list1[i].person_id) == tostring(personlist.list[j].personID) then
			--ngx.log(ngx.ERR, "cxg_log =====>"..list1[i].person_id.."**"..personlist.list[j].personID.."<====querySql");
				list1[i].person_name = personlist.list[j].personName
				break
			end
		end
	end
end
--获取协作体下的教师ID列表结束

returnjson.list = list1
returnjson.success = true
returnjson.pageNumber = pageNumber
returnjson.pageSize = pageSize
say(cjson.encode(returnjson))


--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0,v_pool_size)
