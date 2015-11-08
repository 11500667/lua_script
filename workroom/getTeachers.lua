--[[
分页查询工作室下名师
@Author  feiliming
@Date    2014-12-2
--]]

local say = ngx.say
local quote = ngx.quote_sql_str

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

--获得get请求参数
local workroom_id = ngx.var.arg_workroom_id
local pageSize = ngx.var.arg_pageSize
local pageNumber = ngx.var.arg_pageNumber

local stage_id = ngx.var.arg_stage_id
local subject_id = ngx.var.arg_subject_id
local keyword = ngx.unescape_uri(ngx.var.arg_keyword);
--local key_start = ngx.var.arg_key_start
--local score_start = ngx.var.arg_score_start
if not workroom_id or string.len(workroom_id) == 0 
	or not pageSize or string.len(pageSize) == 0 
	or not pageNumber or string.len(pageNumber) == 0 
	then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end
pageSize = tonumber(pageSize)
pageNumber = tonumber(pageNumber)
if pageNumber == 0 then
	pageNumber = 1
end

--创建ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end


-----------------------------------
--获取mysql数据库连接
local mysql = require "resty.mysql";
local db, err = mysql : new();
if not db then 
	ngx.log(ngx.ERR, err);
	return;
end
db:set_timeout(1000) -- 1 sec

local ok, err, errno, sqlstate = db:connect{
	host = v_mysql_ip,
	port = v_mysql_port,
	database = v_mysql_database,
	user = v_mysql_user,
	password = v_mysql_password,
	max_packet_size = 1024 * 1024 }

if not ok then
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}")
	ngx.log(ngx.ERR, "=====> 连接数据库失败!");
	return
end

local limit_sql = "limit "..pageNumber*pageSize-pageSize..","..pageSize..""
local stage_sql = ""
local subject_sql = ""
if stage_id and stage_id~="-1" then
	stage_sql = " and  sta.stage_id= "..stage_id..""
end
if subject_id and subject_id~="-1" then
	subject_sql = " and sub.subject_id = "..subject_id..""
end
ngx.log(ngx.ERR, "cxg_log keyword=====>"..keyword);
if keyword=="nil" then
	keyword = ""
else  --如果搜索关键字不为空就把传过来的base64进行编码转成真实的内容
	if #keyword~=0 then
		keyword = ngx.decode_base64(keyword)..""
	else
		keyword = ""
	end
end


local person_Sql = "SELECT p.person_id,p.person_name,p.bureau_id,o.org_name,sta.stage_id,sta.stage_name,sub.subject_id,sub.subject_name,t.pic_url,t.b_top,t.res_count,t.description,t.pic_url as avatar_url,t.level,t.id from t_base_workroom_member t LEFT JOIN t_base_person p on t.leader_id = p.PERSON_ID LEFT JOIN t_base_organization o on o.ORG_ID = p.BUREAU_ID LEFT JOIN t_base_person_subject ps on ps.person_id = p.person_id LEFT JOIN t_dm_subject sub on sub.subject_id = ps.subject_id LEFT JOIN t_dm_stage sta on sub.stage_id = sta.stage_id where t.user_type=1 and wr_id="..workroom_id.." "..stage_sql..subject_sql.." and (p.person_name like "..quote("%"..keyword.."%").." or o.org_name  like "..quote("%"..keyword.."%")..") order by t.b_top desc,res_count desc ";

--[[local person_Sql = "SELECT p.person_id,p.person_name,p.bureau_id,o.org_name,p.stage_id,p.stage_name,p.subject_id,p.subject_name,t.pic_url,t.b_top,t.res_count,t.description,t.pic_url as avatar_url,t.level,t.id from t_base_workroom_member t LEFT JOIN t_base_person p on t.leader_id = p.PERSON_ID LEFT JOIN t_base_organization o on o.ORG_ID = p.BUREAU_ID  where t.user_type=1 and wr_id="..workroom_id.." order by t.b_top desc,res_count desc ";]]

	--ngx.log(ngx.ERR, "cxg_log =====>"..person_Sql);
local person_count, err, errno, sqlstate = db:query(person_Sql);
local person_list, err, errno, sqlstate = db:query(person_Sql..limit_sql);
if not person_list then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	return;
end

local totalRow = #person_count
local totalPage = math.floor((totalRow + pageSize - 1) / pageSize)

