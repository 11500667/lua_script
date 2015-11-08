#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-05-05
#描述：设置参加资源检查的人员的评分
]]
--1.获得参数方法
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

--传参数
if args["person_id"] == nil or args["person_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
    return
end
local person_id  = tostring(args["person_id"]);

if args["subject_id"] == nil or args["subject_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"subject_id参数错误！\"}")
    return
end
local subject_id  = tostring(args["subject_id"]);

if args["subject_name"] == nil or args["subject_name"] == "" then
    ngx.say("{\"success\":false,\"info\":\"subject_name参数错误！\"}")
    return
end
local subject_name  = tostring(args["subject_name"]);

if args["school_id"] == nil or args["school_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"school_id参数错误！\"}")
    return
end
local school_id  = tostring(args["school_id"]);

if args["check_id"] == nil or args["check_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"check_id参数错误！\"}")
    return
end
local check_id  = tostring(args["check_id"]);


if args["identity_id"] == nil or args["identity_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"identity_id参数错误！\"}")
    return
end
local identity_id  = tostring(args["identity_id"]);

if args["person_score"] == nil or args["person_score"] == "" then
    ngx.say("{\"success\":false,\"info\":\"person_score参数错误！\"}")
    return
end
local person_score  = tostring(args["person_score"]);

if args["person_comments"] == nil or args["person_comments"] == "" then
    ngx.say("{\"success\":false,\"info\":\"person_comments参数错误！\"}")
    return
end
local person_comments  = tostring(args["person_comments"]);

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local person_name = cache:hget("person_"..person_id.."_"..identity_id,"person_name");

-- 将redis连接归还到连接池
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
    ngx.log(ngx.ERR, "====>将redis数据库连接归还连接池出错");
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
local create_time = ngx.localtime();
local sql_submit = "INSERT into t_resource_check_person_score(check_id,PERSON_ID,PERSON_NAME,IDENTITY_ID,person_socre,PERSON_COMMENTS,CREATE_TIME,school_id,subject_id,subject_name) VALUES("..check_id..","..person_id..",'"..person_name.."',"..identity_id..","..person_score..",'"..person_comments.."','"..create_time.."',"..school_id..","..subject_id..",'"..subject_name.."')";

ngx.log(ngx.ERR,"===================="..sql_submit)
local result, err, errno, sqlstate = db:query(sql_submit)
if not result then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	 ngx.say("{\"success\":false,\"info\":\"设置人员评分出错！\"}");
	 return
end

-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

ngx.say("{\"success\":true,\"info\":\"设置人员评分成功\"}")












