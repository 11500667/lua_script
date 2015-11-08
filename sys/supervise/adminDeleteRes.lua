#ngx.header.content_type = "text/plain;charset=utf-8"
-- local cookie_person_id = tostring(ngx.var.cookie_person_id);
-- local cookie_identity_id = tostring(ngx.var.cookie_identity_id);

local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end


--参数：resource_id_int
if args["resource_id_int"]==nil or args["resource_id_int"]=="" then
    ngx.say("{\"success\":\"false\",\"info\":\"参数错误！\"}");
	ngx.log(ngx.ERR, "ERR MSG =====> 参数resource_id_int不能为空！");
    return
end
local resIdInt = tostring(args["resource_id_int"]);


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
-- 查询info的语句
local sql = "SELECT ID FROM T_RESOURCE_INFO_SPHINXSE WHERE QUERY='filter=resource_id_int,".. resIdInt ..";maxmatches=10000;offset=0;limit=10000'";

-- local sql = "SELECT ID FROM T_RESOURCE_INFO_SPHINXSE WHERE QUERY='filter=resource_id_int,".. resIdInt ..";filter=res_type,1;select=IF(group_id=2,1,0) as match_qq;filter=match_qq,0;maxmatches=10000;offset=0;limit=10000'";

-- 查询my_info的语句
local myinfoSql = "SELECT ID FROM T_RESOURCE_MY_INFO WHERE RESOURCE_ID_INT=" .. resIdInt;

--local myinfoSql = "SELECT ID FROM T_RESOURCE_MY_INFO_SPHINXSE WHERE QUERY='filter=resource_id_int,".. resIdInt ..";select=IF(type_id=6,1,0) as match_qq;filter=match_qq,0;maxmatches=10000;offset=0;limit=10000'";

-- 删除数据的语句
local delSql = "START TRANSACTION;";
delSql = delSql .. "DELETE FROM T_RESOURCE_INFO WHERE RESOURCE_ID_INT=" .. resIdInt .. ";";
delSql = delSql .. "INSERT INTO SPHINX_DEL_INFO (DEL_INDEX_ID) ".. sql .. ";";
delSql = delSql .. "DELETE FROM T_RESOURCE_MY_INFO WHERE RESOURCE_ID_INT=" .. resIdInt .. ";";
delSql = delSql .. "INSERT INTO SPHINX_MY_DEL_INFO (DEL_INDEX_ID) ".. myinfoSql .. ";";
delSql = delSql .. "DELETE FROM T_RESOURCE_BASE WHERE RESOURCE_ID_INT=" .. resIdInt .. ";";
delSql = delSql .. "COMMIT;";

cache:init_pipeline()

-- 查询info表的记录
local results, err, errno, sqlstate = db:query(sql);
if not results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end

for i=1, #results do
	local resInfoId = results[i]["ID"];
	local infoCache = cache: del("resource_"..resInfoId);
end

-- 查询my_info表的记录
local results2, err2, errno2, sqlstate2 = db:query(myinfoSql);
if not results2 then
    ngx.log(ngx.ERR, "bad result: ", err2, ": ", errno2, ": ", sqlstate2, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end

for i=1, #results2 do
	local myInfoId = results2[i]["ID"];
	local infoCache = cache: del("myresource_" .. myInfoId);
end

local cacheResults, err = cache:commit_pipeline()
if not cacheResults then
    ngx.say("{\"success\":\"false\",\"info\":\"删除数据出错！\"}")
	ngx.log(ngx.ERR, "redis pipe bad result: ", err);
    return
end

-- 删除数据库记录
local delRs, err3, errno3, sqlstate3 = db:query(delSql);
if not delRs then
	ngx.log(ngx.ERR, "bad result: ", err3, ": ", errno3, ": ", sqlstate3, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"删除数据出错！\"}");
    return
end


local responseObj = {};
responseObj.success = true;
responseObj.info = "删除资源成功！";

-- 将table对象转换成json
local cjson = require "cjson";
local responseJson = cjson.encode(responseObj);

-- 输出json串到页面
ngx.say(responseJson);

-- 将redis连接归还到连接池
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
	ngx.log(ngx.ERR, "====>将Redis连接归还连接池出错！");
end

-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end
