#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-07-15
#描述：修改微课的主讲人
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
if args["wkds_id_int"] == nil or args["wkds_id_int"] == "" then
    ngx.say("{\"success\":false,\"info\":\"wkds_id_int参数错误！\"}")
    return
end
local wkds_id_int  = tostring(args["wkds_id_int"]);

if args["teacher_name"] == nil or args["teacher_name"] == "" then
    ngx.say("{\"success\":false,\"info\":\"teacher_name参数错误！\"}")
    return
end
local teacher_name  = tostring(args["teacher_name"]);


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

local up_res = "UPDATE t_wkds_base SET teacher_name = '"..teacher_name.."' WHERE wkds_id_int = "..wkds_id_int;
--修改base表的数据
local result_res, err, errno, sqlstate = db:query(up_res)
	if not result_res then
		ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
		ngx.say("{\"success\":false,\"info\":\"修改微课的基本表失败！\"}")
		return
	end
			
--修改info表的数据
local sel_info = "SELECT SQL_NO_CACHE id FROM t_wkds_info_sphinxse WHERE query='filter=wkds_id_int,"..wkds_id_int.."'";
local result_info = db:query(sel_info);
local up_info = "update t_wkds_info set teacher_name ='"..teacher_name.."' where id = ";
	local cjson = require "cjson";
local wkds_info = {};
for i=1,#result_info do

    local content_json = cache:hget("wkds_"..result_info[i]["id"],"content_json")
	local data = cjson.decode(ngx.decode_base64(content_json))
	data.teacher_name = teacher_name;
	local data_new = cjson.encode(data)
	data_new = ngx.encode_base64(data_new);
			   
	up_info = up_info..result_info[i]["id"];
	wkds_info.teacher_name = teacher_name;
	wkds_info.content_json = data_new;
	cache:hmset("wkds_"..result_info[i]["id"],wkds_info);
	local result_upinfo, err, errno, sqlstate = db:query(up_info)
	    if not result_upinfo then
		      ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
			  ngx.say("{\"success\":false,\"info\":\"修改微课的info表失败！\"}")
			 return
		end
end
			
local cjson = require "cjson";
local resultJson={};
resultJson.success = true;
resultJson.info = "修改主讲人成功！";
local responseJson = cjson.encode(resultJson);

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

ngx.say(responseJson);
