--
-- Created by IntelliJ IDEA.
-- User: zh
-- Date: 2015/8/10
-- Time: 13:51
-- To change this template use File | Settings | File Templates.
--
local log = require("social.common.log")
local SsdbUtil = require("social.common.ssdbutil")
local TS = require "resty.TS"

local _M = {}
--修改空间模块ts值.
function _M.updateTs(person_id, identity_id)
    local db = SsdbUtil:getDb();

    local t  = TS.getTs()
    local b = db:set("space_last_personid_" .. person_id .. "_identityid_" .. identity_id .. "_ts", t)
    local b_nologin =db:set("space_last_personid_" .. person_id .. "_identityid_" .. identity_id .. "_nologin_ts",t)
    --db:set("space_last_personid_"..person_id.."_identityid_"..identity_id.."_ts", TS.getTs())
    if b and b_nologin then
        return true;
    end
    return false
end

return _M;

