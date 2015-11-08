--[[
功能：根据人员ID和身份ID获取班级信息
		如果是教师就返回所教授的班级
		如果是学生就返回所在班级
作者：吴缤
时间：2015-08-22
]]

local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--人员ID
if args["person_id"] == nil or args["person_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"person_id参数不允许为空！\"}")
    return
end
local person_id = args["person_id"]
--身份ID
if args["identity_id"] == nil or args["identity_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"identity_id参数不允许为空！\"}")
    return
end
local identity_id = args["identity_id"]

--连接mysql数据库
local mysql = require "resty.mysql"
local mysql_db = mysql:new()
mysql_db:connect{
	host = v_mysql_ip,
	port = v_mysql_port,
	database = v_mysql_database,
	user = v_mysql_user,
	password = v_mysql_password,
	max_packet_size = 1024*1024
}

local class_res = ""
if identity_id == "5" then
	class_res = mysql_db:query("SELECT T1.CLASS_ID,T2.CLASS_NAME FROM T_BASE_CLASS_SUBJECT T1 INNER JOIN t_base_class T2 ON T1.CLASS_ID=T2.CLASS_ID WHERE T1.B_USE = 1 AND T2.B_USE = 1 AND XQ_ID = (SELECT XQ_ID FROM t_base_term WHERE SFDQXQ = 1) AND TEACHER_ID="..person_id)
else
	class_res = mysql_db:query("SELECT T1.CLASS_ID,T2.CLASS_NAME FROM t_base_student T1 INNER JOIN t_base_class T2 ON T1.CLASS_ID=T2.CLASS_ID WHERE T2.B_USE = 1 AND STUDENT_ID="..person_id)
end

local class_tab = {}
for i=1,#class_res do
	local class_info = {}
	class_info["class_id"] = class_res[i]["CLASS_ID"]
	class_info["class_name"] = class_res[i]["CLASS_NAME"]
	class_tab[i] = class_info
end

local cjson = require "cjson"
local result = {}
result["success"] = true
result["list"] = class_tab

cjson.encode_empty_table_as_object(false)

ngx.print(cjson.encode(result))

