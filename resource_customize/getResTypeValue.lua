#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#陈丽月 2015-03-23
#描述：获取定制资源的类型值
]]
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

--参数：res_type

if args["res_type"]==nil or args["res_type"]=="" then
    ngx.say("{\"success\":\"false\",\"info\":\"2参数错误！\"}");
	ngx.log(ngx.ERR, "ERR MSG =====> 参数res_type不能为空！");
    return
end
local res_type = tostring(args["res_type"]);

local ResourceCustomize = require "resource_customize.model.ResourceCustomize";
local typeValueJson = ResourceCustomize: getResTypeValue(res_type);

local resultObj = typeValueJson;
--resultObj.success = true;
--resultObj  = typeValueJson;

--local cjson		= require "cjson";
--cjson.encode_empty_table_as_object(false);
--local resultJsonStr = cjson.encode(resultObj);
ngx.log(ngx.ERR, "===> 查询资源定制的类型值列表，返回的值：[<>]", resultObj, "[<>]");
ngx.print(resultObj);