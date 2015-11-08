--[[
@Author chuzheng
@date 2014-12-18
--]]
local say = ngx.say
--引用模块
--获取前台传过来的参数
local request_method = ngx.var.request_method
local args
if request_method == "GET" then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end
local student_id = args["student_id"];
local subject_id = args["subject_id"];
local model_id = args["model_id"];
if  not student_id or string.len(student_id) == 0
        or not model_id or string.len(model_id) == 0
            or not subject_id or string.len(subject_id) == 0 then
    say("{\"success\":false,\"info\":\"参数错误！\"}");
    return
end
local structreModel = require "yxx.structure.model.StructreModel";
local table = structreModel:get_structre_record(student_id,model_id,subject_id);
if table and table.pidstr ~= nil then
    say("{\"success\":true,\"structure_id\":\""..table.structure_id.."\",\"pidstr\":\""..table.pidstr.."\"}")
else
    say("{\"success\":false}")
end

