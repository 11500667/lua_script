local util = require("social.common.util")
local Request = {}

--- 分析参数
--
-- @param table args 源参数表(Hash模式)
-- @param table data 目标参数表(Hash模式)
local function parseArgs(args, data)
    for key, val in pairs(args) do
        data.params[key] = val
    end
end

--- 分析请求参数(根据GET、POST)
--
-- @return table 参数表(Hash模式)
local function parseRequestData()
    local data = {
        headers = ngx.req.get_headers(),
        params = {},
        cookies = {},
        time = ngx.req.start_time(),
        ip = ngx.var.remote_addr
    }
    local request_method = ngx.var.request_method
    if request_method == "GET" then
        parseArgs(ngx.req.get_uri_args(), data)
    end

    if request_method == "POST" then
        ngx.req.read_body()
        local body = ngx.req.get_body_data()
        if body then
            parseArgs(ngx.decode_args(body), data)
        end
    end
    ngx.ctx[Request] = data
    return ngx.ctx[Request]
end

--- 获取请求数据
--
-- @return table 参数表
local function getRequestData()
    return ngx.ctx[Request] or parseRequestData()
end




--- 获取请求参数中的字符串参数
--
-- @param string name     键名
-- @param boolean nonempty 是否不允许为空
-- @param boolean trim     是否去除首尾空格
-- @return string 参数值
function Request:getStrParam(name, nonempty, trim)
    local param = getRequestData().params[name]
    local value = param or ""

    if trim and value ~= "" then
        value = util:trim(value)
    end

    if nonempty and value == "" then
        local err = { name = name, data = "不能为空" }
        error(err, 2);
    end
    return value
end

--- 获取请求参数中的数字参数
--
-- @param string name    键名
-- @param boolean abs     是否取绝对值
-- @param boolean nonzero 是否不允许为零
-- @return number 参数值
function Request:getNumParam(name, abs, nonzero)
    local param = getRequestData().params[name]
    local value = util:numval(param, abs)
    if nonzero and value == 0 then
        local err = { name = name, data = "不允许为0" }
        error(err, 2);
    end
    return value
end

return Request
