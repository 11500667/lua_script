#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-05-27
#描述：设置版本和产品的关系
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

local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local myts = require "resty.TS";
local ts =  myts.getTs();

--传参数
if args["paramJson"] == nil or args["paramJson"] == "" then
    ngx.say("{\"success\":false,\"info\":\"paramJson参数错误！\"}")
    return
end
local paramJson  = tostring(args["paramJson"]);

 --连接redis
local redis = require "resty.redis"
local cache = redis:new();
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
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

local paramObj = cjson.decode(paramJson);
local scheme_id = paramObj.scheme_id;
local type_id = paramObj.type_id;
local version_name = paramObj.scheme_name;
local scheme_id_char = paramObj.scheme_id_char;

local delProList = paramObj.delProList;
local addProList = paramObj.addProList;

local versionJdon ={};
versionJdon.version_id = scheme_id;
versionJdon.version_name = version_name;
local responseJson = cjson.encode(versionJdon);
	 
local del_product = "delete FROM t_resource_product_scheme where scheme_id = "..scheme_id.." and product_id=";
for i=1,#delProList do
	local product_id = delProList[i];
	local sql_del_product = del_product..product_id;	
	local result, err, errno, sqlstate = db:query(sql_del_product)
     if not result then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	 ngx.say("{\"success\":false,\"info\":\"删除产品版本的关系1！\"}");
	 return
     end
	 --删除缓存
	 cache:zrem("product_scheme_"..product_id.."_"..type_id,responseJson);
end
local sel_sort = "SELECT IFNULL(max(SORT_ID),0) as sort_id FROM t_resource_product_scheme WHERE scheme_id = "..scheme_id;
for j=1,#addProList do 
    local product_id = addProList[j];
	local sql_del_product = del_product..product_id;	
    local result, err, errno, sqlstate = db:query(sql_del_product)
     if not result then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	 ngx.say("{\"success\":false,\"info\":\"删除产品版本的关系2！\"}");
	 return
     end
	 local result_sort, err, errno, sqlstate = db:query(sel_sort)
     if not result_sort then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	 ngx.say("{\"success\":false,\"info\":\"查询最大的sortid失败！\"}");
	 return
     end
	 local sort_id = result_sort[1]["sort_id"];
	 sort_id = tonumber(sort_id+1);
	 --添加到数据库
	 local in_product_scheme = "INSERT INTO t_resource_product_scheme(PRODUCT_ID,PRODUCT_ID_CHAR,SCHEME_ID_CHAR,SCHEME_ID,TS,SORT_ID,B_USE) VALUES ("..product_id..",-1,'"..scheme_id_char.."',"..scheme_id..","..ts..","..sort_id..",1)";
	  local result_scheme, err, errno, sqlstate = db:query(in_product_scheme)
     if not result_scheme then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	 ngx.say("{\"success\":false,\"info\":\"添加产品版本失败！\"}");
	 return
     end
	 --增加缓存
	 cache:zadd("product_scheme_"..product_id.."_"..type_id,sort_id,responseJson)
	 
end
local resultJson = {};
resultJson.success = true;
resultJson.info = "操作成功";
local result = cjson.encode(resultJson);

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


ngx.say(result);