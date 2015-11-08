#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-05-08
#描述：判断人员是否是检查人员
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

if args["identity_id"] == nil or args["identity_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"identity_id参数错误！\"}")
    return
end
local identity_id  = tostring(args["identity_id"]);
--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local school_id = cache:hget("person_"..person_id.."_"..identity_id,"xiao");
local school_name = cache:hget("t_base_organization_"..school_id,"org_name");
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


--拼接sql语句
local sql_person = "SELECT t1.check_id,t1.school_id FROM t_resource_check_person_subject as t1 INNER JOIN t_resource_check_info AS t2 on t1.check_id = t2.check_id WHERE person_id ="..person_id.."  and identity_id = "..identity_id.." and status_id = 1";

local result_check, err, errno, sqlstate = db:query(sql_person)
	if not result_check then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	 return
    end
	
local resultJson={};

resultJson.success = true;
if #result_check>0 then
resultJson.is_checkperson = 1;
else
resultJson.is_checkperson = 0;
end
resultJson.school_name = school_name;
resultJson.school_id = school_id;
-- 将table对象转换成json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(resultJson);

-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

ngx.say(responseJson);












