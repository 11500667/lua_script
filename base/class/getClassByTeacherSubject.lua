local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--教师ID
if args["teacher_id"] == nil or args["teacher_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"teacher_id参数错误！\"}")
    return
end
local teacher_id = ngx.quote_sql_str(args["teacher_id"])

--科目ID
if args["subject_id"] == nil or args["subject_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"subject_id参数错误！\"}")
    return
end
local subject_id = ngx.quote_sql_str(args["subject_id"])

local cjson = require "cjson"

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
-- 陈续刚 于 2015.05.16修改，只检索当前学期的班级

local class_res= db:query("SELECT class_id,class_name FROM t_base_class WHERE B_USE=1 AND CLASS_ID IN (SELECT CLASS_ID FROM t_base_class_subject WHERE TEACHER_ID="..teacher_id.." AND SUBJECT_ID="..subject_id..") ORDER BY class_id")
--[[
local class_res= db:query("SELECT class_id,class_name FROM t_base_class WHERE B_USE=1 AND CLASS_ID IN (SELECT CLASS_ID FROM t_base_class_subject t2,t_base_term t3   WHERE TEACHER_ID="..teacher_id.." AND SUBJECT_ID="..subject_id.." and t3.XQ_ID = t2.XQ_ID and t3.SFDQXQ=1) ORDER BY class_id")
]]
local class_info = class_res

local result = {}
result["success"] = true
result["list"] = class_info

ngx.say(cjson.encode(result))

