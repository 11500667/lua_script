#ngx.header.content_type = "text/plain;charset=utf-8"
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

--参数：scheme_id
if args["scheme_id"]==nil or args["scheme_id"]=="" then
    ngx.say("{\"success\":\"false\",\"info\":\"参数错误！\"}");
	ngx.log(ngx.ERR, "ERR MSG =====> 参数scheme_id不能为空！");
    return
end
local scheme_id = tostring(args["scheme_id"]);

--参数：app_type_name
if args["app_type_name"]==nil or args["app_type_name"]=="" then
    ngx.say("{\"success\":\"false\",\"info\":\"参数错误！\"}");
	ngx.log(ngx.ERR, "ERR MSG =====> 参数app_type_name不能为空！");
    return
end
local app_type_name = tostring(args["app_type_name"]);


db:set_timeout(1000) -- 1 sec

local ok, err, errno, sqlstate = db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024 * 1024 }

if not ok then
    ngx.say("failed to connect: ", err, ": ", errno, " ", sqlstate)
    return
end

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local  sel_scheme_sql = "SELECT SCHEME_ID_CHAR FROM T_RESOURCE_SCHEME WHERE SCHEME_ID = "..scheme_id;

-- 查询SCHEME_ID_CHAR记录
local results, err, errno, sqlstate = db:query(sel_scheme_sql);
if not results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end

ngx.log(ngx.ERR,"scheme_id_char"..results[1]["SCHEME_ID_CHAR"]);


local insert_app_type = "INSERT INTO T_BASE_APPTYPE(APP_TYPE_NAME,SCHEME_ID,SCHEME_ID_CHAR,B_USE,TS) VALUES ("..app_type_name..","..scheme_id..")";


insert_app_type = ngx.quote_sql_str(insert_app_type);
--ngx.say("防止sql注入："..raw_value..'       :'..quoted_value);

local res, err, errno, sqlstate =db:query(insert_app_type)
if not res then
    ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
    return
end



