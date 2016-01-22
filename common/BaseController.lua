-- -----------------------------------------------------------------------------------
-- 函数描述： 公有类 -> Controller的基础函数类, 注意使用此类，只支持一层封装，
--            即在nginx的配置文件中进行配置时，
--            如果配置的路径为 /dsideal_yy/test,则支持的路径只能为test的下一级请求，
--            例如：/dsideal_yy/test/test1,不支持/dsideal_yy/test/test1/test11
-- 日    期： 2015年8月15日
-- 作    者： 申健
-- -----------------------------------------------------------------------------------
_BaseController = { __index = _BaseController };

-- ----------------------- example code ----------------------------------------------
-- ***1. nginx配置：
-- location /dsideal_yy/testUri
-- {
-- 		content_by_lua_file /usr/local/lua_script/test_java_request.lua;
-- }

-- ***2. test_java_request.lua 代码：

-- local _TestController = {};

-- function _TestController: testUri2() 
    -- local paramValue1 = self: getParamByName("param1", true);
    -- local paramValue2 = self: getParamToNumber("param2");
    -- local paramValue3 = self: getParamToNumber("param3");
	
	-- local result = {};
	-- result.param1 = paramValue1;
	-- result.param2 = paramValue2;
	-- result.param3 = paramValue3;
	
	-- self: printJson(result);
-- end

-- function _TestController: testUri3()
	-- self: printJson("ssssssssssssssssssssssssssssssss");
-- end
-- -- 此行很重要
-- BaseController: initController(_TestController);

-- ***3. 测试url：
-- 访问1：http://10.10.3.199/dsideal_yy/testUri/testUri2?param1=val1&param2=256
-- 访问2：http://10.10.3.199/dsideal_yy/testUri/testUri3

-- ----------------------- example code ----------------------------------------------


-- -----------------------------------------------------------------------------------
-- 函数描述： Controller公有函数 -> 初始化Controller
-- 日    期： 2015年8月15日
-- 作    者： 申健
-- 参    数： 无
-- 返 回 值： string类型：需要调用的函数名；如果获取失败，则返回nil；
-- -----------------------------------------------------------------------------------
function _BaseController: initController(newController)
    newController = newController or {};
    setmetatable(newController, _BaseController);
    self.__index = self;
	
	newController: run();
    return newController;
end

