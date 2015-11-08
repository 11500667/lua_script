local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--学生ID
if args["student_id"] == nil or args["student_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"student_id参数错误！\"}")
    return
end
local student_id = ngx.quote_sql_str(args["student_id"])

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

local subject_res= db:query("SELECT subject_id,subject_name FROM t_dm_subject WHERE SUBJECT_ID IN (SELECT SUBJECT_ID FROM t_base_class_subject WHERE CLASS_ID IN (SELECT CLASS_ID FROM t_base_student WHERE STUDENT_ID="..student_id.."))")
local subject_info = subject_res

local result = {}
result["success"] = true
result["list"] = subject_info

cjson.encode_empty_table_as_object(false);
ngx.say(cjson.encode(result))

