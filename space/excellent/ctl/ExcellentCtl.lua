--
-- Created by IntelliJ IDEA.
-- User: zh
-- Date: 2015/8/28
-- Time: 16:21
-- To change this template use File | Settings | File Templates.
--
local web = require("social.router.web")
local request = require("social.common.request")
local excellentService = require("space.excellent.service.ExcellentService")
--log.debug(context);
--log.debug(no_permission_context);
local cjson = require "cjson"
local context = ngx.var.path_uri --有权限的context.
local log = require("social.common.log")
local function getExcellent()
    local ids = request:getStrParam("ids", true, true)
    local limit = request:getStrParam("limit", false, true)
    local ids_table = cjson.decode(ids);
    local org_ids = {}
    local org_types = {};
    local identity_id;
    for j = 1, #ids_table do
        table.insert(org_ids, ids_table[j][1])
        table.insert(org_types, ids_table[j][2])
        identity_id = ids_table[1][3]
    end
    log.debug(org_ids)
    log.debug(org_types)
    log.debug(identity_id)
    local result = excellentService.getExcellence(org_ids, org_types, identity_id, limit);
    log.debug(result);
    if result then
        result.success = true;
    end
    cjson.encode_empty_table_as_object(false)
    ngx.say(cjson.encode(result));
end

-- 配置url.
-- 按功能分
local urls = {
    context .. '/getExcellent', getExcellent,
}
local app = web.application(urls, nil)
app:start()

