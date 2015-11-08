local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

if tostring(args["login_name"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"login_name参数错误\"}")    
    return
end
if tostring(args["pwd"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"pwd参数错误\"}")    
    return
end

if tostring(args["pwd"])=="" then
    ngx.say("{\"success\":false,\"info\":\"pwd不可以为空\"}")    
    return
end

if tostring(args["user_name"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"user_name参数错误\"}")    
    return
end
if tostring(args["user_name"])=="" then
    ngx.say("{\"success\":false,\"info\":\"user_name不可以为空\"}")    
    return
end

local login_name = args["login_name"]
local pwd = args["pwd"]
local user_name = args["user_name"]

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

--检查用户是否存在
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local identity_id,err = cache:hget("login_"..login_name,"identity_id")
if not identity_id then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

if tostring(identity_id)=="userdata: NULL" then
    ngx.say("{\"success\":false,\"info\":\"用户不存在\"}")
    return
end
local person_id = cache:hget("login_"..login_name,"person_id")
local redis_pwd = cache:hget("login_"..login_name,"pwd")

--为旧密码的校验使用
if tostring(args["old_pwd"])~="nil" then
	local old_pwd = tostring(args["old_pwd"])
    if redis_pwd ~= ngx.md5(old_pwd) then
		 ngx.say("{\"success\":false,\"info\":\"旧密码不正确\"}")
		return
	end   
end

--更新数据库
local update_sql = "UPDATE T_SYS_LOGINPERSON SET LOGIN_PASSWORD='"..ngx.md5(pwd).."',PERSON_NAME='"..user_name.."' WHERE LOGIN_NAME='"..login_name.."'"
local results, err, errno, sqlstate = db:query(update_sql);
if not results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"更新数据库错误\"}");
    return
end
--老师
if identity_id == "5" then
	local update_tea_sql = "UPDATE T_BASE_PERSON SET PERSON_NAME='"..user_name.."' WHERE PERSON_ID="..person_id.." AND IDENTITY_ID="..identity_id
	db:query(update_tea_sql)
--学生
elseif identity_id == "6" then
	local update_stu_sql = "UPDATE T_BASE_STUDENT SET STUDENT_NAME='"..user_name.."' WHERE STUDENT_ID="..person_id
	db:query(update_stu_sql)
end

--更新缓存
cache:hset("login_"..login_name,"pwd",ngx.md5(pwd))
cache:hset("login_"..login_name,"person_name",user_name)

--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

ngx.say("{\"success\":true}")  