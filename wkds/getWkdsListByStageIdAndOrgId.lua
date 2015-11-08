--[[
根据学段id和学校id获得获得微课列表,包括所有的微课
@Author   feiliming
@Date     2014-11-20
--]]

--判断request类型
local request_method = ngx.var.request_method
local args,err
if request_method == "GET" then
	args,err = ngx.req.get_uri_args()
else
	ngx.req.read_body()
	args,err = ngx.req.get_post_args() 
end
if not args then 
	ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
	return
end

--获得请求参数
local stage_id = args["stage_id"]
local org_id = args["org_id"]
local sort_type = args["sort_type"]
local sort_order = args["sort_order"]
local pageSize = args["pageSize"]
local pageNumber = args["pageNumber"]

if not stage_id or string.len(stage_id) == 0 or not org_id or string.len(org_id) == 0 or not sort_type or string.len(sort_type) == 0 
   or not sort_order or string.len(sort_order) == 0 or not pageSize or string.len(pageSize) == 0 or not pageNumber or string.len(pageNumber) == 0 then
	ngx.say("{\"success\":\"false\",\"info\":\"参数错误！\"}")
	return
end

if sort_type == "1" then
	sort_type = "w.teacher_name_py "
elseif sort_type == "2" then 
	sort_type = "w.play_count "
elseif sort_type == "3" then 
	sort_type = "w.score_total "
elseif sort_type == "4" then 
	sort_type = "w.update_ts "
elseif sort_type == "5" then 
	sort_type = "w.download_count "
end

if sort_order == "1" then
	sort_order = "ASC "
else
	sort_order = "DESC "
end

if pageNumber == "0" then
    pageNumber = "1"
end

--连接mysql
local mysql = require "resty.mysql"
local db, err = mysql:new()
if not db then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
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
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--查询数据
local offset = pageSize*pageNumber - pageSize
local limit = pageSize

local sqldata,sqlcount
if org_id == "0" then
	sqldata = "SELECT w.id, w.wkds_id_int, w.wkds_name, w.teacher_name, w.teacher_name_py, "..
	"w.person_id, w.identity_id, w.create_time, w.study_instr,w.design_instr,w.practice_instr, w.content_json, "..
	"w.scheme_id, w.structure_id, w.subject_id, w.play_count,w.download_count,w.score_count,w.score_total,w.score_average, "..
	"p.person_name, s.subject_name FROM t_base_person_subject ps, t_base_person p, t_dm_subject s, t_wkds_info w "..
	"WHERE ps.person_id = p.person_id AND ps.subject_id = s.subject_id AND p.PERSON_ID = w.PERSON_ID "..
	"AND w.isdraft = 0 AND w.b_delete = 0 AND w.type = 2 AND w.type_id = 6 AND s.stage_id = "..stage_id.." ORDER BY "..sort_type..sort_order.." LIMIT "..offset..","..limit
	sqlcount = "SELECT COUNT(*) AS totalcount FROM t_base_person_subject ps, t_base_person p, t_dm_subject s, t_wkds_info w "..
	"WHERE ps.person_id = p.person_id AND ps.subject_id = s.subject_id AND p.PERSON_ID = w.PERSON_ID AND w.isdraft = 0 "..
	"AND w.b_delete = 0 AND w.type = 2 AND w.type_id = 6 AND s.stage_id = "..stage_id
else 
	sqldata = "SELECT w.id, w.wkds_id_int, w.wkds_name, w.teacher_name, w.teacher_name_py, "..
	"w.person_id, w.identity_id, w.create_time, w.study_instr,w.design_instr,w.practice_instr, w.content_json, "..
	"w.scheme_id, w.structure_id, w.subject_id, w.play_count,w.download_count,w.score_count,w.score_total,w.score_average, "..
	"p.person_name,p.qp,o.org_id,o.org_name FROM "..
	"t_base_org_stage os, t_base_organization o, t_base_person p, t_base_person_subject ps, t_dm_subject s, t_wkds_info w "..
	"WHERE os.org_id = o.ORG_ID AND o.ORG_ID = p.org_id AND ps.person_id = p.person_id AND ps.subject_id = s.subject_id "..
	"AND os.stage_id = s.STAGE_ID AND p.person_id = w.person_id AND w.isdraft = 0 AND w.b_delete = 0 AND w.type = 2 AND w.type_id = 6 "..
	"AND os.stage_id = "..stage_id.." AND o.ORG_ID = "..org_id.." ORDER BY "..sort_type..sort_order.." LIMIT "..offset..","..limit
	sqlcount = "SELECT COUNT(*) AS totalcount FROM "..
	"t_base_org_stage os, t_base_organization o, t_base_person p, t_base_person_subject ps, t_dm_subject s, t_wkds_info w "..
	"WHERE os.org_id = o.ORG_ID AND o.ORG_ID = p.org_id AND ps.person_id = p.person_id AND ps.subject_id = s.subject_id "..
	"AND os.stage_id = s.STAGE_ID AND p.person_id = w.person_id AND w.isdraft = 0 AND w.b_delete = 0 AND w.type = 2 AND w.type_id = 6 "..
	"AND os.stage_id = "..stage_id.." AND o.ORG_ID = "..org_id
end

local resultdata, err = db:query(sqldata)
local resultcount, err = db:query(sqlcount)
if not resultdata or not resultcount then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--分页信息
local totalRow = resultcount[1].totalcount
local totalPage = math.floor((totalRow + pageSize - 1) / pageSize)

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--引入cjson
local cjson = require "cjson"

--找第一个视频的缩略图
for i,v in ipairs(resultdata) do
	local content_json = tostring(resultdata[i].content_json)
    content_json = ngx.decode_base64(content_json)
    --转成table类型
    content_json = cjson.decode(content_json)
	
	local thumb_id
	if table.getn(content_json.sp_list) ~= 0 then
		local resource_info_id = content_json.sp_list[1].id
		if resource_info_id ~= ngx.null then
			local thumbid = ssdb_db:multi_hget("resource_"..resource_info_id, "thumb_id")
			thumb_id = thumbid[2]
		end                              
	else
		thumb_id = "E6648460-4FFD-E626-1C14-6FBF9F94A23C"
	end
	resultdata[i].thumb_id = thumb_id
end

--返回值
local returnjson = {}
returnjson.success = "true"
returnjson.totalRow = totalRow
returnjson.totalPage = tostring(totalPage)
returnjson.pageNumber = pageNumber
returnjson.pageSize = pageSize
returnjson.list = resultdata

ngx.say(cjson.encode(returnjson))

--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0,v_pool_size)
--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size);