#lzy 2015-3-15 唐山开平统一账号登录
local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--先判断参数是否正确
if tostring(args["person_id"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")    
    return
end

--获取人员id
local person_id = tostring(args["person_id"])

local returnJson = {};
--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end


--3.连接数据库
local mysql = require "resty.mysql";
local db, err = mysql : new();
if not db then 
    ngx.log(ngx.ERR, err);
    return;
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
    ngx.say("failed to connect: ", err, ": ", errno, " ", sqlstate)
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

--判断人员是否能够登录后台

local ssdb_value = ssdb_db:exists("school_admin_person_"..person_id);

if ssdb_value[1] == "1" then
-- 根据人员id查询对应的区id
local old_qu_id = cache:hget("person_"..person_id.."_5","qu");
-- 查询区管理员的人员id
local  sel_new_person_id = "SELECT PERSON_ID FROM t_base_person WHERE bureau_id ="..old_qu_id.." and identity_id = 10";

local results, err, errno, sqlstate = db:query(sel_new_person_id);
if not results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end

local new_person_id  = results[1]["PERSON_ID"];

-- 获得区管理员的登录名

local login_name_sql =  "SELECT login_name FROM t_sys_loginperson WHERE person_id = "..new_person_id.." and identity_id = 10";

local results_login_name, err, errno, sqlstate = db:query(login_name_sql);
if not results_login_name then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end

local login_name = results_login_name[1]["login_name"];


-- 组装后台登录管理员信息
local admin_info,err = cache:hmget("login_"..login_name,"person_id","person_name","identity_id","token")
  if not admin_info then
     ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
     return
end

--获得管理员的省市区

local org_info,err = cache:hmget("person_"..admin_info[1].."_10","shi","qu","xiao","sheng");
  if not org_info then
     ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
     return
end
local role_str = "";
local role_info = cache:lrange("role_"..admin_info[1].."_10",0,-1)
    if #role_info ~= 0 then
	for j=1,#role_info,1 do
		   role_str = role_str..role_info[j]..",";
    end
end
returnJson["background_bureau_id"] = org_info[3];
returnJson["background_city_id"] = org_info[1];
returnJson["background_district_id"] = org_info[2];
returnJson["background_identity_id"] = admin_info[3];
returnJson["background_person_id"] = admin_info[1];
returnJson["background_person_name"] = admin_info[2];
returnJson["background_role_id"] = role_str;
returnJson["background_token"] = admin_info[4];
returnJson["background_user"] = login_name;
returnJson["background_province_id"] = org_info[4];
end
returnJson["success"] = true;
returnJson["is_admin"] =ssdb_value[1];	





local cjson = require "cjson";
--cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(returnJson);

ngx.say(responseJson);

-- 7.将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size);

--redis放回连接池
cache:set_keepalive(0,v_pool_size)


	
