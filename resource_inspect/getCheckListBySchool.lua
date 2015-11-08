#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-05-04
#描述：学校管理员获得检查列表
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
if args["school_id"] == nil or args["school_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"school_id参数错误！\"}")
    return
end
local school_id  = tostring(args["school_id"]);

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
local sql_check_count = "SELECT COUNT(1) as count FROM t_resource_check_info WHERE school_id ="..school_id;
local result, err, errno, sqlstate = db:query(sql_check_count)
	 if not result then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	 return
    end
local check_count = result[1]["count"];
local totalPage = math.floor((check_count+pageSize-1)/pageSize);
local offset = pageSize*pageNumber-pageSize;
local limit = pageSize;
local sql_limit = " limit "..offset..","..limit;
--拼接sql语句
local sql_check_list = "SELECT CHECK_ID,CHECK_NAME,CHECK_STANDARD,START_TIME,END_TIME,CREATE_TIME,STATUS_ID FROM t_resource_check_info WHERE SCHOOL_ID = "..school_id.." ORDER BY create_time desc "..sql_limit;

local result_check, err, errno, sqlstate = db:query(sql_check_list)
	if not result_check then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	 return
    end
	
local resultJson={};
local check_list = {};
for i=1,#result_check do
   local tab={};
   tab.check_id = result_check[i]["CHECK_ID"];
   tab.check_name = result_check[i]["CHECK_NAME"];
   tab.check_standard = result_check[i]["CHECK_STANDARD"];
   tab.start_time = result_check[i]["START_TIME"];
   tab.end_time = result_check[i]["END_TIME"];
   tab.create_time = result_check[i]["CREATE_TIME"];
   tab.status_id = result_check[i]["STATUS_ID"];
   check_list[i] = tab;
end
resultJson.success = true;
resultJson.totalRow = check_count;
resultJson.pageSize = pageSize;
resultJson.totalPage = totalPage;
resultJson.list = check_list;
resultJson.pageNumber = pageNumber;
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












