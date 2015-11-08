--[[
根据条件获取活动列表[mysql版]
@Author  chenxg
@Date    2015-06-03
--]]

local say = ngx.say
--引用模块
local cjson = require "cjson"
local quote = ngx.quote_sql_str
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
--活动名称
local keyword = tostring(args["searchTeam"])
--检索范围：-1、全部 1、我组织的 2、我参与的
local scope = ngx.var.arg_Scope

--判断参数是否为空
if not page_type or string.len(page_type) == 0 
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

--计算offset和limit
local offset = pageSize*pageNumber-pageSize
local limit = pageSize
--设置查询最大匹配的数量
local str_maxmatches = "10000"

--学科查询条件
local subjectPamas = ""
--活动类型查询条件
local hdlxPamas = ""

--排序条件
local sortPamas ="order by startts desc "

--检索范围：全部，我参与的，我创建的
local scopePamas = ""
--关键字
if keyword=="nil" then
	keyword = ""
else  --如果搜索关键字不为空就把传过来的base64进行编码转成真实的内容
	if #keyword~=0 then
		keyword = ngx.decode_base64(keyword)..""
	else
		keyword = ""
	end
end
local dxqidPamas = ""
local statrPamas = ""
local xzt_result = {}
local hdlist = {}
local hhd  = {}
local base_sql = "select id as mysql_id,qyjh_id,dxq_id,xzt_id,person_id,hd_name as active_name,hd_id,lx_id as hd_type,statu,start_time as start_date,end_time as end_date,create_time as createtime,ts,subject_id,b_delete,startts,description,hd_confid,con_pass,pls_tj from t_qyjh_hd where b_delete=0 and hd_name like "..quote("%"..keyword.."%").." "

local count_sql = "select count(1) as hd_count from t_qyjh_hd where b_delete=0 and hd_name like "..quote("%"..keyword.."%").." "

--门户页不展示未开始的
if page_type == "1" or page_type == "2" or page_type == "3" then
	--展示未开时的活动
	local ts1 = os.date("%Y%m%d%H%M%S")
	statrPamas = " and startts<"..ts1.." "
end
if page_type == "1" or page_type == "4" then --区域均衡页面加载
	dxqidPamas = " and qyjh_id="..path_id.." "
end
if page_type == "2" then
	dxqidPamas = " and dxq_id="..path_id.." "
end
if page_type == "3" then
	dxqidPamas = " and xzt_id="..path_id.." "
end
if subject_id ~= "-1" and subject_id ~= nil then
	subjectPamas = " and subject_id="..subject_id.." "
end
if hd_type ~= "-1" then
	hdlxPamas = " and lx_id="..hd_type.." "
end
if page_type == "5" then 
	if scope == "-1" then --全部
		--判断是否是大学区负责人[2015.06.12添加]
		local dxq_sql = "select d.dxq_id from t_qyjh_dxq d where b_delete=0 and b_use=1 and person_id = "..person_id
		local has_result, err, errno, sqlstate = db:query(dxq_sql);
		if not has_result then
			ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
			return;
		end
		if #has_result>=1 then
			scopePamas = " and (dxq_id in("..dxq_sql.."))"
		else
			local query_sql = "select xzt_id from t_qyjh_xzt_tea where b_use=1 and tea_id="..person_id.." union select xzt_id from t_qyjh_xzt where createueer_id = "..person_id
			scopePamas = " and xzt_id in("..query_sql..")"
		end
	
		--scopePamas = " and xzt_id in (select xzt_id from t_qyjh_xzt_tea where tea_id="..person_id.." and b_use=1) "
	elseif scope == "1" then --我组织的
		scopePamas = " and person_id="..person_id.." "
	else--我参与的
		scopePamas = " and xzt_id in (select xzt_id from t_qyjh_xzt_tea where tea_id="..person_id.." and b_use=1) and person_id !="..person_id.." "
	end
	
	--获取当前用户是哪些协作体的带头人
	local xzt_sql = "select xzt_id from t_qyjh_xzt where person_id="..person_id
	xzt_result = db:query(xzt_sql);
	if not xzt_result then
		ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
		return;
	end

end

local querySql = base_sql..subjectPamas..scopePamas..hdlxPamas..dxqidPamas..statrPamas..sortPamas.." limit "..offset..","..limit
local countSql = count_sql..subjectPamas..scopePamas..hdlxPamas..dxqidPamas..statrPamas

