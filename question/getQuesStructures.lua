#ngx.header.content_type = "text/plain;charset=utf-8"
local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)

--判断是否有person_id的cookie信息
if cookie_person_id == "nil" or cookie_identity_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"notlogin\"}")
	ngx.log(ngx.ERR, "Cookie中的人员信息不全！")
    return
end

-- 获取参数
local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end
--参数：试题的GUID
if not args["question_id_char"] then
	ngx.say("{\"success\":false,\"info\":\"参数question_id_char不能为空！\"}")
	return
end

local p_question_id_char = args["question_id_char"]

if p_question_id_char == "" then
    ngx.say("{\"success\":false,\"info\":\"参数question_id_char不能为空！\"}");
    return
end

-- 获取数据库连接
local cjson = require "cjson"
local mysql = require "resty.mysql"
local db, err = mysql : new();
if not db then 
	ngx.say("{\"success\":false,\"info\":\"获取数据库连接出错！\"}")
	ngx.log(ngx.ERR, "获取数据库连接出错，错误信息：" .. err);
	return;
end

db:set_timeout(1000) -- 1 sec

local ok, err, errno, sqlstate = db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024 * 1024 
}

if not ok then
    ngx.log(ngx.ERR, "failed to connect: ", err, ": ", errno, " ", sqlstate)
    ngx.say("{\"success\":false,\"info\":\"连接数据库服务器出错！\"}")
    return
end


local sql_queryStruc = "SELECT ID, STRUCTURE_ID_INT, STRUCTURE_PATH FROM T_TK_QUESTION_INFO WHERE QUESTION_ID_CHAR='" .. p_question_id_char .. "' AND B_DELETE=0 AND B_IN_PAPER=0 AND OPER_TYPE=1 AND CREATE_PERSON="..cookie_person_id.." GROUP BY STRUCTURE_ID_INT"

local results, err, errno, sqlstate = db:query(sql_queryStruc);

if not results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".")
    ngx.say("{\"success\":false,\"info\":\"获取试题的结构信息出错！\"}")
    return
end 

if #results == 0 then
    ngx.say("{\"success\":false,\"info\":\"获取试题的结构信息出错！\"}")
    return
end 

local resultJsonObj = {}

local strucJsonObj = {}
for i=1, #results do
	local strucIdInt = results[i]["STRUCTURE_ID_INT"]
	local strucPath = results[i]["STRUCTURE_PATH"]
	
	local strucObj = {}
	strucObj.structure_id_int = strucIdInt
	strucObj.structure_path = strucPath
	
	strucJsonObj[i] = strucObj	
end

resultJsonObj.structure_json = strucJsonObj
resultJsonObj.success = true
resultJsonObj.question_id_char = p_question_id_char

local resultJsonStr = cjson.encode(resultJsonObj)

ngx.say(resultJsonStr)

-- 将mysql连接归还到连接池
local ok, err = db:set_keepalive(0, v_pool_size);
if not ok then
    ngx.log(ngx.ERR, "failed to set keepalive: ", err)
    return
end




