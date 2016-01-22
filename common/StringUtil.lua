-- -----------------------------------------------------------------------------------
-- 文件描述： 字符串的工具类，此类已经在init.lua中进行了应用，在使用的地方直接调用
--            此类的函数即可，不需要再进行引用（require）
-- 日    期： 2015年10月17日
-- 作    者： 申健
-- -----------------------------------------------------------------------------------

-- （调试中，请先不要调用）

-- -----------------------------------------------------------------------------------
-- 函数描述： 公有函数 -> 字符串分割函数, 传入字符串和分隔符，返回分割后的table
-- 日    期： 2015年8月14日
-- 作    者： 申健
-- 参    数： str        原始字符串
-- 参    数： delimiter  分隔符
-- 返 回 值： 分割后的table
-- -----------------------------------------------------------------------------------
function string.split(str, delimiter)
    if string.isBlank(str) or string.isBlank(delimiter) then
        return nil;
    end
    if type(str) ~= "string" or type(delimiter) ~= "string" then
        error("string.split(str, delimiter)中要求的参数类型为(string,string), 当前为(" .. type(str) .."," .. type(delimiter) .. ");");
    end
    
    local result = {}
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

-- -----------------------------------------------------------------------------------
-- 函数描述： 公有函数 -> 判断字符串是否为空（包括nil、ngx.null)
-- 日    期： 2015年10月18日
-- 作    者： 申健
-- 参    数： str     原始字符串
-- 返 回 值： boolean true 为空， false 不为空
-- -----------------------------------------------------------------------------------
function string.isNil(str)
    return (str == nil or str == ngx.null);
end

-- -----------------------------------------------------------------------------------
-- 函数描述： 公有函数 -> 判断字符串是否为空白 （包括nil、ngx.null、空格）
-- 日    期： 2015年10月18日
-- 作    者： 申健
-- 参    数： str     原始字符串
-- 返 回 值： true是空字符串，false不是空字符串
-- -----------------------------------------------------------------------------------
function string.isBlank(str)
    if string.isNil(str) then
        return true;
    end
    if type(str) ~= "string" then
        return str;
    end
    return string.len(string.trim(str)) == 0;
end

-- -----------------------------------------------------------------------------------
-- 函数描述： 公有函数 -> 判断字符串是否不为空白 （包括nil、ngx.null、空格）
-- 日    期： 2015年10月18日
-- 作    者： 申健
-- 参    数： str     原始字符串
-- 返 回 值： true不是空字符串，false是空字符串
-- -----------------------------------------------------------------------------------
function string.isNotBlank(str)
    if string.isNil(str) then
        return false;
    end
    if type(str) ~= "string" then
        return str;
    end
    return string.len(string.trim(str)) ~= 0;
end

-- -----------------------------------------------------------------------------------
-- 函数描述： 公有函数 -> 去掉字符串左边的空格
-- 日    期： 2015年10月18日
-- 作    者： 申健
-- 参    数： str     原始字符串
-- 返 回 值： 处理后的字符串
-- -----------------------------------------------------------------------------------
function string.ltrim(str)
    if string.isNil(str) then
        return nil;
    end
    if type(str) ~= "string" then
        error("string.ltrim(str)中str只能为string类型，当前为[" .. type(str) .. "]类型");
    end
    return string.gsub(str, "^[ \t\n\r]+", "")
end

-- -----------------------------------------------------------------------------------
-- 函数描述： 公有函数 -> 去掉字符串右边的空格
-- 日    期： 2015年10月18日
-- 作    者： 申健
-- 参    数： str     原始字符串
-- 返 回 值： 处理后的字符串
-- -----------------------------------------------------------------------------------
function string.rtrim(str)
    if string.isNil(str) then
        return nil;
    end
    if type(str) ~= "string" then
        error("string.rtrim(str)中str只能为string类型，当前为[" .. type(str) .. "]类型");
    end
    return string.gsub(str, "[ \t\n\r]+$", "")
end

-- -----------------------------------------------------------------------------------
-- 函数描述： 公有函数 -> 去掉字符串两边的空格
-- 日    期： 2015年10月18日
-- 作    者： 申健
-- 参    数： str     原始字符串
-- 返 回 值： 处理后的字符串
-- -----------------------------------------------------------------------------------
function string.trim(str)
    if string.isNil(str) then
        return nil;
    end
    if type(str) ~= "string" then
        error("string.trim(str)中str只能为string类型，当前为[" .. type(str) .. "]类型");
    end
    str = string.gsub(str, "^[ \t\n\r]+", "")
    return string.gsub(str, "[ \t\n\r]+$", "")
end

-- -----------------------------------------------------------------------------------
-- 函数描述： 公有函数 -> 如果为目标字符串为空白字符串，则返回默认的字符串
-- 日    期： 2015年10月18日
-- 作    者： 申健
-- 参    数： str            原始字符串
-- 参    数： defaultVal     默认字符串
-- 返 回 值： 结果字符串
-- -----------------------------------------------------------------------------------
function string.defaultIfBlank(str, defaultVal)
    if string.isNil(defaultVal)  then
        error("string.split(str, defaultVal)中的参数 defaultVal 不能为nil;");
    end
    if string.isBlank(str) then
        return defaultVal;
    end
    return str;
end