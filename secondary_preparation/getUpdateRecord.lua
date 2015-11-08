#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-05-10
#描述：获得资源修改记录
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

local action_id;
if args["action_id"] == nil  then
   action_id = -1;
else
   action_id= tostring(args["type_id"]);
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

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--根据int_id获得对应的infoid
local sql_info_id = "";

if type_id == "1" then
    sql_info_id = "SELECT SQL_NO_CACHE id FROM t_resource_info_sphinxse where query='filter=resource_id_int,"..obj_id_int..";filter=group_id,2;'";
end
local result_infoid, err, errno, sqlstate = db:query(sql_info_id)
	 if not result_infoid then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	 ngx.say("{\"success\":false,\"info\":\"查询infoid失败！\"}");
	 return
 end
	
local obj_info_id = result_infoid[1]["id"];

local sql_sel_record = "SELECT new_obj_info_id,create_time,describe_info FROM t_resource_update_flow WHERE yuan_obj_info_id= (SELECT yuan_obj_info_id FROM t_resource_update_flow WHERE old_obj_info_id = "..obj_info_id.." AND type_id = "..type_id.." limit 1) and action_id = "..action_id;
ngx.log(ngx.ERR,"SQL->"..sql_sel_record.."<-")
local result, err, errno, sqlstate = db:query(sql_sel_record)
	 if not result then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	 ngx.say("{\"success\":false,\"info\":\"查询修改记录失败！\"}");
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


local resultJson={};
local update_record = {};
for i=1,#result do
   local tab={};
   tab.update_time = result[i]["create_time"];
   local info_id = result[i]["new_obj_info_id"]
   tab.describe_info = result[i]["describe_info"];
  --去缓存中取值
    if type_id == "1" then
	   local res_value =  ssdb_db:multi_hget("resource_"..info_id,"resource_title","person_name","file_id","resource_format","resource_page","preview_status","width","height");
	   tab.resource_title = res_value[2];
	   tab.person_name = res_value[4];
	   tab.file_id = res_value[6];
	   tab.resource_format = res_value[8];
	   tab.resource_page = res_value[10];
	   tab.preview_status = res_value[12];
	   tab.width = res_value[14];
	   tab.height = res_value[16];
	end
   update_record[i] = tab;
end
resultJson.success = true;
resultJson.list = update_record;

-- 将table对象转换成json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(resultJson);
	
-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

-- 将redis连接归还到连接池
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
    ngx.log(ngx.ERR, "====>将redis数据库连接归还连接池出错");
end

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size);

ngx.say(responseJson)




