#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2014-02-05
#描述：获得一个资源的共享范围
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
--2.获得参数方法
--获得资源id
if args["resource_id"] == nil or args["resource_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"resource_id参数错误！\"}")
    return
end
local resource_id = ngx.quote_sql_str(args["resource_id"])

--3.连接数据库
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

--根据资源获得是否共享
local sel_share = "SELECT is_share,resource_category FROM t_bag_resource_info where resource_id = "..resource_id;
ngx.log(ngx.ERR,"====="..sel_share)
-- 根据资源获得是否共享
local results, err, errno, sqlstate = db:query(sel_share);
if not results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end

local responseObj = {};
responseObj.success = true;
if #results > 0 then
    responseObj.is_share =  results[1]["is_share"];
else
    ngx.say("{\"success\":\"false\",\"info\":\"没有找到该资源！\"}");
	return
end
local resource_category = results[1]["resource_category"];
--根据资源id获得发布班级
local sel_class_list = "SELECT distinct class_id FROM t_resource_sendstudent WHERE resource_id = "..resource_id;

-- 根据资源获得是否共享
local results_list, err, errno, sqlstate = db:query(sel_class_list);
if not results_list then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据1出错！\"}");
    return
end
local class_ids = "";
if #results_list >0 then
for i=1,#results_list do
    class_ids = results_list[i]["class_id"]..","..class_ids;
end
class_ids = string.sub(class_ids,0,#class_ids-1)
end
responseObj.class_ids =  class_ids;

if resource_category == 7 then
        local sql_state = "SELECT CLASS_ID,STATE_ID from t_bag_sjstate where resource_id ="..resource_id;
		local class_state = db:query(sql_state);
		local class_state_info = "";
		for i=1,#class_state do
		   class_state_info = class_state_info..","..class_state[i]["CLASS_ID"]..":"..class_state[i]["STATE_ID"];
		end
		if #class_state_info >0 then
		    class_state_info = string.sub(class_state_info,2,#class_state_info)
		end
		responseObj.class_open = class_state_info;
end

-- 5.将table对象转换成json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(responseObj);

-- 6.输出json串到页面
ngx.say(responseJson);

-- 7.将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end









