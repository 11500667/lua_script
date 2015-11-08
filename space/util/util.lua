local Util = {}
local table = require("space.util.table")
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

--- 打印数据到日志文件中
--
-- @param table data 数据
-- @param string prefix 描述前缀
-- @param string logFile 日志文件路径
function Util:logData(data, prefix, logFile)
    self:writeFile(logFile or "/tmp/lua.log", (prefix or "") .. self:toString(data) .. "\n", true)
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
return Util
