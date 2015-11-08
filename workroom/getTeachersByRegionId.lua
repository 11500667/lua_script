--[[
根据地区ID获取名师工作室名师列表
@Author  chenxg
@Date    2015-09-08
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"

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
local region_id = args["region_id"]
local stage_id = args["stage_id"]
local subject_id = args["subject_id"]
local pageSize = args["pageSize"]
local pageNumber = args["pageNumber"]

if not region_id or string.len(region_id) == 0 
	or not stage_id or string.len(stage_id) == 0 
	or not subject_id or string.len(subject_id) == 0 
	or not pageSize or string.len(pageSize) == 0 
	or not pageNumber or string.len(pageNumber) == 0 
	  then
		say("{\"success\":false,\"info\":\"region_id or stage_id or subject_id or pageSize or pageNumber 参数错误！\"}")
		return
	end

--获取mysql数据库连接
local mysql = require "resty.mysql";
local db, err = mysql : new();
if not db then 
	ngx.log(ngx.ERR, err);
	return;
end
db:set_timeout(3000) -- 1 sec

local ok, err, errno, sqlstate = db:connect{
	host = v_mysql_ip,
	port = v_mysql_port,
	database = v_mysql_database,
	user = v_mysql_user,
	password = v_mysql_password,
	max_packet_size = 1024 * 1024 }

if not ok then
	ngx.say("{\"success\":\"false\",\"info\":\"连接数据库失败\"}")
	return
end

--创建ssdb连接
local ssdblib = require "resty.ssdb"
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--判断是否已经开通
local wkrm, err = ssdb:hget("workroom_region", region_id)
if not wkrm then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
if string.len(wkrm[1]) == 0 then
	say("{\"success\":false,\"info\":\"改地区尚未开通名师工作室！\"}")
	return
end

--更新
local region = cjson.decode(wkrm[1])
local workroom_id = region.workroom_id


local returnjson = {}
pageSize = tonumber(pageSize)
pageNumber = tonumber(pageNumber)

local limit_sql = "limit "..pageNumber*pageSize-pageSize..","..pageSize..""
local stage_sql = ""
local subject_sql = ""
if stage_id ~= "0" then 
	stage_sql = " and sub.STAGE_ID ="..stage_id..""
end
if subject_id ~= "0" then 
	subject_sql = " and sub.SUBJECT_ID in ("..subject_id..")"
end
local person_Sql = "SELECT p.person_id,p.person_name,p.bureau_id,o.org_name,sta.stage_id,sta.stage_name,sub.subject_id,sub.subject_name,t.pic_url,t.b_top,t.res_count,t.description,t.pic_url as avatar_url,t.level,t.id,count(pu.obj_id_int) as dddd  from t_base_workroom_member t LEFT JOIN t_base_person p on t.leader_id = p.PERSON_ID LEFT JOIN t_base_publish pu on pu.person_id = p.PERSON_ID LEFT JOIN t_base_organization o on o.ORG_ID = p.BUREAU_ID LEFT JOIN t_base_person_subject ps on ps.person_id = p.person_id LEFT JOIN t_dm_subject sub on sub.subject_id = ps.subject_id LEFT JOIN t_dm_stage sta on sub.stage_id = sta.stage_id where t.user_type=1 and wr_id="..workroom_id..subject_sql..stage_sql.." GROUP BY p.person_id order by t.b_top desc,dddd desc ";

local person_count, err, errno, sqlstate = db:query(person_Sql);
local person_list, err, errno, sqlstate = db:query(person_Sql..limit_sql);
	ngx.log(ngx.ERR, "cxg_log =====>"..person_Sql);
if not person_list then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	return;
end

local totalRow = #person_count
local totalPage = math.floor((totalRow + pageSize - 1) / pageSize)

local sch_res_list = {}
for i=1,#person_list do
	local res_list = {}

	res_list.teacher_id = person_list[i].id
	res_list.person_id = person_list[i].person_id
	res_list.person_name = person_list[i].person_name
	res_list.school_id = person_list[i].bureau_id
	res_list.school_name = person_list[i].org_name
	res_list.stage_id = person_list[i].stage_id
	res_list.stage_name = person_list[i].stage_name
	res_list.subject_id = person_list[i].subject_id
	res_list.subject_name = person_list[i].subject_name
	res_list.res_count = person_list[i].dddd
	res_list.description = person_list[i].description
	res_list.avatar_url = person_list[i].avatar_url
	res_list.level = person_list[i].level
	res_list.workroom_id = workroom_id
	sch_res_list[i] = res_list
		
end

returnjson.list = sch_res_list
returnjson.success = true

--新增
returnjson.totalRow = totalRow
returnjson.totalPage = totalPage
returnjson.pageNumber = pageNumber
returnjson.pageSize = pageSize


say(cjson.encode(returnjson))

--mysql放回连接池
db:set_keepalive(0, v_pool_size)
