--[[
	局部函数：访问其它请求，并将返回的值组装成table对象
	参数：url 	 		 接口地址
	参数：paramStr 	     参数字符串
	参数：methodType	 请求方式：GET 或 POST
]]
local function getResponseJson(url, paramStr, methodType)
	local response;
	if methodType == "GET" then
	
		response = ngx.location.capture(url .. "?" .. paramStr, {
			method = ngx.HTTP_GET
		});
		
	elseif methodType == "POST" then
	
		response = ngx.location.capture(url, {
			method = ngx.HTTP_POST,
			body = paramStr
		});
	end
	
	if response.status == 200 then
		local cjson = require "cjson";
		local responseJson = cjson.decode(response.body);
		ngx.log(ngx.ERR, "===> 调用接口的返回值 ===> " , response.body);
		return response.body;
	else
		-- return { success=true, info="访问请求失败！"};
		return "访问请求失败！";
	end
end 

-- local url = "/dsideal_yy/management/multiCheck/setCheckPerson";
-- paramStr = "unit_id=300529&param_json=%5B%7B%22person_id%22%3A259,%22identity_id%22%3A5,%22person_name%22%3A%22%E7%94%B3%E5%81%A5%22,%22stage_id%22%3A5,%22stage_name%22%3A%22%E5%88%9D%E4%B8%AD%22,%22subject_id%22%3A6,%22subject_name%22%3A%22%E6%95%B0%E5%AD%A6%22%7D,%7B%22person_id%22%3A259,%22identity_id%22%3A5,%22person_name%22%3A%22%E7%94%B3%E5%81%A5%22,%22stage_id%22%3A5,%22stage_name%22%3A%22%E5%88%9D%E4%B8%AD%22,%22subject_id%22%3A8,%22subject_name%22%3A%22%E7%89%A9%E7%90%86%22%7D%5D"
-- local result = getResponseJson(url, paramStr, ngx.var.request_method)

--------------------------------------------------------------------------

-- ngx.print("调用接口的返回值===> " .. result);

-- local url = "/dsideal_yy/management/multiCheck/delCheckPerson";
-- paramStr = "unit_id=300529&param_json=%5B%7B%22person_id%22%3A259,%22identity_id%22%3A5,%22subject_id%22%3A6%7D,%7B%22person_id%22%3A259,%22identity_id%22%3A5,%22subject_id%22%3A8%7D%5D"
-- local result = getResponseJson(url, paramStr, ngx.var.request_method)

-- ngx.print("调用接口的返回值===> " .. result);
--------------------------------------------------------------------------

-- local url = "/dsideal_yy/ypt/multiCheck/saveCheckResult";
-- paramStr = "unit_id=300529&check_msg=dddffffff&param_json=%5B%7B%22check_id%22%3A17,%22check_status%22%3A%2211%22%7D,%7B%22check_id%22%3A19,%22check_status%22%3A%2211%22%7D%5D"
-- local result = getResponseJson(url, paramStr, ngx.var.request_method)

-- ngx.print("调用接口的返回值===> " .. result);
--------------------------------------------------------------------------

-- local url = "/dsideal_yy/ypt/multiCheck/modifyCheckStatus";
-- paramStr = "unit_id=100007&check_id=34&check_status=12&check_msg=dddffffff"
-- local result = getResponseJson(url, paramStr, ngx.var.request_method)

-- ngx.print("调用接口的返回值===> " .. result);
--------------------------------------------------------------------------

local raw_value="'dfdfdfdf' "
local quoted_value = ngx.quote_sql_str(raw_value);
ngx.print("===> 处理后的值 ===> " .. quoted_value);

-- 测试SQL注入
local raw_value="'fffs''dfdf"
local quoted_value = ngx.quote_sql_str(raw_value);
--ngx.say("防止sql注入："..raw_value..'       :'..quoted_value);

local sql = "insert into cats (name) values (\'Bob\'),(\'\'),(null),("..quoted_value..")";
ngx.log(ngx.ERR, "===> sql : [", sql, "]");




