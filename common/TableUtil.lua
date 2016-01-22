-- -----------------------------------------------------------------------------------
-- 文件描述： table操作的工具类
-- 日    期： 2015年10月19日
-- 作    者： 申健
-- -----------------------------------------------------------------------------------

-- （调试中，请先不要调用）

-- -----------------------------------------------------------------------------------
-- 函数描述： 公有函数 -> 克隆一个Table对象
-- 日    期： 2015年10月19日
-- 作    者： 申健
-- 参    数： srcTable   被复制的table变量
-- 返 回 值： 克隆后的table对象，如果参数不是table类型的变量，则直接返回参数变量
-- -----------------------------------------------------------------------------------
function table.clone(srcTable)
    local lookup_table = {};
    local function _copy(object)
        if type(object) ~= "table" then
            return object;
        elseif lookup_table[object] then
            return lookup_table[object];
        end
        local new_table = {};
        lookup_table[object] = new_table;
        for key, value in pairs(object) do
            new_table[_copy(key)] = _copy(value);
        end
        return setmetatable(new_table, getmetatable(object));
    end
    return _copy(srcTable);
end

-- -----------------------------------------------------------------------------------
-- 函数描述： 公有函数 -> 判断一个table是否为空 是 nil 或者 长度为0
-- 日    期： 2015年10月19日
-- 作    者： 申健
-- 参    数： tableObj  被判断的table变量
-- 返 回 值： 非table 返回 true
-- -----------------------------------------------------------------------------------
function table.isEmpty(tableObj)
    local isEmpty = false;
    if type(tableObj) ~= "table" then
        isEmpty = true;
    else
        local length = 0;
        for k,v in pairs(tableObj) do
            length = length + 1;
            break;
        end
        if length == 0 then
            isEmpty = true;
        end
    end
    return isEmpty;
end

-- -----------------------------------------------------------------------------------
-- 函数描述： 公有函数 -> 判断一个table是否不为空 是 nil 或者 长度为0
-- 日    期： 2015年10月31日
-- 作    者： 申健
-- 参    数： tableObj  被判断的table变量
-- 返 回 值： table不为空 返回 true， 否则返回false
-- -----------------------------------------------------------------------------------
function table.isNotEmpty(tableObj)
    if table.isEmpty(tableObj) then
        return false;
    end
    return true;
end

-- -----------------------------------------------------------------------------------
-- 函数描述： 公有函数 -> 得到table中所有元素的个数
-- 日    期： 2015年10月19日
-- 作    者： 申健
-- 参    数： tableObj  被判断的table变量
-- 返 回 值： 非table 返回 true
-- -----------------------------------------------------------------------------------
function table.size(tableObj)
    local tNum = 0;
    for k,v in pairs(tableObj) do
        tNum = tNum + 1
    end
    return tNum;
end

-- -----------------------------------------------------------------------------------
-- 函数描述： 公有函数 -> 颠倒一个数组类型的table
-- 日    期： 2015年10月19日
-- 作    者： 申健
-- 参    数： tableObj  被判断的table变量
-- 返 回 值： 非table 返回 true
-- -----------------------------------------------------------------------------------
function table.reverse(tArray)
    if tArray == nil or #tArray == 0 then
        return nil;
    end
    local tArrayReversed = {};
    local nArrCount = #tArray;
    for i=1, nArrCount do
        tArrayReversed[i] = tArray[nArrCount-i+1]
    end
    return tArrayReversed;
end

-- -----------------------------------------------------------------------------------
-- 函数描述： 公有函数 -> 获得所有的key
-- 日    期： 2015年10月19日
-- 作    者： 申健
-- 参    数： tableObj  被判断的table变量
-- 返 回 值： 非table 返回 true
-- -----------------------------------------------------------------------------------
function table.allKeys(t_table)
    local tmplTable = {};
    if not table.isEmpty(t_table) then
        for k,v in pairs(t_table) do
            table.insert(tmplTable, k);
        end
    end
    return tmplTable;
end

-- -----------------------------------------------------------------------------------
-- 函数描述： 公有函数 -> 是否包含指定的key
-- 日    期： 2015年10月23日
-- 作    者： 申健
-- 参    数： tableObj  被判断的table变量
-- 参    数： key       被判断的table变量中的KEY值
-- 返 回 值： 非table 返回 true
-- -----------------------------------------------------------------------------------
function table.containKey(tableObj, key)
    local hasKey = false;
    if not table.isEmpty(tableObj) then
        for hashKey, hashVal in pairs(tableObj) do
            if hashKey == key then
                return true;
            end 
        end
    end
    return hasKey;
end

-- -----------------------------------------------------------------------------------
-- 函数描述： 公有函数 -> 判断table中是否包含指定的值
-- 日    期： 2015年10月26日
-- 作    者： 申健
-- 参    数： tableObj  被判断的table变量
-- 参    数： val       被判断的table变量中的值
-- 返 回 值： 如果table中存在该值，返回 true，否则返回false
-- -----------------------------------------------------------------------------------
function table.containValue(tableObj, val)
    local hasVal = false;
    if not table.isEmpty(tableObj) then
        for hashKey, hashVal in pairs(tableObj) do
            if hashVal == val then
                return true;
            end 
        end
    end
    return hasVal;
end
