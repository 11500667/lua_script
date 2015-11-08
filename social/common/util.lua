local Util = {}
local table = require("social.common.table")
--- 将数据转化为可打印的字符串
--
-- @param table data 数据
-- @param string indentStr 缩进字符
-- @param number indentLevel 缩进级别
-- @return string 可打印的字符串
function Util:toString(data, indentStr, indentLevel)
    local dataType = type(data)

    if dataType == "string" then
        return string.format('%q', data)
    elseif dataType == "number" or dataType == "boolean" then
        return tostring(data)
    elseif dataType == "table" then
        return table:toString(data, indentStr or "\t", indentLevel or 1)
    else
        return "<" .. tostring(data) .. ">"
    end
end

--- 去除字符串收尾空格
--
-- @param string str
-- @return string
function Util:trim(str)
    return (string.gsub(str, "^%s*(.-)%s*$", "%1"))
end

--- 转化任意类型的值为数字
--
-- @param mixed value 任意类型的值
-- @param boolean abs 是否取绝对值
-- @return number 转化后的数字
function Util:numval(value, abs)
    local num = 0

    if value then
        num = tonumber(value) or 0
    end

    if num ~= 0 and abs then
        num = math.abs(num)
    end

    return num
end

--- 打印数据到日志文件中
--
-- @param table data 数据
-- @param string prefix 描述前缀
-- @param string logFile 日志文件路径
function Util:logData(data, prefix, logFile)
    local info = debug.getinfo(2,"Sl")
    local lineinfo = info.currentline
    local name = string.match(info.short_src, ".+/([^/]*%.%w+)$");
    local src_name =  (name==nil and "") or name
    local msg = src_name..":"..lineinfo.." : "..self:toString(data)
    local msg_str = string.format("[%s] %s\n", os.date(),  msg)
    self:writeFile(logFile or "/tmp/lua.log", (prefix or "") .. msg_str , true)
end
--- 将字符串内容写入文件
--
-- @param string file 文件路径
-- @param string content 内容
-- @param string append 追加模式(否则为覆盖模式)
function Util:writeFile(file, content, append)
    local fd = io.open(file, append and "a+" or "w+")
    local result, err = fd:write(content)
    fd:close()
    if not result then
        error(err)
    end
end

---字符串分割函数
--传入字符串和分隔符，返回分割后的table
--@param #string str 目标字符串.
--@param #string delimiter 分隔符.
--@return table 分隔后的table
function Util:split(str, delimiter)
    if str==nil or str=='' or delimiter==nil then
        return nil
    end

    local result = {}
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

---通过ssdb的multi_hget查询回来的结果返回一个类似于hashmap的table
---过滤掉不存在的key,可以解决对应不上和下标乱序问题
--@param #table ssdbResult
--@param #table keys
--    local keys = {"id","total_today","total_yestoday","total","name","logo_url","icon_url","domain"}
--    local ssdbResult = {"id","1","name","zhanghai","logo_url","dfasdf.jpg"}
function Util:multi_hget(ssdbResult,keys)
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



function Util:logkeys(key,method,logFile)
    local keystr = "key:%s,method:%s"
    keystr = string.format(keystr,key,method)
    self:writeFile(logFile or "/tmp/keys.log",keystr.."\n", true)
end
---记录读过的key
function Util:log_r_keys(key,method,logFile)
    local keystr = "key:%s,method:%s"
    keystr = string.format(keystr,key,method)
    self:writeFile(logFile or "/tmp/r_keys.log",keystr.."\n", true)
end

return Util
