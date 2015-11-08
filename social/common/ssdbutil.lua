local ssdblib = require "resty.ssdb"
local SsdbUtil = {}

local function initSsdb()
    local ssdb = ssdblib:new()
    local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
    if not ok then
        return false
    end
    ngx.ctx[SsdbUtil] = ssdb
    return ngx.ctx[SsdbUtil] ;
end

function SsdbUtil:getDb()
   return ngx.ctx[SsdbUtil] or initSsdb()
end
function SsdbUtil:keepalive()
    if ngx.ctx[SsdbUtil] then
        ngx.ctx[SsdbUtil]:set_keepalive(0, v_pool_size)
        ngx.ctx[SsdbUtil] = nil
    end
end

return SsdbUtil;
