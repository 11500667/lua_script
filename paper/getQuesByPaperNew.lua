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

if args["id"] == nil or args["id"]=="" then
	ngx.say("{\"success\":\"false\",\"info\":\"参数id不能为空！\"}");
	return;
--elseif args["kg_zg"] == nil or args["kg_zg"]=="" then
--	ngx.say("{\"success\":\"false\",\"info\":\"参数kg_zg不能为空！\"}");
--	return;
end

local id = tostring(args["id"]);
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

db:set_timeout(5000) -- 1 sec

local ok, err, errno, sqlstate = db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024 * 1024 }

if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\"连接数据库失败！\"}")
	ngx.log(ngx.ERR, "=====> 连接数据库失败!");
    return
end
--local info_sql ="SELECT PAPER_ID_INT FROM t_sjk_paper_info WHERE ID="..id;

--ngx.log(ngx.ERR,"paperIdInt"..info_sql);
--[[
local results, err, errno, sqlstate = db:query(info_sql);
if not results then
	ngx.log(ngx.ERR, " ===> bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}")
    return
end
local paperIdInt = results[1]["PAPER_ID_INT"];
]]
--ngx.log(ngx.ERR,"paperIdInt"..results[1]["PAPER_ID_INT"]);

--local sql = "SELECT ID FROM T_TK_QUESTION_INFO WHERE PAPER_ID_INT=".. paperIdInt .. " AND KG_ZG=" .. kgZg;
local sql = "SELECT T2.FILE_ID,T1.KG_ZG AS KG_ZG,T1.QUESTION_ID_CHAR AS QUESTION_ID_CHAR,T2.QUESTION_ANSWER AS QUESTION_ANSWER,T1.QUESTION_TYPE_ID AS QUESTION_TYPE_ID, T1.SORT_ID FROM T_TK_QUESTION_INFO AS T1,T_TK_QUESTION_BASE AS T2 WHERE T1.QUESTION_ID_CHAR = T2.QUESTION_ID_CHAR AND T1.PAPER_ID_INT =".. id .. " ORDER BY T1.SORT_ID";

--local sql = "SELECT SQL_NO_CACHE ID FROM T_TK_QUESTION_INFO_SPHINXSE WHERE QUERY='filter=paper_id_int, " .. paperIdInt .. "'";
local cjson = require "cjson";
local res, err, errno, sqlstate = db:query(sql);
--ngx.log(ngx.ERR, "===> 试卷下的试题的查询结果 ===> ", cjson.encode(res));
if not res then
	ngx.log(ngx.ERR, " ===> bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}")
    return
end


cjson.encode_empty_table_as_object(false);

local responseJson = {};
local quesArray = {};

ngx.log(ngx.ERR, "===> res length ===> ", #res);

for i=1, #res do

	local record = {}
	record.file_id 	= res[i].FILE_ID;
	record.kg_zg 	= res[i].KG_ZG;
	record.question_answer 	= ngx.encode_base64(res[i].QUESTION_ANSWER);
	record.question_id_char = res[i].QUESTION_ID_CHAR;
	record.question_type_id = res[i].QUESTION_TYPE_ID;
	record.sort_id 	= res[i].SORT_ID
		
	table.insert(quesArray, record);
	
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




