--
-- 学情分析 -> 获取教师在指定科目下任教的班级,
--             此接口没有用到，使用已有接口base/class/getTeachClassBySubject.lua
-- 请求方式：GET
-- 作者: 申健
-- 日期: 2015/5/6 10:04
--
ngx.log(ngx.ERR, "[sj_log]->[person_info]->  获取指定科目下教师任教的班级--> 开始");
local requestMethod = ngx.var.request_method;
local args;
if requestMethod == "GET" then
	args = ngx.req.get_uri_args();
else
	ngx.req.read_body();
	args = ngx.req.get_post_args();
end

if args["teacher_id"] == nil or args["teacher_id"] == "" then
	ngx.log(ngx.ERR, "[sj_log]->[person_info]->  获取指定科目下教师任教的班级, 错误信息-> 参数 [teacher_id] 为空！");
	ngx.print("{ \"success\": false, \"info\": \"参数teacher_id不能为空。\" }");
	return;
elseif args["class_id"] == nil or args["class_id"] == "" then
	ngx.log(ngx.ERR, "[sj_log]->[person_info]->  获取指定科目下教师任教的班级, 错误信息-> 参数 [class_id] 为空！");
	ngx.print("{ \"success\": false, \"info\": \"参数class_id不能为空。\" }");
	return;
end

local teacherId = args["teacher_id"];
local classId   = args["class_id"];

local personService = require "base.person.services.PersonService";
local resultJsonObj = personService: getTeachClassesBySubject(teacherId, classId);

local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
ngx.log(ngx.ERR, "[sj_log]->[person_info]->  获取指定科目下教师任教的班级, 返回给前台的信息-> ", cjson.encode(resultJsonObj));
ngx.print(cjson.encode(resultJsonObj));