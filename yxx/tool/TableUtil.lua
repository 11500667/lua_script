local Table = {};
local function checkTable(t)
    if type(t) ~= "table" then
       error("t is not a table");
    end
end
--- 获取表的所有键
--
-- @param table t 源表
-- @return table 键名表
function Table:keys(t)
    checkTable(t)

    local keys = {}

    for k in pairs(t) do
        keys[#keys + 1] = k
    end

    return keys
end

--- 获取表的所有值
--
-- @param table t 源表
-- @return table 值表
function Table:values(t)
    checkTable(t)

    local values = {}

    for _, v in pairs(t) do
        values[#values + 1] = v
    end

    return values
end
--- 装置mysql语句代码
--
-- @param table t 源表
-- @return k_str 值  k1,k2,k3
--         v_str 值  'v4',1,'v3',true,'2015-06-17 16:31:10'
function Table:convert_sql(t)
    checkTable(t)
    local return_table = {};
    if next(t) ~= nil then
        local v_str = "";
        local k_str = "";
        local keys = {};
        for k in pairs(t) do
            keys[#keys + 1] = k;
        end
        for k,_ in pairs(keys) do
            k_str = k_str .. keys[k] .. ",";
            if type(t[keys[k]]) == "number" or type(t[keys[k]]) == "boolean" then
                v_str = v_str..tostring(t[keys[k]])..",";
            else
                v_str = v_str.."'"..t[keys[k]].."'"..",";
            end
        end
        if string.len(k_str) > 0 then
            return_table["k_str"] = string.sub(k_str,1,string.len(k_str)-1)
        else
            return_table["k_str"] = "";
        end
        if string.len(k_str) > 0 then
            return_table["v_str"] = string.sub(v_str,1,string.len(v_str)-1);
        else
            return_table["v_str"] = "";
        end
    end
    return return_table;
end

--- 装置mysql的update语句代码
-- @param table t 源表
-- @return k_v_str 值  k1=v1,k2=v2,k3=v3
function Table:convert_update_sql(t)
    checkTable(t)
    local sql = "";
    if next(t) ~= nil then
        local k_v_str = "";
        local keys = {};
        for k in pairs(t) do
            keys[#keys + 1] = k;
        end
        for k,_ in pairs(keys) do
            k_v_str = k_v_str..keys[k].."=";
            if type(t[keys[k]]) == "number" or type(t[keys[k]]) == "boolean" then
                k_v_str = k_v_str..tostring(t[keys[k]])..",";
            else
                k_v_str = k_v_str.."'"..t[keys[k]].."'"..",";
            end
        end
        if string.len(k_v_str) > 0 then
            sql = string.sub(k_v_str,1,string.len(k_v_str)-1)
        else
            sql = "";
        end
    end
    return sql;
end
---通过ssdb的multi_hget查询回来的结果返回一个类似于hashmap的table
---过滤掉不存在的key,可以解决对应不上和下标乱序问题
--@param #table ssdbResult
--@param #table keys
--    local keys = {"id","total_today","total_yestoday","total","name","logo_url","icon_url","domain"}
--    local ssdbResult = {"id","1","name","zhanghai","logo_url","dfasdf.jpg"}
function Table:multi_hget(ssdbResult,keys)
    local keyResult = {}
    local valueResult = {}
    local len = #ssdbResult;
    for i=1, len do
        if i%2~=0 then
            keyResult[#keyResult+1] = ssdbResult[i]
        else
            valueResult[#valueResult+1] = ssdbResult[i]
        end
    end
    local result = {}
    for i=1,#keys do
        for j =1 ,#keyResult do
            if keys[i] == keyResult[j] then
                result[keys[i]] = valueResult[j]
                break;
            else
                result[keys[i]] = ""
            end
        end
    end
    return result
end
--- 将表连接到Array模式源表尾部
--
-- @param table t 源表
-- @param table t1 待连接表
-- @return table 连接后的表
function Table:concat(t, t1)
    checkTable(t)
    checkTable(t1)

    local length = #t

    for i, v in ipairs(t1) do
        t[length + i] = v
    end

    return t
end

return Table;
