--[[
获得学段下所有学校,按微课数量排倒序
@Author feiliming
@Date   2014-11-19
--]]

--判断request类型
local request_method = ngx.var.request_method
local args,err
if request_method == "GET" then
    args,err = ngx.req.get_uri_args()
else
    --get_post_args()这个方法依赖于通过先调用ngx.req.read_body()方法先读取请求的body或者打开lua_need_request_body指令(设置lua_need_request_body为on), 否则将会抛出异常错误. 
    ngx.req.read_body()
    args,err = ngx.req.get_post_args() 
end
if not args then 
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--获得请求参数
local stage_id = args["stage_id"]
local pageSize = args["pageSize"]
local pageNumber = args["pageNumber"]

--args为table类型,不传stage_id返回nil,传stage_id=1或stage_id=true,都返回string,说明table里存的都是string类型
--ngx.say(type(args))
--ngx.say(type(stage_id))

if not stage_id or string.len(stage_id) == 0 or not pageSize or string.len(pageSize) == 0 or not pageNumber or string.len(pageNumber) == 0 then
    ngx.say("{\"success\":\"false\",\"info\":\"参数错误！\"}")
    return
end

local stage_name = nil
if stage_id == "4" then
    stage_name = "小学"
elseif stage_id == "5" then
    stage_name = "初中"
elseif stage_id == "6" then
    stage_name = "高中"
end

if pageNumber == "0" then
    pageNumber = "1"
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
--local sqldata = "SELECT o.ORG_ID as org_id,o.ORG_NAME as org_name FROM t_base_org_stage os,t_base_organization o WHERE os.org_id = o.ORG_ID AND os.stage_id = "..stage_id.." ORDER BY o.ORG_ID ASC LIMIT "..offset..","..limit..""
local sqldata = "SELECT t1.org_id as org_id, t1.org_name as org_name, IFNULL(t2.wk_num,0) AS wk_num "..
    "FROM (SELECT o.org_id, o.org_name FROM t_base_org_stage os, t_base_organization o, t_dm_stage s "..
    "WHERE os.org_id = o.ORG_ID AND os.stage_id = s.STAGE_ID AND os.stage_id = "..stage_id..") t1 "..
    "LEFT JOIN (SELECT  o.org_id, COUNT(*) AS wk_num FROM t_base_org_stage os, t_base_organization o, t_base_person p, t_base_person_subject ps, "..
    "t_dm_subject s, t_wkds_info w WHERE os.org_id = o.ORG_ID AND o.ORG_ID = p.org_id AND ps.person_id = p.person_id AND ps.subject_id = s.subject_id "..
    "AND os.stage_id = s.STAGE_ID AND p.person_id = w.person_id AND w.isdraft = 0 AND w.b_delete = 0 AND w.type = 2 AND w.type_id = 6 "..
    "AND os.stage_id = "..stage_id.." GROUP BY o.ORG_ID) t2 ON t1.org_id = t2.org_id ORDER BY wk_num DESC LIMIT "..offset..","..limit
local sqlcount = "SELECT count(*) as totalcount FROM t_base_org_stage os,t_base_organization o WHERE os.org_id = o.ORG_ID AND os.stage_id = "..stage_id

local resultdata, err = db:query(sqldata)
local resultcount, err = db:query(sqlcount)
if not resultdata or not resultcount then
    ngx.say("{\"success\":\"false\",\"info\":\"SQL出错！\"}")
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