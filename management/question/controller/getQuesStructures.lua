-- 获取参数
local request_method = ngx.var.request_method
local quote = ngx.quote_sql_str;


local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

local p_question_id_char = args["question_id_char"]

--参数：试题的GUID
if not p_question_id_char then
	ngx.say("{\"success\":false,\"info\":\"参数question_id_char不能为空！\"}")
	return
end


if p_question_id_char == "" then
    ngx.say("{\"success\":false,\"info\":\"参数question_id_char不能为空！\"}");
    return
end


local cjson = require "cjson"


-- 获取数据库连接
local DBUtil   = require "common.DBUtil";
local db = DBUtil: getDb();

local sql_queryStruc = "select id, structure_id_int, structure_path from t_tk_question_info where question_id_char=" .. quote(p_question_id_char) .. " and b_delete=0 and b_in_paper=0 and group_id=1 and create_person=1 and oper_type=1 group by structure_id_int";

local results, err, errno, sqlstate = db:query(sql_queryStruc);

if not results or #results == 0 then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".")
    ngx.say("{\"success\":false,\"info\":\"获取试题的结构信息出错！\"}")
    return
end 


local resultJsonObj = {}

local strucJsonObj = {}
for i=1, #results do
	local strucIdInt = results[i]["structure_id_int"]
	local strucPath = results[i]["structure_path"]
	local strucObj = {}
	strucObj.structure_id_int = strucIdInt
	strucObj.structure_path = strucPath
	strucJsonObj[i] = strucObj
end

resultJsonObj.structure_json = strucJsonObj
resultJsonObj.success = true
resultJsonObj.question_id_char = p_question_id_char

local resultJsonStr = cjson.encode(resultJsonObj)

DBUtil: keepDbAlive(db);

ngx.say(resultJsonStr);






