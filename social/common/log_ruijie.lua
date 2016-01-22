--
--    刘全锋  2016-01-05
--    描述：  RUIJIE log.
--
local Log = { _VERSION = "0.1" }
local tableutil = require("social.common.table");


function file_exists(path)
    local file = io.open(path, "rb")
    if file then file:close() end
    return file ~= nil
end

local path = "usr/local/openresty/nginx/logs/ruijie/"..os.date("%Y-%m");
local logFile = "usr/local/openresty/nginx/logs/ruijie/"..os.date("%Y-%m").."/"..os.date("%Y-%m-%d")..".log";

local folderExist = file_exists(path);

if not folderExist then
    local obj =  os.execute("mkdir -p "..path);
end

local fileExist = file_exists(logFile);

if not fileExist then
    local file = io.open(logFile,"w");
    file:close();
end



Log.outfile = logFile;
Log.level = "trace"
local modes = {
    { name = "trace" },
    { name = "debug" },
    { name = "info" },
    { name = "warn" },
    { name = "error" },
    { name = "fatal" },
}

local levels = {}
for i, v in ipairs(modes) do
    levels[v.name] = i
end

local _tostring = tostring

local tostring = function(...)
    local t = {}
    for i = 1, select('#', ...) do
        local x = select(i, ...)
        local dataType = type(x)
        if dataType == "string" then
            t[#t + 1] = string.format('%q', x)
        elseif dataType == "number" or dataType == "boolean" then
            t[#t + 1] = tostring(x)
        elseif dataType == "table" then
            t[#t + 1] = tableutil:toString(x, "\t", 1)
        else
            t[#t + 1] = "<" .. tostring(x) .. ">"
        end
    end
    return table.concat(t, " ")
end

for i, x in ipairs(modes) do
    local nameupper = x.name:upper()
    Log[x.name] = function(...)
        if i < levels[Log.level] then
            return
        end
        local msg = tostring(...)
        local info = debug.getinfo(2, "Sl")
        local name = string.match(info.short_src,".+/([^/]*%.%w+)$");
        local src_name = (name == nil and "") or name
        local lineinfo = src_name .. ":" .. info.currentline
        if Log.outfile then
            local fp = io.open(Log.outfile, "a+");
            local str = string.format("[%-6s%s] %s: %s\n",
                nameupper, os.date(), lineinfo, msg);
            fp:write(str);
            fp:close();
        end
    end
end
return Log
