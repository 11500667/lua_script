#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2014-02-05
#描述：获得一个资源的共享范围
#去掉是否共享的返回值 只返回 共享范围  曹洪念 2015.8.15
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
local resource_id = args["resource_id"]

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

--根据资源获得资源类型
local sel_share = "SELECT bk_type FROM t_resource_base where RESOURCE_ID_INT = '"..resource_id.."'";
ngx.log(ngx.ERR,"====="..sel_share)
-- 根据资源获得资源类型
local results, err, errno, sqlstate = db:query(sel_share);
if not results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"查询资源类型失败！\"}");
    return
end

local responseObj = {};
responseObj.success = true;

local bk_type = results[1]["bk_type"];
--根据资源id获得发布班级
local sel_class_list = "SELECT distinct class_id FROM t_resource_sendstudent WHERE resource_id = '"..resource_id.."'";

-- 根据资源获得是否共享
local results_list, err, errno, sqlstate = db:query(sel_class_list);
if not results_list then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"获得发布班级出错！\"}");
    return
end

local class_ids = "";
if #results_list >0 then
for i=1,#results_list do
    class_ids = results_list[i]["class_id"]..","..class_ids;
end
class_ids = string.sub(class_ids,0,#class_ids-1)
end
-- responseObj.class_ids =  class_ids;

local sql2 = "SELECT class_id,class_name FROM t_base_class where class_id in ("..class_ids..")";

local result_name,err, errno, sqlstate = db:query(sql2);
if not result_name then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"查询班级名称失败！\"}");
    return
end

-- responseObj.list = result_name

if bk_type == 107 then
        local sql_state = "SELECT CLASS_ID,STATE_ID from t_bag_sjstate where resource_id ='"..resource_id.."'";
		local class_state = db:query(sql_state);
		
		for j=1,#results_list do
		
			for k=1,#class_state do
				if (results_list[j]["class_id"] == class_state[k]["CLASS_ID"]) then
				result_name[j].class_open = class_state[k]["STATE_ID"];
				end
			
			end
		
		end
		
		
		--local class_state_info = "";
		--for i=1,#class_state do
		 --  class_state_info = class_state_info..","..class_state[i]["CLASS_ID"]..":"..class_state[i]["STATE_ID"];
		--end
		--if #class_state_info >0 then
		 --   class_state_info = string.sub(class_state_info,2,#class_state_info)
		--end
		--responseObj.class_open = class_state_info;	
end

responseObj.list = result_name

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