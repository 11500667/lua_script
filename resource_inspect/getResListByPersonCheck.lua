#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-05-08
#描述：获得人员参加检查的资源
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
if args["check_id"] == nil or args["check_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"check_id参数错误！\"}")
    return
end
local check_id  = tostring(args["check_id"]);

if args["person_id"] == nil or args["person_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
    return
end
local person_id  = tostring(args["person_id"]);

if args["identity_id"] == nil or args["identity_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"identity_id参数错误！\"}")
    return
end
local identity_id  = tostring(args["identity_id"]);

if args["type_id"] == nil or args["type_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"type_id参数错误！\"}")
    return
end
local type_id  = tostring(args["type_id"]);

if args["subject_id"] == nil or args["subject_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"subject_id参数错误！\"}")
    return
end
local subject_id  = tostring(args["subject_id"]);

if args["pageSize"] == nil or args["pageSize"] == "" then
    ngx.say("{\"success\":false,\"info\":\"pageSize参数错误！\"}")
    return
end
local pageSize  = tostring(args["pageSize"]);

if args["pageNumber"] == nil or args["pageNumber"] == "" then
    ngx.say("{\"success\":false,\"info\":\"pageNumber参数错误！\"}")
    return
end
local pageNumber  = tostring(args["pageNumber"]);

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
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
function encodeURI(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
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
local sql_res_list = "SELECT  obj_info_id FROM t_resource_sendcheck WHERE CHECK_id = "..check_id.."  AND person_id = "..person_id.." AND type_id ="..type_id.." and identity_id =  "..identity_id;

local sql_res_list_count = "SELECT count(1) as count  FROM t_resource_sendcheck WHERE CHECK_id = "..check_id.."  AND person_id = "..person_id.." AND type_id ="..type_id.." and identity_id =  "..identity_id;

if subject_id ~= "0" then
   sql_res_list = sql_res_list.." and subject_id="..subject_id;
   sql_res_list_count = sql_res_list_count.." and subject_id="..subject_id;
end
local result, err, errno, sqlstate = db:query(sql_res_list_count)
	 if not result then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	 return
    end
local check_count = result[1]["count"];
local totalPage = math.floor((check_count+pageSize-1)/pageSize);
local offset = pageSize*pageNumber-pageSize;
local limit = pageSize;
local sql_limit = " limit "..offset..","..limit;

local result_res, err, errno, sqlstate = db:query(sql_res_list..sql_limit)
	if not result_res then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	 return
    end
	ngx.log(ngx.ERR,"==========="..sql_res_list..sql_limit.."==================")
local resultJson={};
local res_list = {};
for i=1,#result_res do
   local tab={};
   tab.obj_info_id = result_res[i]["obj_info_id"];
   local res_value = ssdb_db:multi_hget("resource_"..result_res[i]["obj_info_id"],"resource_title","resource_type_name","resource_format","resource_size","resource_page","for_urlencoder_url","for_iso_url","beike_type","resource_id_int","preview_status","file_id");
   tab.resource_title = res_value[2];
   tab.resource_type_name = res_value[4];
   tab.resource_format = res_value[6];
   tab.resource_size = res_value[8];
   tab.resource_page = res_value[10];
   tab.for_urlencoder_url = res_value[12];
   tab.for_iso_url = res_value[14];
   tab.beike_type = res_value[16];
   tab.resource_id_int = res_value[18];
   tab.url_code = encodeURI(res_value[2]);
   tab.preview_status = res_value[20];
   tab.file_id = res_value[22];
	  
   res_list[i] = tab;
end
resultJson.success = true;
resultJson.totalRow = check_count;
resultJson.pageSize = pageSize;
resultJson.totalPage = totalPage;
resultJson.list = res_list;
resultJson.totalPage = pageNumber;

-- 将table对象转换成json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(resultJson);

-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size);

ngx.say(responseJson);












