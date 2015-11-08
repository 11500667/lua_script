--获取人员信息的接口 by huyue 2015-08-22 

--1.获得参数方法
local args = getParams();

--引用模块
local cjson = require "cjson"



local person_id=args["person_id"];

if person_id == nil or person_id == "" then
	ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}");
	return;
else
  person_id = args["person_id"];
end

local identity_id=args["identity_id"];

if identity_id == nil or identity_id == "" then
	ngx.say("{\"success\":false,\"info\":\"identity_id参数错误！\"}");
	return;
else
  identity_id = args["identity_id"];
end

local personService = require "base.person.services.PersonService";
local result  = personService:getPersonInfo(person_id,identity_id);

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))