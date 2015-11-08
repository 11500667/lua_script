#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-05-22
#描述：获得用户修改的记录的详细信息
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

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
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
--传参数
if args["resource_id_int"] == nil or args["resource_id_int"] == "" then
    ngx.say("{\"success\":false,\"info\":\"resource_id_int参数错误！\"}")
    return
end
local resource_id_int  = tostring(args["resource_id_int"]);

--根据resource_id_int获得infoid
 local sql_info_id = "SELECT SQL_NO_CACHE id FROM t_resource_info_sphinxse where query='filter=resource_id_int,"..resource_id_int..";filter=group_id,2;'";
 local result_info_id, err, errno, sqlstate = db:query(sql_info_id)
	 if not result_info_id then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	 ngx.say("{\"success\":false,\"info\":\"查询infoid失败！\"}");
	 return
 end
 local iid = result_info_id[1]["id"];
--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end


local resultJson = {};
local sql_info = "SELECT old_obj_info_id,describe_info FROM t_resource_update_flow WHERE new_obj_info_id = "..iid;
 local result_info, err, errno, sqlstate = db:query(sql_info)
	 if not result_info then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	 ngx.say("{\"success\":false,\"info\":\"查询infoid失败！\"}");
	 return
 end
resultJson.success = true;
local new_res_info =ssdb_db:multi_hget("resource_"..iid,"person_name","create_time")
resultJson.create_person = new_res_info[2];
resultJson.create_time = new_res_info[4];

if #result_info >0 then
resultJson.content = result_info[1]["describe_info"];
local old_res_info = ssdb_db:multi_hget("resource_"..result_info[1]["old_obj_info_id"],"resource_title","person_name","create_time","resource_format","resource_page","preview_status","width","height","file_id")

resultJson.old_title = old_res_info[2];
resultJson.old_person = old_res_info[4];
resultJson.old_time = old_res_info[6];
resultJson.resource_format = old_res_info[8];
resultJson.resource_page = old_res_info[10];
resultJson.preview_status = old_res_info[12];
resultJson.width = old_res_info[14];
resultJson.height = old_res_info[16];
resultJson.file_id = old_res_info[18];
else
resultJson.success = false;
resultJson.info = "未找到引用文件";
end

-- 将table对象转换成json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(resultJson);

-- 将redis连接归还到连接池
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
    ngx.log(ngx.ERR, "====>将redis数据库连接归还连接池出错");
end

-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size);

ngx.say(responseJson)
