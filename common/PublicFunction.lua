
-- -----------------------------------------------------------------------------------
-- 函数描述： 公有函数 -> 获取参数
-- 日    期： 2015年8月5日
-- 作    者： 申健
-- 返 回 值： args 存储参数的table
-- -----------------------------------------------------------------------------------
function getParams()
    local args = {};
    -- 获取url中的参数
    local uriArgs = ngx.req.get_uri_args();
    --ngx.log(ngx.ERR, "\n[sj_log] -> [URL中的参数]");
    for key, value in pairs(uriArgs) do
        args[key] = value;
        --ngx.log(ngx.ERR, "\n[sj_log] -> name: [", key, "], value: [", value, "]");
    end

    if ngx.var.request_method == "POST" then
        -- 获取body中的参数，如果url中已经存在该参数，则会被post中的覆盖
        ngx.req.read_body();
        local postArgs = ngx.req.get_post_args();
        --ngx.log(ngx.ERR, "\n[sj_log] -> [BODY中的参数]");
        for key, value in pairs(postArgs) do
            args[key] = value;
            --ngx.log(ngx.ERR, "\n[sj_log] -> name: [", key, "], value: [", value, "]");
        end
    end

    return args;
end

-- -----------------------------------------------------------------------------------
-- 函数描述： 公有函数 -> 根据参数名获取对应的参数
-- 日    期： 2015年8月5日
-- 作    者： 申健
-- 返 回 值： 参数对应的值(string 类型)
-- -----------------------------------------------------------------------------------
function getParamByName(paramName)
    local args = ngx.ctx["http_params"];
    if args == nil then
        args = getParams();
        ngx.ctx["http_params"] = args;
    end
    return args[paramName];
end

-- -----------------------------------------------------------------------------------
-- 函数描述： 公有函数 -> 根据参数名获取对应的参数， 并转换成number类型的变量
-- 日    期： 2015年8月5日
-- 作    者： 申健
-- 返 回 值： 参数对应的值（number类型）
-- -----------------------------------------------------------------------------------
function getParamToNumber(paramName)
    local paramValue = getParamByName(paramName);
    if paramValue ~= nil and paramValue ~= "" then
        return tonumber(paramValue);
    end
    return nil;
end

-- -----------------------------------------------------------------------------------
-- 函数描述： 公有函数 -> 根据参数名获取对应的参数， 并转换成table类型的变量
-- 日    期： 2015年8月5日
-- 作    者： 申健
-- 返 回 值： 参数对应的值（table类型）
-- -----------------------------------------------------------------------------------
function getParamToTable(paramName)
    local paramValue = getParamByName(paramName);
    if paramValue ~= nil and paramValue ~= "" then
        return g_cjson.decode(paramValue);
    end
    return nil;
end

-- -----------------------------------------------------------------------------------
-- 函数描述： 公有函数 -> 根据名称获取cookie中的值
-- 日    期： 2015年8月6日
-- 作    者： 申健
-- 返 回 值： cookie中对应名称的值
-- -----------------------------------------------------------------------------------
function getCookieByName(cookieName)
    local cookieValue = ngx.var["cookie_" .. cookieName];
    if cookieValue ~= nil and cookieValue ~= "" then
        return cookieValue;
    end
    return nil;
end

-- -----------------------------------------------------------------------------------
-- 函数描述： 公有函数 -> 根据名称获取cookie中的值，并转换成number类型的变量
-- 日    期： 2015年8月6日
-- 作    者： 申健
-- 返 回 值： cookie中对应名称的值
-- -----------------------------------------------------------------------------------
function getCookieToNumber(cookieName)
    local cookieValue = getCookieByName(cookieName);
    if cookieValue ~= nil and cookieValue ~= "" then
        return tonumber(cookieValue);
    end
    return nil;
end

-- -----------------------------------------------------------------------------------
-- 函数描述： 公有函数 -> 根据名称获取cookie中的值，并转换成table类型的变量
-- 日    期： 2015年8月6日
-- 作    者： 申健
-- 返 回 值： cookie中对应名称的值
-- -----------------------------------------------------------------------------------
function getCookieToTable(cookieName)
    local cookieValue = getCookieByName(cookieName);
    if cookieValue ~= nil and cookieValue ~= "" then
        return g_cjson.decode(cookieValue);
    end
    return nil;
end

-- -----------------------------------------------------------------------------------
-- 函数描述： 公有函数 -> 将table对象转换成json字符串
-- 日    期： 2015年8月5日
-- 作    者： 申健
-- 参    数： tableObj 需要转换的table对象
-- 返 回 值： 转换后的json字符串
-- -----------------------------------------------------------------------------------
function encodeJson(tableObj)
    return g_cjson.encode(tableObj);
end

-- -----------------------------------------------------------------------------------
-- 函数描述： 公有函数 -> 将json字符串转换成table对象
-- 日    期： 2015年8月5日
-- 作    者： 申健
-- 参    数： stringObj 需要转换的json字符串
-- 返 回 值： 转换后的table对象
-- -----------------------------------------------------------------------------------
function decodeJson(stringObj)
    return g_cjson.decode(stringObj);
end

-- -----------------------------------------------------------------------------------
-- 函数描述： 公有函数 -> 生成一个uuid
-- 日    期： 2015年8月13日
-- 作    者： 申健
-- 参    数： 无
-- 返 回 值： UUID值
-- -----------------------------------------------------------------------------------
function getUUID()
    local uuidModel =  require "resty.uuid";
    local uuidStr   = uuidModel.new();
    return uuidStr;
end

-- -----------------------------------------------------------------------------------
-- 函数描述： 公有函数 -> 生成TS值
-- 日    期： 2015年8月20日
-- 作    者： 申健
-- 参    数： 无
-- 返 回 值： number类型的时间戳：例：2015082016443312345
-- -----------------------------------------------------------------------------------
function getTS()
    local tsModel  = require "resty.TS";
    local tsValue  = tsModel.getTs();
    return tsValue;
end

-- -----------------------------------------------------------------------------------
-- 函数描述： 公有函数 -> 字符串分割函数, 传入字符串和分隔符，返回分割后的table
-- 日    期： 2015年8月14日
-- 作    者： 申健
-- 参    数： str        原始字符串
-- 参    数： delimiter  分隔符
-- 返 回 值： 分割后的table
-- -----------------------------------------------------------------------------------
function string.split(str, delimiter)
    if str==nil or str=='' or delimiter==nil then
        return nil
    end
    
    local result = {}
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end