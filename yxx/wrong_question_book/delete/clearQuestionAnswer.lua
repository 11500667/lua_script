--[[
@Author 陈续刚 
@desc 清空教师对错题的解答，包括文本和附件
@date 2015-5-17
--]]
local cjson = require "cjson"
local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

if tostring(args["class_id"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"class_id 参数错误\"}")    
    return
end

if tostring(args["question_id"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"question_id 参数错误\"}")    
    return
end

--参数
local class_id = tostring(args["class_id"])
local question_id = tostring(args["question_id"])

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

local create_time = os.date("%Y-%m-%d %H:%M:%S");
local delete_sql = "delete from t_question_teacher_answer where class_id="..class_id.." and question_id = "..question_id.."";

db:query(delete_sql)
-- 
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

local result = {}
result["success"] = true

cjson.encode_empty_table_as_object(false)
ngx.say(tostring(cjson.encode(result)))