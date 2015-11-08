--[[
@Author 陈续刚 
@desc 教师增加对错题的批阅，包括文本和附件
@date 2015-5-17
--]]
local cjson = require "cjson"
local quote = ngx.quote_sql_str
local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end
if tostring(args["class_id"])=="nil" or tostring(args["teacher_id"])=="nil" or tostring(args["question_id"])=="nil" or tostring(args["content"])=="nil" or tostring(args["target"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"class_id,teacher_id,question_id,content 参数错误\"}");
    return
end

local class_id = tostring(args["class_id"]);
local teacher_id = tostring(args["teacher_id"]);
local question_id = tostring(args["question_id"]);
local subject_id = tostring(args["subject_id"]);
local content = tostring(args["content"]);
local target = ngx.unescape_uri(args["target"]);
local t_target = cjson.decode(target);
local tj_question_ids = ngx.unescape_uri(args["tj_question_ids"]);
local tj_question_id = cjson.decode(tj_question_ids);
local wrongQuestionBookModel = require "yxx.wrong_question_book.model.wrongQuestionBookModel";
local personInfoModel = require "base.person.model.PersonInfoModel";
local class_tab = personInfoModel:getTeachClassesBySubject(teacher_id,subject_id);
local class_ids = wrongQuestionBookModel:getClassIdsByClassTab(class_tab);
--ngx.log(ngx.ERR,"##############"..class_ids.."###################");
wrongQuestionBookModel:addQuestionAnswer(class_ids,teacher_id,question_id,content,t_target,teacher_id,tj_question_id);
ngx.say("{\"success\":true}");