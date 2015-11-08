--
-- 学情分析 -> 获取教师任教的所有科目
-- 请求方式：GET
-- 作者: 申健
-- 日期: 2015/5/6 09:31
--

local requestMethod = ngx.var.request_method;
local args;
if requestMethod == "GET" then
	args = ngx.req.get_uri_args();
else
	ngx.req.read_body();
	args = ngx.req.get_post_args();
end

if args["teacher_id"] == nil or args["teacher_id"] == "" then
	ngx.log(ngx.ERR, "===> 获取教师任教的所有科目, 错误信息-> 参数 [teacher_id] 为空！");
	ngx.print("{ \"success\": false, \"info\": \"参数teacher_id不能为空。\" }");
	return;
end

local teacherId = args["teacher_id"];

local personService = require "base.person.services.PersonService";
local resultJsonObj = personService: getTeachSujbect(teacherId);

local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(resultJsonObj));