-- -----------------------------------------------------------------------------------
-- 函数描述： Controller公有函数 -> 根据当前请求的路径，获取需要调用的Controller文件中的函数名
-- 日    期： 2015年8月15日
-- 作    者： 申健
-- 参    数： 无
-- 返 回 值： string类型：需要调用的函数名；如果获取失败，则返回nil；
-- -----------------------------------------------------------------------------------
function _BaseController: getMethodNameByUri()
    -- 获取当前请求的url地址
	local reqUrl = ngx.var.uri;
	ngx.log(ngx.ERR, "\n[sj_log] -> [BaseController] -> 当前请求的地址：[", reqUrl, "]\n");
    local uriTable = string.split(reqUrl, "/");
    local lastUriStr = uriTable[#uriTable];
    ngx.log(ngx.ERR, "\n[sj_log] -> [BaseController] -> 要请求的函数：[", lastUriStr, "]\n");
	
    if lastUriStr ~= nil and lastUriStr ~= "" then
        return lastUriStr;
    else
        return nil;
    end
end

-- -----------------------------------------------------------------------------------
-- 函数描述： Controller公有函数 -> 执行当前请求对应的 Contrller 函数， 如果调用出现错误
--           					    则直接输出错误信息的json串；
-- 日    期： 2015年8月15日
-- 作    者： 申健
-- 参    数： 无
-- 返 回 值： 无
-- -----------------------------------------------------------------------------------
function _BaseController: run()
    local lastUriStr = self: getMethodNameByUri();
	ngx.log(ngx.ERR, "\n[sj_log] -> [BaseController] -> 函数对象[", lastUriStr, "]是否存在：[", (self[lastUriStr] ~= nil), "]\n");
    --local status, result = pcall(self[lastUriStr], self);
	local funcObj = self[lastUriStr];
	funcObj(self);
    
    -- if not status then
        -- error("调用函数[" .. ngx.var.uri .. "]出错，错误信息：[\n" .. result .. "\n]");
		-- ngx.log(ngx.ERR, "\n调用函数[", lastUriStr, "]出错，错误信息：[", result, "]\n");
        -- self: printJson(encodeJson({ success = false, info = "请求出现错误" }));
        -- ngx.exit(ngx.HTTP_OK);
    -- end
end

-- -----------------------------------------------------------------------------------
-- 函数描述： Controller公有函数 -> 向客户端输出字符串，如果是字符串，则直接输出；
--                                  如果是Table对象，会先用cjson转换成字符串，再进行输出；
-- 日    期： 2015年8月15日
-- 作    者： 申健
-- 参    数： jsonObj     要输出的对象，支持String、table类型的变量
-- 返 回 值： 无
-- -----------------------------------------------------------------------------------
function _BaseController: printJson(jsonObj)
    if jsonObj == nil then
        error("printJson函数中的参数jsonObj不能为空");
    end
    local objType = type(jsonObj);
	if objType == "string" or objType == "table" then
		if type(jsonObj) == "string" then
			ngx.print(jsonObj);
		end
		
		if type(jsonObj) == "table" then
			ngx.print(encodeJson(jsonObj));
		end
	else
		error("printJson函数的参数不正确，要输出的对象只支持String、table两种变量类型！");
	end
end
	

-- -----------------------------------------------------------------------------------
-- 函数描述： Controller公有函数 -> 根据参数名获取对应的参数， 并转换成number类型的变量
-- 日    期： 2015年8月15日
-- 作    者： 申健
-- 参    数： paramName     参数的名称
-- 参    数： validateNull  是否进行非空校验，true进行非空校验，nil和false表示不进行非空校验，默认为不进行非空校验
-- 返 回 值： 参数对应的值（number类型）
-- -----------------------------------------------------------------------------------
function _BaseController: getParamByName(paramName, validateNull)
	local paramValue = getParamByName(paramName);
	if validateNull == nil then
		validateNull = false;
	end
	if validateNull then 
		if paramValue == nil or paramValue == "" then
			self: printJson(encodeJson({ success = false, info = "参数" .. paramName .. "不能为空" }));
			ngx.log(ngx.ERR, "[sj_log] -> [BaseController] -> 参数 [", paramName, "] 的值为空！！！");
			ngx.exit(ngx.HTTP_OK);
			return nil;
		end
	end
	return paramValue;
end

-- -----------------------------------------------------------------------------------
-- 函数描述： Controller公有函数 -> 根据参数名获取对应的参数， 并转换成number类型的变量
-- 日    期： 2015年8月15日
-- 作    者： 申健
-- 参    数： paramName     参数的名称
-- 参    数： validateNull  是否进行非空校验，true进行非空校验，nil和false表示不进行非空校验，默认为不进行非空校验
-- 返 回 值： 参数对应的值（number类型）
-- -----------------------------------------------------------------------------------
function _BaseController: getParamToNumber(paramName, validateNull)
	local paramValue = self: getParamByName(paramName, validateNull);
	if paramValue ~= nil or paramValue ~= "" then
		return tonumber(paramValue);
	end
	return nil;
end

-- -----------------------------------------------------------------------------------
-- 函数描述： Controller公有函数 -> 根据参数名获取对应的参数， 并转换成table类型的变量
-- 日    期： 2015年8月15日
-- 作    者： 申健
-- 参    数： cookieName     Cookie的名称
-- 参    数： validateNull   是否进行非空校验，true进行非空校验，
--							 nil和false表示不进行非空校验，默认为不进行非空校验
-- 返 回 值： 参数对应的值（table类型）
-- -----------------------------------------------------------------------------------
function _BaseController: getParamToTable(paramName, validateNull)
	local paramValue = self: getParamByName(paramName, validateNull);
	if paramValue ~= nil and paramValue ~= "" then
        return g_cjson.decode(paramValue);
    end
    return nil;
end


-- -----------------------------------------------------------------------------------
-- 函数描述： Controller公有函数 -> 根据名称获取cookie中的值
-- 日    期： 2015年8月15日
-- 作    者： 申健
-- 参    数： cookieName     Cookie的名称
-- 参    数： validateNull   是否进行非空校验，true进行非空校验，
--							 nil和false表示不进行非空校验，默认为不进行非空校验
-- 返 回 值： cookie中对应名称的值
-- -----------------------------------------------------------------------------------
function _BaseController: getCookieByName(cookieName, validateNull)
	if validateNull == nil then
		validateNull = false;
	end
	local cookieValue = ngx.var["cookie_" .. cookieName];
    ngx.log(ngx.ERR, "[sj_log] -> [BaseController] -> cookieValue: [", cookieValue, "]");
	if validateNull then
		if cookieValue == nil or cookieValue == "" then
			self: printJson(encodeJson({ success = false, info = "cookie中名称： [" .. cookieName .. "] 的值不能为空" }));
			ngx.log(ngx.ERR, "[sj_log] -> [BaseController] -> cookie中名称： [", cookieName, "] 的值为空！！！");
			ngx.exit(ngx.HTTP_OK);
			return nil;
		end
	end
   
    return cookieValue;
end

-- -----------------------------------------------------------------------------------
-- 函数描述： Controller公有函数 -> 根据名称获取cookie中的值，并转换成number类型的变量
-- 日    期： 2015年8月15日
-- 作    者： 申健
-- 参    数： cookieName     Cookie的名称
-- 参    数： validateNull  是否进行非空校验，true进行非空校验，
--							nil和false表示不进行非空校验，默认为不进行非空校验
-- 返 回 值： cookie中对应名称的值
-- -----------------------------------------------------------------------------------
function _BaseController: getCookieToNumber(cookieName, validateNull)
	local cookieValue = self: getCookieByName(cookieName, validateNull);
	if cookieValue ~= nil and cookieValue ~= "" then
		return tonumber(cookieValue);
	end
	return nil;
end

-- -----------------------------------------------------------------------------------
-- 函数描述： Controller公有函数 -> 根据名称获取cookie中的值，并转换成table类型的变量
-- 日    期： 2015年8月15日
-- 作    者： 申健
-- 参    数： cookieName     Cookie的名称
-- 参    数： validateNull  是否进行非空校验，true进行非空校验，
--							nil和false表示不进行非空校验，默认为不进行非空校验
-- 返 回 值： cookie中对应名称的值
-- -----------------------------------------------------------------------------------
function _BaseController: getCookieToTable(cookieName, validateNull)
    local cookieValue = self: getCookieByName(cookieName, validateNull);
    if cookieValue ~= nil and cookieValue ~= "" then
        return g_cjson.decode(cookieValue);
    end
    return nil;
end

return _BaseController;

