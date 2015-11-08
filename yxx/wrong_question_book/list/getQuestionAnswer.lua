--[[
@Author 陈续刚 
@desc 获取教师对错题的解答，包括文本和附件
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

if tostring(args["question_id"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"question_id 参数错误\"}")    
    return
end

--参数
local teacher_id = tostring(args["teacher_id"])
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

local query_condition = "";
if class_id ~= "nil" then
    --query_condition = " and class_id like '%,"..class_id..",%'"
elseif teacher_id ~= "nil" then
    query_condition = " and teacher_id="..teacher_id;
end

local create_time = os.date("%Y-%m-%d %H:%M:%S");
local select_sql = "select id,class_id,teacher_id,question_id,content,dtype,file_path,tj_question_id from t_question_teacher_answer where question_id = "..question_id..query_condition;
ngx.log(ngx.ERR,"###############"..select_sql.."###############");
local hdzy_res = db:query(select_sql)
local result = {}
result["content"] = ""
local fujian = {}
local tjst = {}
local sds = #hdzy_res
for i=1,#hdzy_res do
	local answer = {}
	local id = hdzy_res[i]["id"]
	local class_id = hdzy_res[i]["class_id"]
	local teacher_id = hdzy_res[i]["teacher_id"]
	local question_id = hdzy_res[i]["question_id"]
	local content = hdzy_res[i]["content"]
	local dtype = hdzy_res[i]["dtype"]
	local file_path = hdzy_res[i]["file_path"]
	local tj_question_id = hdzy_res[i]["tj_question_id"]
	
	result["class_id"] = class_id
	result["teacher_id"] = teacher_id
	result["question_id"] = question_id
	--answer["dtype"] = dtype
	if dtype == 1 then--文字
		result["content"] = content
	elseif dtype == 2 then--附件
		answer["id"] = id
		answer["file_name"] = content
		answer["file_path"] = file_path
		fujian[#fujian+1] = answer
	else
		result["id"] = id
		answer["tj_question_id"] = tj_question_id
		tjst[#tjst+1] = answer
	end
end
-- 
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end


result["success"] = true
result["fujian"] = fujian
result["tjst"] = tjst

cjson.encode_empty_table_as_object(false)
ngx.say(tostring(cjson.encode(result)))