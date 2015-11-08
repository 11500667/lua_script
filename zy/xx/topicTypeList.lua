#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
@Author cuijinlong
@date 2015-4-24
--]]
local say = ngx.say
local cjson = require "cjson"
--  获取request的参数
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then 
	args = ngx.req.get_uri_args(); 
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end
local subject_id = args["subject_id"];
--local topicTypeNameStr = ngx.decode_base64(tostring(topicTypeName));
local dbUtil = require "yxx.wrong_question_book.util.DbUtil";
local mysql_db = dbUtil:getMysqlDb();
--保存错题本（mysql）
local rows, err, errno, sqlstate = mysql_db:query("select id,topic_type_name from t_topic_type where subject_id = "..subject_id);
if not rows then
	ngx.print("{\"success\":\"false\",\"info\":\"查询数据出错。\"}");
	return;
end
local topicArray = {}
for i=1,#rows do
	local ssdb_info = {};
	ssdb_info["topic_type_id"] = rows[i]["id"];									--错题时间
	ssdb_info["topic_type_name"] = rows[i]["topic_type_name"];									--错题时间
	table.insert(topicArray, ssdb_info);
end
local topicListJson = {};
topicListJson.success    = true;
topicListJson.list = topicArray;
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(topicListJson);
say(responseJson);
mysql_db:set_keepalive(0,v_pool_size);