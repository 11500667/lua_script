--[[
功能：根据群组ID获取该群组下的人员登录名和姓名
作者：吴缤
时间：2015-08-27
]]

local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

if args["id"] == nil or args["id"] == "" then
    ngx.print("{\"success\":false,\"info\":\"id参数不允许为空！\"}")
    return
end
local id = args["id"]

--连接redis服务器
local redis = require "resty.redis"
local redis_db = redis:new()
local ok,err = redis_db:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--连接mysql数据库
local mysql = require "resty.mysql"
local mysql_db = mysql:new()
mysql_db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024*1024
}

local cjson = require "cjson"
cjson.encode_empty_table_as_object(false);

local result = {}
--如果传过来的ID第一位为c说明就是班级，否则就是其他
if string.sub(id,0,1) == "c" then
	--需要将id中的class_去掉只留id值
	local class_id = string.sub(id,7,#id)
	--班级有哪些学生
	local student_res = ngx.location.capture("/dsideal_yy/base/getStudentByClassId?class_id="..class_id.."&random_num="..math.random(1000))
	local student_info = cjson.decode(student_res.body).list
	for i=1,#student_info do
		local person_id = student_info[i]["student_id"]
		local person_name = student_info[i]["student_name"]
		local identity_id = "6"
		local login_name = redis_db:hget("person_"..person_id.."_"..identity_id,"login_name")
		if login_name == ngx.null then
			login_name = "暂无"
		end
		result[login_name] = person_name
	end	
	
	--班级有哪些教师教
	local teacher_res = mysql_db:query("SELECT t1.teacher_id,t2.person_name FROM t_base_class_subject t1 INNER JOIN t_base_person t2 on t1.teacher_id=t2.person_id WHERE xq_id = (SELECT xq_id FROM t_base_term WHERE sfdqxq=1) AND t1.b_use = 1 AND class_id = "..class_id)
	for i=1,#teacher_res do
		local person_id = teacher_res[i]["teacher_id"]
		local person_name = teacher_res[i]["person_name"]
		local identity_id = "5"
		local login_name = redis_db:hget("person_"..person_id.."_"..identity_id,"login_name")
		if login_name == ngx.null then
			login_name = "暂无"
		end
		result[login_name] = person_name		
	end
	
else
	--群组下有哪些人员
	local group_res = ngx.location.capture("/dsideal_yy/group/getMemberByparams?groupId="..id.."&nodeId="..id.."&rangeType=3&orgType=-1&stage_id=-1&subject_id=-1&keyword=&member_type=-1&pageNumber=1&pageSize=1000&random_num="..math.random(1000))
	local group_info = cjson.decode(group_res.body).table_List	
	for i=1,#group_info do
		local person_id = group_info[i]["PERSON_ID"]
		local person_name = group_info[i]["PERSON_NAME"]
		local identity_id = group_info[i]["identity_id"]	
		local login_name = redis_db:hget("person_"..person_id.."_"..identity_id,"login_name")
		if login_name == ngx.null then
			login_name = "暂无"
		end		
		result[login_name] = person_name
	end	
end

--放回到SSDB连接池
redis_db:set_keepalive(0,v_pool_size)
mysql_db:set_keepalive(0,v_pool_size)
ngx.print(cjson.encode(result))

