#ngx.header.content_type = "text/plain;charset=utf-8"
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end


--参数：resource_ids
if args["resource_ids"]==nil or args["resource_ids"]=="" then
    ngx.say("{\"success\":\"false\",\"info\":\"参数错误！\"}");
	ngx.log(ngx.ERR, "ERR MSG =====> 参数resource_ids不能为空！");
    return
end
local resource_ids = tostring(args["resource_ids"]);


--参数：apptype_ids
if args["apptype_ids"]==nil or args["apptype_ids"]=="" then
    ngx.say("{\"success\":\"false\",\"info\":\"参数错误！\"}");
	ngx.log(ngx.ERR, "ERR MSG =====> 参数apptype_ids不能为空！");
    return
end
local apptype_ids = tostring(args["apptype_ids"]);

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

local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end


-- 用sphinx查询出所有的资源
local info_id_sql = "SELECT SQL_NO_CACHE ID FROM t_resource_info_sphinxse WHERE query='filter=resource_id_int,"..resource_ids..";'";


local results, err, errno, sqlstate = db:query(info_id_sql);
if not results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end

local  up_info = "START TRANSACTION;";
for i=1,#results do
	local t=ngx.now();
    local n=os.date("%Y%m%d%H%M%S").."00"..string.sub(t,12,14);
    n=n..string.rep("0",19-string.len(n));
 up_info = up_info.."UPDATE T_RESOURCE_INFO SET UPDATE_TS = "..n.." , APP_TYPE_ID = "..apptype_ids.." WHERE ID = "..results[i]["ID"]..";"; 
 --修改缓存
 -- lzy 2015-7-9

 local resourceInfo = {};
resourceInfo.id = results[i]["ID"]
resourceInfo.app_type_id = apptype_ids;

 local resourceUtil     = require "base.resource.model.ResourceUtil";

 local result_set = resourceUtil:setResourceInfo(resourceInfo)
 --cache:hmset("resource_"..results[i]["ID"],"app_type_id",apptype_ids);
 -- lzy 2015-7-9
end
up_info= up_info.."COMMIT;";

local results_up, err, errno, sqlstate = db:query(up_info);
if not results_up then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"更改数据库出错！\"}");
    return
end

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

ngx.say("{\"success\":\"true\",\"info\":\"操作成功\"}");