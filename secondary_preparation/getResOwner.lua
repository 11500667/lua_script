#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-05-10
#描述：获得资源的所有者
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
	
--传参数
if args["obj_id_int"] == nil or args["obj_id_int"] == "" then
    ngx.say("{\"success\":false,\"info\":\"obj_id_int参数错误！\"}")
    return
end
local obj_id_int  = tostring(args["obj_id_int"]);

if args["type_id"] == nil or args["type_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"type_id参数错误！\"}")
    return
end
local type_id  = tostring(args["type_id"]);

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

--根据int_id获得对应的infoid
local sql_info_id = "";

if type_id == "1" then
    sql_info_id = "SELECT SQL_NO_CACHE id FROM t_resource_info_sphinxse where query='filter=resource_id_int,"..obj_id_int..";filter=group_id,2;'";
elseif type_id =="2" then
    sql_info_id = "SELECT SQL_NO_CACHE id FROM t_sjk_paper_info_sphinxse where query='filter=paper_id_int,"..obj_id_int..";filter=group_id,2;'";
end

local result_infoid, err, errno, sqlstate = db:query(sql_info_id)
	 if not result_infoid then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	 ngx.say("{\"success\":false,\"info\":\"查询infoid失败！\"}");
	 return
 end
	
local obj_info_id = result_infoid[1]["id"];

local down_path;
local person_id;
local res_value;


--local sql_get_yuan_obj_info_id = "SELECT yuan_obj_info_id FROM t_resource_update_flow where new_obj_info_id ="..obj_info_id.." and type_id="..type_id;
--ngx.log(ngx.ERR,"SQL->"..sql_get_yuan_obj_info_id.."<-")
--[[
local result, err, errno, sqlstate = db:query(sql_get_yuan_obj_info_id)
	 if not result then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	 ngx.say("{\"success\":false,\"info\":\"新增修改记录失败！\"}");
	 return
    end


	if #result>0 then
	  res_value = cache:hmget("resource_"..result[1]["yuan_obj_info_id"],"person_id","for_urlencoder_url");
	  person_id = res_value[1];
	  obj_info_id = result[1]["yuan_obj_info_id"];
	  down_path = res_value[2];
	else
	  res_value = cache:hmget("resource_"..obj_info_id,"person_id","for_urlencoder_url");
	  person_id = res_value[1];
	  down_path = res_value[2];
	end
]]
res_value = ssdb_db:multi_hget("resource_"..obj_info_id,"person_id","for_urlencoder_url");
person_id = res_value[2];
down_path = res_value[4];
-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end


--放回到SSDB连接池
	ssdb_db:set_keepalive(0,v_pool_size)


ngx.say("{\"success\":true,\"owner\":\""..person_id.."\",\"yuan_obj_info_id\":\""..obj_info_id.."\",\"down_path\":\""..down_path.."\"}")












