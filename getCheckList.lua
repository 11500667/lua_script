#ngx.header.content_type = "text/plain;charset=utf-8"
local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)

--判断是否有person_id的cookie信息
if cookie_person_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"Cookie的人员信息未获取到！\"}")
    return
end
--判断是否有identity_id的cookie信息
if cookie_identity_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"Cookie的人员身份信息未获取到！\"}")
    return
end

--连接redis服务器
local redis = require "resty.redis"
local cache = redis.new()
local ok,err = cache.connect(cache,v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--组ID参数
local groupId = tostring(ngx.var.arg_groupId)
--判断是否有groupId参数
if groupId == "nil" then
    ngx.say("{\"success\":false,\"info\":\"没有groupId参数！\"}")
    return
end

--stateId参数
local stateId = tostring(ngx.var.arg_stateId)
--判断是否有stateId参数
if stateId == "nil" then
    ngx.say("{\"success\":false,\"info\":\"没有stateId参数！\"}")
    return
end

--pageSize参数
local pageSize = tostring(ngx.var.arg_pageSize)
--判断是否有pageSize参数
if pageSize == "nil" then
    ngx.say("{\"success\":false,\"info\":\"没有pageSize参数！\"}")
    return
end

--pageNumber参数
local pageNumber = tostring(ngx.var.arg_pageNumber)
--判断是否有pageNumber参数
if pageNumber == "nil" then
    ngx.say("{\"success\":false,\"info\":\"没有pageNumber参数！\"}")
    return
end

--连接数据库
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


local offset = pageSize*pageNumber-pageSize
local limit = pageSize

local l_res = db:query("SELECT SQL_NO_CACHE id FROM t_base_group_member_sphinxse WHERE QUERY='filter=state_id,"..stateId..";filter=group_id,"..groupId..";sort=attr_desc:ts;maxmatches=100000;offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX STATUS;")

--去第二个结果集中的Status中截取总个数
local res1 = db:read_result()
local _,s_str = string.find(res1[1]["Status"],"found: ")
local e_str = string.find(res1[1]["Status"],", time:")
local totalRow = string.sub(res1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

local res = ""

if #l_res ~=0 then
    for i=1,#l_res do
	local str = "{\"member_id\": \"##\",\"org_id\": \"##\",\"org_name\": \"##\",\"person_id\": \"##\",\"person_name\": \"##\",\"identity_id\": \"##\",\"bureau_id\": \"##\",\"bureau_name\": \"##\",\"apply_time\": \"##\",\"check_content\": \"##\",\"member_type\":\"##\"}"
	local group_person = cache:hmget("member_"..l_res[i]["id"],"group_id","person_id","identity_id")
	local group_id = group_person[1]
	local person_id = group_person[2]
	local identity_id = group_person[3]
	
	local member_info = cache:hmget("member_"..group_id.."_"..person_id.."_"..identity_id,"member_id","org_id","org_name","person_id","person_name","identity_id","bureau_id","bureau_name","apply_time","check_content","member_type")
	for j=1,#member_info do
	    str = string.gsub(str,"##",member_info[j],1)
	end
	res = res..str..","
    end
end
res = string.sub(res,0,#res-1)
ngx.say("{\"success\":true,\"totalRow\":\""..totalRow.."\",\"totalPage\":\""..totalPage.."\",\"pageNumber\":\""..pageNumber.."\",\"pageSize\":\""..pageSize.."\",\"table_List\":["..res.."]}")
