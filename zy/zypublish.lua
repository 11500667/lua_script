--[[
作业发布
@Author chuzheng
@date 2014-12-25
--]]
local say = ngx.say;
local cjson = require "cjson";
local StringUtil = require "yxx.tool.StringUtil";
local DbUtil = require "yxx.tool.DbUtil";
local ZyModel = require "zy.model.zyModel";
--获取前台传过来的参数
local request_method = ngx.var.request_method;
local args = nil;
if request_method == "GET" then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end
local zy_id=args["zy_id"]
local teacher_id = ngx.var.cookie_person_id
if not teacher_id or string.len(teacher_id) == 0 or not zy_id or string.len(zy_id) == 0  then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end
local db = DbUtil:getMysqlDb();
local ssdb = DbUtil:getSSDb();
local param = cjson.decode(ssdb:hget("homework_zy_content",zy_id)[1]);
param.is_public=1;
local subject_id = param.subject_id;
ZyModel:save_student_zy_relate(zy_id,subject_id,teacher_id,param.class_id_arrs,param.group_id_arrs);--将作业下发给学生
ssdb:hset("homework_zy_content",zy_id,cjson.encode(param));--更改作业信息中的发布字段信息
db:query("update t_zy_info set UPDATE_TS="..ngx.quote_sql_str(StringUtil:getTimestamp())..",IS_PUBLIC=1  where ID="..zy_id);
say("{\"success\":true,\"info\":\"发布成功\"}");
ssdb:set_keepalive(0,v_pool_size)
db:set_keepalive(0,v_pool_size)
