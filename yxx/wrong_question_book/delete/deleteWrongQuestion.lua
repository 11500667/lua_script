--[[
@Author cuijinlong
@date 2015-4-24
--]]
local say = ngx.say
local cjson = require "cjson"
--  ��ȡrequest�Ĳ���
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then 
	args = ngx.req.get_uri_args(); 
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

local ssdb_info = {};
--[[ ssdb_info["student_id"]= ;					--ѧ��ID
ssdb_info["class_id"] = 2200;											--�༶ID
ssdb_info["subject_id"] = tonumber(args["subject_id"]);					--ѧ��
ssdb_info["knowledge_point"] = tonumber(args["knowledge_point"]);		--֪ʶ��
ssdb_info["create_source"] = tonumber(args["create_source"]);			--������Դ
ssdb_info["create_time"] = ngx.localtime();								--����ʱ��
ssdb_info["stu_answer"] = args["stu_answer"];							--ѧ����
ssdb_info["cause_content"] = tonumber(args["cause_content"]);			--����ԭ��
ssdb_info["quality_goods"] = tonumber(args["quality_goods"]);			--�Ƿ�Ʒ
ssdb_info["priority_levels"] = tonumber(args["priority_levels"]);		--�������ȼ�
ssdb_info["question_id"] = ;				--����ID ]]
ssdb_info["student_id"]= 25;							--ѧ��ID
ssdb_info["class_id"] = 0941;							--�༶ID
ssdb_info["subject_id"] =6;								--ѧ��
ssdb_info["knowledge_point"] = 402;						--֪ʶ��
ssdb_info["create_source"] =1;							--������Դ
ssdb_info["create_time"] = ngx.localtime();				--����ʱ��
ssdb_info["stu_answer"] = "A";							--ѧ����
ssdb_info["cause_content"] = 1;							--����ԭ��
ssdb_info["quality_goods"] = 2;							--�Ƿ�Ʒ
ssdb_info["priority_levels"] = 3;						--�������ȼ�
ssdb_info["question_id"] = 1000000009;				--����ID

local wrongQuestionBookModel = require "yxx.wrong_question_book.model.wrongQuestionBookModel";
wrongQuestionBookModel:wq_delete(student_id,question_id,wq_id);
say("{\"success\":true,\"info\":\"�ɹ��Ƴ�����\"}")