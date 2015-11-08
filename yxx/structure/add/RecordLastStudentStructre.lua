--[[
@Author cuijinlong
@date 2015-6-30
--]]
local say = ngx.say;
local cjson = require "cjson";
--引用模块
--获取前台传过来的参数
local request_method = ngx.var.request_method;
local args
if request_method == "GET" then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end
local student_id = args["student_id"];
local model_id = args["model_id"];
local subject_id = args["subject_id"];
local structure_id = args["structure_id"];
local pidstr = args["pidstr"];
if  not student_id or string.len(student_id) == 0
        or not subject_id or string.len(subject_id) == 0
            or not model_id or string.len(model_id) == 0
                or not structure_id or string.len(structure_id) == 0 then
    say("{\"success\":false,\"info\":\"参数错误！\"}");
    return
end
local table = {}
table.structure_id = structure_id;
if not pidstr or string.len(pidstr) == 0  then
    table.pidstr = "";
else
    table.pidstr = ngx.decode_base64(pidstr);
end
local structreModel = require "yxx.structure.model.StructreModel";
structreModel:save_structre_record(student_id,model_id,subject_id,table);
say("{\"success\":true,\"info\":\"保存成功\"}")
