--
-- Created by IntelliJ IDEA.
-- User: zh
-- Date: 2015/8/19
-- Time: 15:56
-- To change this template use File | Settings | File Templates.
--
ngx.header.content_type = "text/plain";
local service = require("space.gzip.service.InteractiveToolsService")
local request = require("social.common.request");
local log = require("social.common.log")
local function generateInteractiveToolsJson()
    log.debug("generateBakToolsJson.....................")
    local person_id = request:getStrParam("person_id", true, true)
    local identity_id = request:getStrParam("identity_id",true,true)
    local login = request:getStrParam("login",true,true)
    local org_id = request:getStrParam("org_id",false,true)
    service.generateBakToolsJson(person_id,identity_id,login,org_id)
end
log.debug(ngx.var.uri)
generateInteractiveToolsJson();


