#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-02-12
#描述：获得这个老师的这个微课发给哪个班级了
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
 


--接收参数
--老师id
local teacher_id = tostring(args["teacher_id"])
--判断是否有结点ID参数
if teacher_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"teacher_id参数错误！\"}")
    return
end
--wk_id
local wk_id = tostring(args["wk_id"])
if wk_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"wk_id参数错误！\"}")
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
ngx.log(ngx.ERR,"SELECT type,classorgroup_id FROM  t_wkds_wktoclassgroup WHERE WK_ID ="..wk_id.." AND TEACHER_ID = "..teacher_id);
local class_info = db:query("SELECT type,classorgroup_id FROM  t_wkds_wktoclassgroup WHERE WK_ID ="..wk_id.." AND TEACHER_ID = "..teacher_id);

local responseObj = {};
local class_tab = {};
  for i=1,#class_info do
     local tab = {};
	 tab.type_id = class_info[i]["type"];
	 tab.classorgroup_id =class_info[i]["classorgroup_id"];
     class_tab[i] = tab;
  end
  
responseObj.success = true;
responseObj.list= class_tab;

-- 5.将table对象转换成json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(responseObj);

--mysql放回连接池
db:set_keepalive(0,v_pool_size)
ngx.say(responseJson);











