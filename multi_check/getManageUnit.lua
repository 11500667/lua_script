#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#申健 2015-03-07
#描述：获取用户所管理的区域
]]

if ngx.var.cookie_background_person_id == nil or ngx.var.cookie_background_person_id=="" then 
	ngx.say("{\"success\":\"false\",\"info\":\"从cookie中获取person_id失败！\"}")
    return
elseif ngx.var.cookie_background_identity_id == nil or ngx.var.cookie_background_identity_id=="" then 
	ngx.say("{\"success\":\"false\",\"info\":\"从cookie中获取identity_id失败！\"}")
    return
end

local personId   = tonumber(ngx.var.cookie_background_person_id);
local identityId = tonumber(ngx.var.cookie_background_identity_id);

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
		return responseJson;
	else
		return { success=true, info="访问请求失败！"};
	end
end 

-- 获取调用此请求的方式GET/POST
local request_method = ngx.var.request_method;
-- 要访问的接口url
local url = "/dsideal_yy/management/person/getOrgInfoByPerson";
-- 调用接口所传递的参数
local paramStr = "person_id=".. personId .. "&identity_id=" .. identityId ;

local unitId = 0;
local unitName = "";
local unitJson;
if identityId == 8 then -- 省管理员
	
	paramStr = paramStr .. "&type=1";
	unitJson = getResponseJson(url, paramStr, request_method);
	unitId 	 = unitJson.province_id;
	unitName = unitJson.province_name;
elseif identityId == 9 then -- 市管理员
	
	paramStr = paramStr .. "&type=2";
	unitJson = getResponseJson(url, paramStr, request_method);
	unitId 	 = unitJson.city_id;
	unitName = unitJson.city_name;
elseif identityId == 10 then -- 区管理员
	
	paramStr = paramStr .. "&type=3";
	unitJson = getResponseJson(url, paramStr, request_method);
	unitId 	 = unitJson.district_id;
	unitName = unitJson.district_name;
elseif identityId == 4 then -- 学校管理员
	
	paramStr = paramStr .. "&type=4";
	unitJson = getResponseJson(url, paramStr, request_method);
	unitId   = unitJson.school_id;
	unitName = unitJson.school_name;
end

local responseObj = {};
responseObj.success   = true;
responseObj.unit_id   = unitId;
responseObj.unit_name = unitName;

local cjson = require "cjson";
local responseJsonStr = cjson.encode(responseObj);
ngx.say(responseJsonStr);
