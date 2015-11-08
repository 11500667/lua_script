--[[
根据学段获取老师列表,按老师微课数排倒序
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
local subject_id = args["subject_id"]
local pageSize = args["pageSize"]
local pageNumber = args["pageNumber"]

if not stage_id or string.len(stage_id) == 0 or not subject_id or string.len(subject_id) == 0 or not pageSize or string.len(pageSize) == 0 or not pageNumber or string.len(pageNumber) == 0 then
	ngx.say("{\"success\":\"false\",\"info\":\"参数错误！\"}")
	return
end

if pageNumber == "0" then
    pageNumber = "1"
end

--subject_id=0不分学科,否则分学科
local subject_id1, subject_id2
if(subject_id == "0") then
    subject_id1 = ""
    subject_id2 = ""
else
    subject_id1 = " AND s.SUBJECT_ID = "..subject_id
    subject_id2 = " AND w.SUBJECT_ID = "..subject_id
end

local offset = pageSize*pageNumber - pageSize
local limit = pageSize

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

--查询数据
--local sqldata = "SELECT p.person_id,p.person_name,s.subject_id,s.subject_name FROM t_base_person_subject ps,t_base_person p,t_dm_subject s WHERE ps.person_id = p.person_id AND ps.subject_id = s.subject_id AND s.stage_id = "..stage_id.." ORDER BY p.person_id ASC LIMIT "..offset..","..limit
local sqldata = "SELECT t1.person_id, t1.person_name, t1.subject_id, t1.subject_name, IFNULL(t2.wk_num, 0) as wk_num "..
    "FROM (SELECT p.person_id, p.person_name, s.subject_id, s.subject_name FROM t_base_person_subject ps, t_base_person p, t_dm_subject s "..
    "WHERE ps.person_id = p.person_id AND ps.subject_id = s.subject_id AND s.stage_id = "..stage_id..subject_id1.." ) t1 LEFT JOIN (SELECT "..
    "w.person_id, COUNT(*) AS wk_num FROM t_wkds_info w WHERE w.isdraft = 0 AND w.b_delete = 0 AND w.type = 2 AND w.type_id = 6 "..subject_id2.." "..
    "GROUP BY w.person_id) t2 ON t1.person_id = t2.person_id ORDER BY wk_num DESC LIMIT "..offset..","..limit
local sqlcount = "SELECT count(*) as totalcount FROM t_base_person_subject ps,t_base_person p,t_dm_subject s WHERE ps.person_id = p.person_id AND ps.subject_id = s.subject_id AND s.stage_id = "..stage_id..subject_id
local resultdata, err = db:query(sqldata)
local resultcount, err = db:query(sqlcount)
if not resultdata or not resultcount then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local totalRow = resultcount[1].totalcount
local totalPage = math.floor((totalRow + pageSize - 1) / pageSize)

--返回值
local cjson = require "cjson"

local returnjson = {}
returnjson.success = "true"
returnjson.stage_name = stage_name
returnjson.totalRow = totalRow
returnjson.totalPage = tostring(totalPage)
returnjson.pageNumber = pageNumber
returnjson.pageSize = pageSize
returnjson.list = resultdata

ngx.say(cjson.encode(returnjson))

--mysql放回连接池
db:set_keepalive(0,v_pool_size)