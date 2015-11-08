--根据学校ID获取教师  by huyue 2015-08-24
--1.获得参数方法
local args = getParams();

--引用模块
local cjson = require "cjson"



local school_id=args["school_id"];

if school_id == nil or school_id == "" then
	ngx.say("{\"success\":false,\"info\":\"school_id参数错误！\"}");
	return;
else
  school_id = args["school_id"];
end


local personService = require "base.person.services.PersonService";
local result  = personService:getTeachersBySchId(school_id);

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))