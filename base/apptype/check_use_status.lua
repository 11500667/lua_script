#ngx.header.content_type = "text/plain;charset=utf-8"
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end


--连接redis服务器
local redis = require "resty.redis"
local cache = redis.new()
local ok,err = cache.connect(cache,v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--参数：scheme_id
if args["scheme_id"]==nil or args["scheme_id"]=="" then
    ngx.say("{\"success\":\"false\",\"info\":\"1参数错误！\"}");
	ngx.log(ngx.ERR, "ERR MSG =====> 参数scheme_id不能为空！");
    return
end
local scheme_id = tostring(args["scheme_id"]);
local str_scheme = "filter=scheme_id_int,"..scheme_id..";";

--应用类型id
local app_type_id = tostring(args["app_type_id"])
if app_type_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"app_type_id丢失！\"}")
    return
end

local  str_app="";

local myPrime = require "resty.PRIME";
--根据scheme_id获得应用类型
if app_type_id ~= "0" then

local appids = cache:get("appids_scheme_"..scheme_id);
ngx.log(ngx.ERR,"&&&&&"..appids.."&&&&&&&")
local app_tab = Split(appids,",");
local app_val_tab = {};
local j = 0;
for i=1,#app_tab do
     
     if app_type_id ~= app_tab[i] then
       app_val_tab[j] = app_tab[i]
       ngx.log(ngx.ERR,"$$$$"..app_val_tab[j].."$$")
        j = j+1
     end
end
local search_app_vals = myPrime.getCombineValues(app_val_tab,app_type_id);
  str_app = "filter=app_type_id,"..app_type_id..","..search_app_vals..";";

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


local sql = "SELECT SQL_NO_CACHE id FROM t_resource_info_sphinxse  WHERE query='"..str_scheme..str_app.."filter=release_status,1,2,3'";
ngx.log(ngx.ERR,sql);
local res = db:query(sql);

local res_length = #res


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


if res_length>0 then
   ngx.say("{\"success\":\"false\",\"info\":\"该应用类型设置了资源，不允许停用！\"}");      
else
   ngx.say("{\"success\":\"true\"}");  
end
