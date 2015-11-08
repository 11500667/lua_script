--[[
新闻通知公告Service
@Author  feiliming
@Date    2015-7-21
]]

local cjson = require "cjson"
local ssdbUtil = require "social.common.ssdbutil"
local _M = {}

--申请注册号
function _M.applyRegisterId()
    local ssdb = ssdbUtil:getDb()

    --return
	local rr = {}
	rr.success = true

    local rt, err = ssdb:incr("social_notice_register_id")
	if not rt then
	    rr.success = false
	    return rr
	end
    local register_id = rt[1]
	rr.register_id = tonumber(register_id)
    
    ssdbUtil:keepalive()
    return rr;
end

return _M;