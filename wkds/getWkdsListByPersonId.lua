--[[
获得一个老师的微课列表
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
--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--获得请求参数
local person_id = args["person_id"]
local sort_type = args["sort_type"]
local sort_order = args["sort_order"]
local pageSize = args["pageSize"]
local pageNumber = args["pageNumber"]

if not person_id or string.len(person_id) == 0 or not sort_type or string.len(sort_type) == 0 
   or not sort_order or string.len(sort_order) == 0 or not pageSize or string.len(pageSize) == 0 or not pageNumber or string.len(pageNumber) == 0 then
	ngx.say("{\"success\":\"false\",\"info\":\"参数错误！\"}")
	return
end

--升序还是降序
local asc_desc = ""
if sort_num=="1" then
    asc_desc = "asc"
else
    asc_desc = "desc"
end 

--排序类型
if sort_type=="1" then
    sort_type = "sort=attr_"..asc_desc..":teacher_name_py;"
elseif sort_type=="2" then
    sort_type = "sort=attr_"..asc_desc..":play_count;"
elseif sort_type=="3" then
    sort_type = "sort=attr_"..asc_desc..":score_average;"
elseif sort_type=="4" then
    sort_type = "sort=attr_"..asc_desc..":ts;"   
elseif sort_type=="5" then
    sort_type = "sort=attr_"..asc_desc..":download_count;"
end

if pageNumber == "0" then
    pageNumber = "1"
end
local offset = pageSize*pageNumber-pageSize
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

local sql = "SELECT SQL_NO_CACHE ID FROM T_WKDS_INFO_SPHINXSE WHERE "..
	"QUERY='filter=person_id,"..person_id..";filter=type,2;filter=type_id,6;filter=isdraft,0;"..
	"filter=b_delete,0;filter=check_status,0,1;"..sort_type.."offset="..offset..";limit="..limit..";';SHOW ENGINE SPHINX  STATUS;"
local resultdata, err = db:query(sql)
if not resultdata then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--去第二个结果集中的Status中截取总个数
local resultdata2 = db:read_result()
local _,s_str = string.find(resultdata2[1]["Status"],"found: ")
local e_str = string.find(resultdata2[1]["Status"],", time:")
local totalRow = string.sub(resultdata2[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

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

local wkdslist = {}
for i,v in ipairs(resultdata) do
	local wkds = {}
	local wkdscache = cache:hmget("wkds_"..resultdata[i].ID, "wkds_id_int","wkds_name","teacher_name","teacher_name_py","person_id","identity_id","create_time",
		"study_instr","design_instr","practice_instr","scheme_id","structure_id","subject_id","play_count","download_count","score_count","score_total","score_average","content_json")
	--ngx.say(type(wkdscache))
	wkds.id = resultdata[i].ID
	wkds.wkds_id_int = wkdscache[1]
	wkds.wkds_name = wkdscache[2]
	wkds.teacher_name = wkdscache[3]
	wkds.teacher_name_py = wkdscache[4]
	wkds.person_id = wkdscache[5]
	wkds.identity_id = wkdscache[6]
	wkds.create_time = wkdscache[7]
	wkds.study_instr = wkdscache[8]
	wkds.design_instr = wkdscache[9]
	wkds.practice_instr = wkdscache[10]
	wkds.scheme_id = wkdscache[11]
	wkds.structure_id = wkdscache[12]
	wkds.subject_id = wkdscache[13]
	wkds.play_count = wkdscache[14]
	wkds.download_count = wkdscache[15]
	wkds.score_count = wkdscache[16]
	wkds.score_total = wkdscache[17]
	wkds.score_average = wkdscache[18]
	wkds.content_json = wkdscache[19]

	local content_json = tostring(wkdscache[19])
    content_json = ngx.decode_base64(content_json)
    --转成table类型
    content_json = cjson.decode(content_json)
	
	local thumb_id
	if table.getn(content_json.sp_list) ~= 0 then
		local resource_info_id = content_json.sp_list[1].id
		if resource_info_id ~= ngx.null then
			local thumbid =ssdb_db:multi_hget("resource_"..resource_info_id, "thumb_id")
			thumb_id = thumbid[2]
		end                              
	else
		thumb_id = "E6648460-4FFD-E626-1C14-6FBF9F94A23C"
	end
	wkds.thumb_id = thumb_id
	wkdslist[i] = wkds
end

--返回值
local returnjson = {}
returnjson.success = "true"
returnjson.totalRow = totalRow
returnjson.totalPage = tostring(totalPage)
returnjson.pageNumber = pageNumber
returnjson.pageSize = pageSize
returnjson.list = wkdslist

ngx.say(cjson.encode(returnjson))

--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0,v_pool_size)
--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size);