#ngx.header.content_type = "text/plain;charset=utf-8"
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end


--参数：app_type_id
if args["app_type_id"]==nil or args["app_type_id"]=="" then
    ngx.say("{\"success\":\"false\",\"info\":\"参数错误！\"}");
    ngx.log(ngx.ERR, "ERR MSG =====> 参数app_type_id不能为空！");
    return
end
local app_type_id = tostring(args["app_type_id"]);
ngx.log(ngx.ERR,"app_type_id="..app_type_id)
--参数：b_use

if args["b_use"]==nil or args["b_use"]=="" then
    ngx.say("{\"success\":\"false\",\"info\":\"3参数错误！\"}");
	ngx.log(ngx.ERR, "ERR MSG =====> 参数b_use不能为空！");
    return
end
local b_use = tostring(args["b_use"]);


--scheme_id

if args["scheme_id"]==nil or args["scheme_id"]=="" then
    ngx.say("{\"success\":\"false\",\"info\":\"3参数错误！\"}");
    ngx.log(ngx.ERR, "ERR MSG =====> 参数scheme_id不能为空！");
    return
end
local scheme_id = tostring(args["scheme_id"]);

--ngx.say("scheme_id"..scheme_id.."app_type_name"..app_type_name);

local cjson = require "cjson"
-- 获取数据库连接
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

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end
local apptype_tab = {}; 


local up_apptype = "UPDATE T_BASE_APPTYPE SET B_USE = "..b_use.." WHERE APP_PRIME_ID = "..app_type_id.." AND SCHEME_ID = "..scheme_id;

local results, err, errno, sqlstate = db:query(up_apptype);
if not results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end

apptype_tab.b_use= b_use;
ngx.log(ngx.ERR,"b_use="..b_use);

-- 查询已经添加的媒体类型
local set_app = "SELECT APP_PRIME_ID,APP_TYPE_NAME FROM T_BASE_APPTYPE WHERE SCHEME_ID = "..scheme_id.." AND B_USE = 1 ORDER BY APP_PRIME_ID";
local ht_set_app = "SELECT APP_PRIME_ID,APP_TYPE_NAME,B_USE FROM T_BASE_APPTYPE WHERE SCHEME_ID = "..scheme_id.." ORDER BY APP_PRIME_ID";

local results, err, errno, sqlstate = db:query(set_app);
if not results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end

local ht_results, err, errno, sqlstate = db:query(ht_set_app);
if not ht_results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end


local app_type = {};
local ht_app_type = {};
local appids="";

for i=1,#results do
    local tab1 = {};
    tab1["app_type_id"] = results[i]["APP_PRIME_ID"];
    appids = appids..","..results[i]["APP_PRIME_ID"];
    tab1["app_type_name"] = results[i]["APP_TYPE_NAME"];
    app_type[i] = tab1;

end


for i=1,#ht_results do
    local ht_tab = {};
    ht_tab["app_type_id"] = ht_results[i]["APP_PRIME_ID"];
    ht_tab["app_type_name"] = ht_results[i]["APP_TYPE_NAME"];
    ht_tab["b_use"] = ht_results[i]["B_USE"];
    ht_app_type[i] = ht_tab;
end

    cache:set("appids_scheme_"..scheme_id,string.sub(appids,2,#appids));
    local jsonData = cjson.encode(app_type)
    cache:set("apptype_scheme_"..scheme_id,jsonData)

    local HtjsonData = cjson.encode(ht_app_type)
    cache:set("ht_apptype_scheme_"..scheme_id,HtjsonData)

    cache:hmset("t_base_apptype_"..scheme_id.."_"..app_type_id,apptype_tab)

-- 将redis连接归还到连接池
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
    ngx.log(ngx.ERR, "====>将Redis连接归还连接池出错！");
end

-- 将mysql连接归还到连接池
local ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
    ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end
--操作缓存
ngx.say("{\"success\":\"true\",\"info\":\"操作成功\"}");



