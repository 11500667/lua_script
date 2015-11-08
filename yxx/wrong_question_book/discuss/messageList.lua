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
if args["class_id"] == nil or args["class_id"]=="" or args["question_id"] == nil or args["question_id"]=="" then
	ngx.print("{\"success\":false,\"info\":\"class_id,question_id不能为空！\"}");
	return;
end
local class_id = args["class_id"];
local question_id = args["question_id"];
local subject_id = args["subject_id"];
local class_id_deal = '';
if class_id == '-1' and tonumber(ngx.var.cookie_identity_id) == 5 then  --如果班级老师查询全部班级的错题，那么将老师任教的班级ID进行处理。
	local classes = ngx.location.capture("/dsideal_yy/base/getClassByTeacherIdSubjectId",{
			args={teacher_id = tostring(ngx.var.cookie_person_id),subject_id=subject_id}
	});
	local class
	if classes.status == 200 then
		class = cjson.decode(classes.body).list
	else
		say("{\"success\":false,\"info\":\"查询班级失败！\"}")
		return
	end
	for i=1,#class do
        class_id_deal = class_id_deal..class[i].class_id..',';
	end
	class_id_deal = string.sub(class_id_deal,1, #class_id_deal-1);
else 
	class_id_deal = class_id;
end

local discussModel = require "yxx.wrong_question_book.model.discussModel";
--学生获得我的错题列表
local return_list = discussModel:message_list(question_id,class_id_deal)
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(return_list);
say(responseJson);