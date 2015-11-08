--
-- Created by IntelliJ IDEA.
-- User: zh
-- Date: 2015/9/8
-- Time: 8:30
-- To change this template use File | Settings | File Templates.
-- 获取评论功能，从远程调用获取数据，简单封装。

local web = require("social.router.web")
local request = require("social.common.request")
local context = ngx.var.path_uri
local log = require("social.common.log")
local http = require "resty.http"
local function getComment()
    local url = request:getStrParam("url", true, true)
    log.debug(url);
    local hc = http:new()
    local ok, code, headers, status, body  = hc:request {
        url = url,
        method = "GET",
    }
    ngx.say(body);
end

-- 配置url.
-- 按功能分
local urls = {
    context .. '/getComment', getComment,
}
local app = web.application(urls, nil)
app:start()
