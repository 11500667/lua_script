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
local subject_id = args["Subject"];
local topicTypeName = args["topicTypeName"];
--local topicTypeNameStr = ngx.decode_base64(tostring(topicTypeName));
local dbUtil = require "yxx.wrong_question_book.util.DbUtil";
local mysql_db = dbUtil:getMysqlDb();
--保存错题本（mysql）

mysql_db:query("INSERT INTO t_topic_type("..
							  "subject_id,"..		--讨论ID
							  "topic_type_name".. 		--错题ID
							  ")"..
					" VALUES ( "..
								subject_id..",'"..topicTypeName.."');");
mysql_db:set_keepalive(0,v_pool_size);
say("{\"success\":true,\"info\":\"保存成功\"}");
