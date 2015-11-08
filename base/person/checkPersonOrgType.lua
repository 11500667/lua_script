#lzy 2015-4-29 检查人员是否是教育局机关的人（多级门户中使用）
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

--先判断参数是否正确
if tostring(args["identity_id"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")    
    return
end

--获取人员id
local identity_id = tostring(args["identity_id"])

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

--获得
local org_info,err = cache:hget("person_"..person_id.."_"..identity_id,"xiao");
  if not org_info then
     ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
     return
end

local bureau_id = org_info;

--判断是否是教育局机关的人
local sql_org_type = "SELECT org_type FROM t_base_organization WHERE ORG_ID= "..bureau_id;

local results, err, errno, sqlstate = db:query(sql_org_type);
if not results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end
local org_type = 0;
if #results > 0 then
    org_type = results[1]["org_type"];
else
   ngx.say("{\"success\":\"false\",\"info\":\"无法获得该人员的组织机构！\"}");
end 

returnJson["success"] = true;
returnJson["org_type"] =org_type;

local cjson = require "cjson";
local responseJson = cjson.encode(returnJson);

ngx.say(responseJson);

-- 7.将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

--redis放回连接池
cache:set_keepalive(0,v_pool_size)


	