--ngx.log(ngx.ERR,"cxg_log   ********===>"..querySql.."<====*********")
local count_result, err, errno, sqlstate = db:query(countSql);
local result, err, errno, sqlstate = db:query(querySql);
if not result then
	ngx.say("{\"success\":false,\"info\":\"查询协作体数据失败！\"}");
	return;
end
local totalRow = tonumber(count_result[1]["hd_count"])
local totalPage = math.floor((totalRow + pageSize - 1) / pageSize)
returnjson.totalRow = totalRow
returnjson.totalPage = totalPage

--统计资源数量
local hd_id = "0"
local xzt_id = "0"
for i=1,#result,1 do
	hd_id = result[i]["hd_id"]..","..hd_id
	xzt_id = result[i]["xzt_id"]..","..xzt_id
end
local zy_sql = "select hd_id,count(distinct obj_id_int) as zy_tj from t_base_publish where b_delete=0 and pub_type=3 and hd_id in("..hd_id..") group by hd_id"
local zy_result, err, errno, sqlstate = db:query(zy_sql);
if not zy_result then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	return;
end

local tea_count_sql = "select xzt_id,js_tj as teaCount from t_qyjh_xzt where b_use=1 and xzt_id in("..xzt_id..")"
local tea_count_result, err, errno, sqlstate = db:query(tea_count_sql);
if not tea_count_result then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	return;
end


for i=1,#result,1 do
	local temp = {}
	
	temp.isxztmana = false
	temp.hd_id = result[i]["hd_id"]
	temp.xzt_id = result[i]["xzt_id"]
	temp.mysql_id = result[i]["mysql_id"]
	temp.subject_id = result[i]["subject_id"]
	temp.hd_confid = result[i]["hd_confid"]
	temp.active_name = result[i]["active_name"]
	temp.description = result[i]["description"]
	temp.person_id = result[i]["person_id"]
	temp.start_date = result[i]["start_date"]
	temp.end_date = result[i]["end_date"]
	temp.statu=result[i]["statu"]
	temp.con_pass=result[i]["con_pass"]
	temp.createtime = result[i]["createtime"]
	temp.b_delete = result[i]["b_delete"]
	temp.hd_type = tostring(result[i]["hd_type"])
	temp.plCount = result[i]["pls_tj"]
	if #xzt_result >0 then
		for j=1,#xzt_result,1 do
			if temp.xzt_id == xzt_result[j]["xzt_id"] then
				temp.isxztmana = true
				break
			end
		end
	end
	--资源数
	temp.resCount = 0
	for j=1,#zy_result,1 do
		if temp.hd_id == zy_result[j]["hd_id"] then
			temp.resCount = zy_result[j]["zy_tj"]
			break
		end
	end
	--参与人数
	temp.teaCount = 0
	for j=1,#tea_count_result,1 do
		
		if temp.xzt_id == tea_count_result[j]["xzt_id"] then
			temp.teaCount = tea_count_result[j]["teaCount"]
			break
		end
	end
	
	local ts = os.date("%Y%m%d%H%M")
	local sdate = temp.start_date
	--ngx.log(ngx.ERR,"sdate===========>"..sdate..type(sdate), "====> ", hd[i]);
	sdate = string.gsub(sdate,"-","")
	sdate = string.gsub(sdate,":","")
	sdate = string.gsub(sdate," ","")
	local stonum = sdate--string.gsub(string.gsub(string.gsub(sdate,"-",""),":","")," ","")
	
	local edate = temp.end_date
	edate = (string.gsub(edate,"-",""))
	edate = (string.gsub(edate,":",""))
	edate = (string.gsub(edate," ",""))
	local etonum = edate--string.gsub(string.gsub(string.gsub(edate,"-",""),":","")," ","")
	if stonum <= ts and etonum >= ts then
		temp.statu = "2"--进行中
	elseif stonum > ts then
		temp.statu = "1"--未开时
	elseif etonum < ts then
		temp.statu = "3"--已结束
	end
	
	local ssname
	local res_person = ngx.location.capture("/dsideal_yy/dzsb/getSubjectStageById?subject_id="..temp.subject_id)
	if res_person.status == 200 then
		ssname = cjson.decode(res_person.body)
	else
		say("{\"success\":false,\"info\":\"查询失败！\"}")
		return
	end
	temp.subject_name=ssname.stage_name..ssname.subject_name

	hdlist[#hdlist+1] = temp
end


returnjson.hd_list = hdlist
returnjson.success = "true"
say(cjson.encode(returnjson))

--mysql放回连接池
db:set_keepalive(0,v_pool_size)
