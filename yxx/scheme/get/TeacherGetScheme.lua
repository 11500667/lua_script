--[[
@Author cjl
@date 2015-7-15
--]]
local say = ngx.say;
local cjson = require "cjson";
--引用模块
local termModel = require "base.term.model.TermModel";
local personInfoModel = require "base.person.model.PersonInfoModel";
local schemeModel = require "yxx.scheme.model.SchemeModel";
--获取前台传过来的参数
local request_method = ngx.var.request_method
local args
if request_method == "GET" then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

local teacher_id = args["teacher_id"];
if not teacher_id  or string.len(teacher_id) == 0 then
    say("{\"success\":false,\"info\":\"teacher_id不能为空\"}");
    return
end
local subject_tab = personInfoModel:getTeachSubjectByPersonId(teacher_id);--获得认可计划
local row_choosed = schemeModel:get_scheme_by_teach(teacher_id,termModel:get_current_term());
local table = {};
table.success = false;
if subject_tab and row_choosed then
    if #subject_tab == #row_choosed then
        table.success = true;
    end
    table.list =  row_choosed;
end
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(table);
say(responseJson);

