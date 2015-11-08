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
if not args["question_id"] or string.len(args["question_id"]) == 0 then
	say("{\"success\":false,\"info\":\"参数错误！\"}")
	return
end
local discussModel = require "yxx.wrong_question_book.model.discussModel";
local ssdb_info = {};
ssdb_info["question_id"] = args["question_id"];				 					--试题ID
ssdb_info["person_id"] = args["person_id"];				 						--发送人ID
ssdb_info["class_id"] = args["class_id"];				 						--班级ID
ssdb_info["person_name"] = ngx.decode_base64(tostring(args["person_name"]));	--班级ID
ssdb_info["identity_id"] = args["identity_id"];				 					--班级ID
ssdb_info["avatar_url"] = args["avatar_url"]									--头像
ssdb_info["content_info"] = args["content_info"];								--发送内容
ssdb_info["create_time"] = ngx.localtime();										--发送时间
discussModel:send_message(ssdb_info);
say("{\"success\":true,\"info\":\"保存成功\"}");