local sch_res_list = {}
for i=1,#person_list do
	local res_list = {}

	res_list.b_top = person_list[i].b_top
	res_list.teacher_id = person_list[i].id
	res_list.person_id = person_list[i].person_id
	res_list.person_name = person_list[i].person_name
	res_list.school_id = person_list[i].bureau_id
	res_list.school_name = person_list[i].org_name
	res_list.stage_id = person_list[i].stage_id
	res_list.stage_name = person_list[i].stage_name
	res_list.subject_id = person_list[i].subject_id
	res_list.subject_name = person_list[i].subject_name
	res_list.res_count = person_list[i].res_count
	res_list.description = person_list[i].description
	res_list.avatar_url = person_list[i].avatar_url
	res_list.level = person_list[i].level
	res_list.workroom_id = workroom_id
	sch_res_list[i] = res_list
		
end

local returnjson = {}
returnjson.list = sch_res_list
returnjson.success = true

returnjson.totalRow = totalRow
returnjson.totalPage = totalPage
returnjson.pageNumber = pageNumber
returnjson.pageSize = pageSize

-----------------------------------



--分页信息
--[[
local t_totalRow = ssdb:zcount("workroom_teachers_sorted_by_name_"..workroom_id, "", "")
local totalRow = t_totalRow[1]
local totalPage = math.floor((totalRow + pageSize - 1) / pageSize)
if pageNumber > totalPage then
	pageNumber = totalPage
end
local offset = pageSize*pageNumber-pageSize
local limit = pageSize

--zscan查名师id,吗的没查到返回ok?
--zscan不能跳页,改成zrange,zrange全表扫描,适合几百条数据以下
--local res, err = ssdb:zscan("workroom_teachers_sorted_by_name_"..workroom_id, key_start, score_start, "", pageSize)
local res, err = ssdb:zrange("workroom_teachers_sorted_by_name_"..workroom_id, offset, limit)
if not res then
	say("{\"success\":false,\"info\":\""..err.."\"}")
	return
end
if res[1] == "ok" then
	local returnjson = {}
	returnjson.success = true
	returnjson.totalRow = 0
	returnjson.totalPage = 0
	returnjson.pageNumber = pageNumber
	returnjson.pageSize = pageSize
	--returnjson.key_start = key_start
	--returnjson.score_start = score_start

	returnjson.list = {}
	cjson.encode_empty_table_as_object(false)
	say(cjson.encode(returnjson))
	return
end

local t_len = #res
local teacherids = {}
for i=1,t_len,2 do
	teacherids[#teacherids+1] = res[i]
	--下次查询使用
	--if i == t_len-1 then
	--	key_start = res[i]
	--	score_start = res[i+1]
	--end
end

--multi_hget查名师详细
local list = {}
local teachers, err = ssdb:multi_hget("workroom_teachers", unpack(teacherids))
local personids = {}
for i=1,#teachers,2 do
	local teacher = cjson.decode(teachers[i+1])
	list[#list+1] = teacher
	table.insert(personids, teacher.person_id)
end
	--获取person_id详情, 调用java接口
local personlist
local res_person = ngx.location.capture("/getTeaDetailInfo", {
	args = { person_id = table.concat(personids,",") }
})
if res_person.status == 200 then
    personlist = cjson.decode(res_person.body)
else
	say("{\"success\":false,\"info\":\"查询失败！\"}")
    return
end
	--合并list和personlist
for i=1,#list do
	for j=1,#personlist do
		if list[i].person_id == tostring(personlist[j].person_id) then
			list[i].person_name = personlist[j].person_name
			list[i].school_id = personlist[j].bureau_id
			list[i].school_name = personlist[j].org_name
			list[i].stage_id = personlist[j].stage_id
			list[i].stage_name = personlist[j].stage_name
			list[i].subject_id = personlist[j].subject_id
			list[i].subject_name = personlist[j].subject_name
			break
		end
	end
end

--返回值
local returnjson = {}
returnjson.success = true
returnjson.totalRow = totalRow
returnjson.totalPage = totalPage
returnjson.pageNumber = pageNumber
returnjson.pageSize = pageSize
--returnjson.key_start = key_start
--returnjson.score_start = score_start
returnjson.list = list
]]
cjson.encode_empty_table_as_object(false)
say(cjson.encode(returnjson))

ssdb:set_keepalive(0,v_pool_size)
