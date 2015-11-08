#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#张爱旭 2015-08-08
#描述：老师和学生获取已下载试卷的状态列表 
 参数：person_id：人员id    Ids：(小ID)试题的id的组合json字符串   identity_id：身份id 5 老师，6 学生
 涉及到的表：t_base_student、t_bag_sjstate、t_resource_sendstudent、t_bag_resource_info（弃用）改为t_resource_base
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
--获得人员id
if args["person_id"] == nil or args["person_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}");
    return;
end
local person_id = tonumber(args["person_id"]);
-- ngx.log(ngx.ERR, "$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$", person_id);
--获取已下载试卷的id
if args["resource_ids"] == nil or args["resource_ids"] == "" then
    ngx.say("{\"success\":false,\"info\":\"resource_ids参数错误！\"}");
    return;
end
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local resource_ids = cjson.decode(args["resource_ids"]);
local resource_ids_list = resource_ids.list;
if resource_ids_list == nil then
    ngx.say("{\"success\":false,\"info\":\"resource_ids参数list格式错误！\"}");
    return;
end
local res_str = "";
for i=1, #resource_ids_list do
	if resource_ids_list[i]["id"] == nil or resource_ids_list[i]["id"] == "" then
		ngx.say("{\"success\":false,\"info\":\"resource_ids参数list的id格式错误！\"}");
		return;
	end
	res_str = res_str..ngx.quote_sql_str(tostring(resource_ids_list[i]["id"]))..",";
end
if res_str ~= "" then
	res_str = string.sub(res_str,0,#res_str-1);
end
-- ngx.log(ngx.ERR, "$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$", res_str);
--获取当前用户身份identity_id 5：老师；6：学生
if args["identity_id"] == nil or args["identity_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"identity_id参数错误！\"}");
    return;
end
local identity_id = tonumber(args["identity_id"]);
-- ngx.log(ngx.ERR, "$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$", identity_id);
--3.连接数据库
local mysql = require "resty.mysql";
local db, err = mysql : new();
if not db then 
    ngx.log(ngx.ERR, err);
    return;
end

db:set_timeout(1000); -- 1 sec

local ok, err, errno, sqlstate = db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024 * 1024
}

if not ok then
    ngx.say("failed to connect: ", err, ": ", errno, " ", sqlstate);
    return;
end

--4.查询
local sql = "";
local list = nil;

if identity_id == 6 then
    sql = "SELECT class_id FROM t_base_student WHERE student_id = " ..person_id..";";
    list, err, errno, sqlstate = db:query(sql);
    if not list then
        ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
        ngx.say("{\"success\":\"false\",\"info\":\"查询数据CLASS_ID出错！\"}");
        return;
    end
    local class_id = list[1]["class_id"];
--	ngx.log(ngx.ERR, "$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$", class_id, "$$$$$$$$$$$$$$$$$$$$$$", #list);
    sql = "SELECT id AS stu_exam_id,state_id AS state,T1.resource_id AS tea_exam_id,(SELECT state_id FROM t_bag_sjstate T2 WHERE T2.resource_id=T1.resource_id AND T2.class_id="..class_id..") AS can_open,(SELECT is_exam FROM t_bag_sjstate T2 WHERE T2.resource_id=T1.resource_id AND T2.class_id="..class_id..") AS is_exam FROM t_resource_sendstudent T1 WHERE id IN ("..res_str..");";
else
    sql="SELECT IFNULL(b.is_exam,0) AS is_exam,a.resource_id_int AS resource_id,b.state_id AS state FROM t_resource_base a LEFT JOIN (SELECT resource_id,state_id,is_exam FROM t_bag_sjstate WHERE state_id=1 GROUP BY resource_id) b ON b.resource_id=a.resource_id_int WHERE a.resource_id_int IN ("..res_str..");";
end

list, err, errno, sqlstate = db:query(sql);
if not list then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return;
end

local result = {};
result["success"] = true;
result["list"] = list;

-- 5.将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

-- 6.返回值
local responseJson = tostring(cjson.encode(result));
ngx.say(responseJson);