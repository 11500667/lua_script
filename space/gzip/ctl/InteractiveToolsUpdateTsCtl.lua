--
-- Created by IntelliJ IDEA.
-- User: zh
-- Date: 2015/8/21
-- Time: 8:52
-- To change this template use File | Settings | File Templates.
--

ngx.header.content_type = "text/plain";
local request = require("social.common.request");
local web = require("social.router.web")
local service = require("space.gzip.service.InteractiveToolsUpdateTsService")
local cjson = require "cjson"
local context = ngx.var.path_uri
local function updateTs()
    local person_id = request:getStrParam("person_id", true, true)
    local identity_id = request:getStrParam("identity_id", true, true)
    local b = service.updateTs(person_id, identity_id)
    local result = { success = b }
    ngx.say(cjson.encode(result));
end

local urls = {
    context .. '/updatets', updateTs,
}
local app = web.application(urls, nil)
app:start()