-- -----------------------------------------------------------------------------------
-- 文件描述： icomet的工具类
-- 日    期： 2016年1月5日
-- 作    者： 申健
-- -----------------------------------------------------------------------------------
local _ICometUtil = {};

-- -----------------------------------------------------------------------------------
-- 函数描述： 发送信息到iComet的指定的Channel中
-- 日    期： 2016年1月5日
-- 参    数： channelName icomet中的管道名
-- 参    数： msgStr      消息内容
-- 返 回 值： 返回值信息
-- -----------------------------------------------------------------------------------
local function push(self, channelName, msgStr)
    -- local http = require "resty.http"
    -- local hc = http:new()
    -- local bodyStr = "cname=" .. channelName .. "&content=" .. msgStr;

    -- WAY-1: http请求方式，POST方式
    -- local ok, code, headers, status, body  = hc:request {                    
    --     url     = "http://127.0.0.1:8000/push",
    --     method  = "POST", -- POST or GET
    --     headers = {
    --         ["Content-Type"]   = "application/x-www-form-urlencoded"
    --     },
    --     body    = bodyStr
    -- }

    -- WAY-2: http请求方式，GET方式
    -- local ok, code, headers, status, body  = hc:request {                    
    --     url     = "http://127.0.0.1:8000/push?" .. bodyStr,
    --     method  = "GET" -- POST or GET
    -- }
    -- ngx.log(ngx.INFO, "[sj_log] -> [icometUtil] -> channelName:[", channelName, "], msgStr:[", msgStr, "]\nok : [", ok, "]\ncode: [", code, "]\nstatus: [", status, "]\nbody: [", body, "]");

    -- WAY-3: nginx capture的方式（需要在配置文件中进行代理）
    local respTable = ngx.location.capture("/icomet/push", {
        method = ngx.HTTP_GET,
        args = { cname = channelName, content = msgStr }
    });
    
    ngx.log(ngx.INFO, "[sj_log] -> [icometUtil] -> respTable:[", encodeJson(respTable), "]");

    local status = tonumber(respTable.status);
    -- 如果返回的状态不是200，表示向iComet插入数据没有成功；
    if status ~= 200 then 
        error("通过capture的方式向iComet的管道中插入数据失败，返回的响应数据为:[" .. encodeJson(respTable) .. "]");
    end
end
_ICometUtil.push = push;

return _ICometUtil;