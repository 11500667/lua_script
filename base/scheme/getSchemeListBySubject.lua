#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-05-21
#描述：获得当前学段科目下的版本列表
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
if args["subject_id"] == nil or args["subject_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"subject_id参数错误！\"}")
    return
end
local subject_id  = tostring(args["subject_id"]);

if args["stage_id"] == nil or args["stage_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"stage_id参数错误！\"}")
    return
end
local stage_id  = tostring(args["stage_id"]);

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

--拼接sql语句
local sql_scheme = "SELECT SCHEME_ID,SCHEME_NAME,TYPE_ID,SCHEME_ID_CHAR FROM t_resource_scheme WHERE  b_use = 1 AND SCHEME_TYPE = 1 AND  system_id = 1 AND SUBJECT_ID ="..subject_id.." order by ts desc ";

local result_scheme, err, errno, sqlstate = db:query(sql_scheme)
	if not result_scheme then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	 return
    end
	
local resultJson={};
local scheme_list = {};
for i=1,#result_scheme do
   local tab={};
   tab.scheme_id = result_scheme[i]["SCHEME_ID"];
   tab.scheme_name = result_scheme[i]["SCHEME_NAME"]; 
   tab.type_id = result_scheme[i]["TYPE_ID"]; 
   tab.scheme_id_char = result_scheme[i]["SCHEME_ID_CHAR"]; 
   
   scheme_list[i] = tab;
end
resultJson.success = true;
resultJson.list = scheme_list;

-- 将table对象转换成json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(resultJson);

-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

ngx.say(responseJson);












