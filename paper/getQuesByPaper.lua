#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#申健 2014-12-22
#描述：根据试卷获取试题
]]

-- 2. 获取request的参数
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["paper_id_int"] == nil or args["paper_id_int"]=="" then
	ngx.say("{\"success\":\"false\",\"info\":\"参数paper_id不能为空！\"}");
	return;
--elseif args["kg_zg"] == nil or args["kg_zg"]=="" then
--	ngx.say("{\"success\":\"false\",\"info\":\"参数kg_zg不能为空！\"}");
--	return;
end

local paperIdInt = tostring(args["paper_id_int"]);
--local kgZg = tostring(args["kg_zg"]);

-- 获取redis连接
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

-- 3. 获取数据库连接
local mysql = require "resty.mysql";
local db, err = mysql : new();
if not db then 
	ngx.log(ngx.ERR, err);
	return;
end

db:set_timeout(3000) -- 1 sec

local ok, err, errno, sqlstate = db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024 * 1024 }

if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}")
	ngx.log(ngx.ERR, "=====> 连接数据库失败!");
    return
end


--local sql = "SELECT ID FROM T_TK_QUESTION_INFO WHERE PAPER_ID_INT=".. paperIdInt .. " AND KG_ZG=" .. kgZg;
  local sql = "SELECT ID FROM T_TK_QUESTION_INFO WHERE PAPER_ID_INT=".. paperIdInt;
local res, err, errno, sqlstate = db:query(sql);
if not res then
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}")
    return
end

local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);

local responseJson = {};
local quesArray = {};

ngx.log(ngx.ERR, "===> res length ===> ", #res);

for i=1, #res do
	local record = {}
	local quesInfoId = res[i]["ID"];
	ngx.log(ngx.ERR, "===> quesInfoId ===> ", quesInfoId);
	
	local quesJsonTable = cache:hmget("question_"..quesInfoId, "json_question", "json_answer");
	if not quesJsonTable then
		table.insert(quesArray, {}); 
	else
		
		local quesJsonStr = ngx.decode_base64(quesJsonTable[1]);
		ngx.log(ngx.ERR, "===> quesJsonStr ===> ", quesJsonStr);
		local answerJsonStr = ngx.decode_base64(quesJsonTable[2]);
		ngx.log(ngx.ERR, "===> answerJsonStr ===> ", answerJsonStr);
		
		if not answerJsonStr then
			record.question_answer = "未找到答案";
		else
			local answerObj = cjson.decode(answerJsonStr);
			record.question_answer = answerObj.answer;
		end
		
		if not quesJsonStr then
			table.insert(quesArray, {}); 
		else
			local quesObj = cjson.decode(quesJsonStr);
			record.file_id 			  = quesJsonTable.t_id;
			record.question_id_char   = quesJsonTable.question_id_char;
			record.question_type_id   = quesJsonTable.qt_type;
			record.kg_zg 	          = quesJsonTable.qt_id;
			record.sort_id 	          = quesJsonTable.sort_id;
		
			table.insert(quesArray, record); 
		end 
	end
	
end

responseJson.success = true;
responseJson.table_List = quesArray;

local responseJsonStr = cjson.encode(responseJson);
ngx.say(responseJsonStr);

-- 将redis连接归还到连接池
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
	ngx.log(ngx.ERR, "====>将Redis连接归还连接池出错！");
end

-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end




