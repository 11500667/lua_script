--
-- Created by IntelliJ IDEA.
-- User: 张海
-- Date: 2015/7/6
-- Time: 9:45
-- To change this template use File | Settings | File Templates.
--

ngx.header.content_type = "text/plain";
local web = require("social.router.web")
local cjson = require "cjson"
local request = require("social.common.request")
local no_permission_context = ngx.var.path_uri_no_permission --无权限的context.
local context = ngx.var.path_uri --有权限的context.
local log = require("social.common.log")
local service = require("space.attention.service.AttentionService")

-------------------------------------------------------------------------------------------------------
-- 保存关注信息.
local function save()
    local personid = request:getStrParam("personid", true, true) --关注人id
    local identityid = request:getStrParam("identityid", true, true) --关注人id
    local b_personid = request:getStrParam("b_personid", true, true) --被关注人id
    local b_identityid = request:getStrParam("b_identityid", true, true) --被关注人的身份.
    local r = service.save({ personid = personid, identityid = identityid, b_personid = b_personid, b_identityid = b_identityid })

    local service = require("space.gzip.service.InteractiveToolsUpdateTsService")
    service.updateTs(personid,identityid)
    service.updateTs(b_personid,b_identityid)
    local result = {}
    result.success = true;
    if not r then
        result.success = false;
        result.info = { name = "", data = "添加出错." }
        ngx.say(cjson.encode(result));
        return;
    end
    ngx.say(cjson.encode(result));
end

-------------------------------------------------------------------------------------------------------
-- 查询关注信息.
local function query()
    log.debug("查询关注信息.")
    local personid = request:getStrParam("personid", true, true) --关注人id
    local identityid = request:getStrParam("identityid", true, true) --关注人id
    local b_personid = request:getStrParam("b_personid", false, true) --被关注人id
    local b_identityid = request:getStrParam("b_identityid", false, true) --被关注人的身份.
    local page_size = request:getNumParam("page_size", false, true) --被关注人的身份.
    local page_num = request:getNumParam("page_num", false, true) --被关注人的身份.
    local result = { success = true, list = {} }
    local list, totalRow, totalPage = service.queryAttention({ personid = personid, identityid = identityid, b_personid = b_personid, b_identityid = b_identityid, page_size = tonumber(page_size), page_num = tonumber(page_num) })
    if not list then
        ngx.say(cjson.encode({ success = false }))
        return;
    end
    result.list = list
    result.total_row = totalRow
    result.total_page = totalPage
    result.page_size = page_size
    result.page_num = page_num
    ngx.say(cjson.encode(result));
end

-------------------------------------------------------------------------------------------------------
-- 查询被关注信息.
local function bquery()
    log.debug("查询被关注信息.")
    local personid = request:getStrParam("personid", true, true) --关注人id
    local identityid = request:getStrParam("identityid", true, true) --关注人id
    local b_personid = request:getStrParam("b_personid", false, true) --被关注人id
    local b_identityid = request:getStrParam("b_identityid", false, true) --被关注人的身份.
    local page_size = request:getNumParam("page_size", false, true) --被关注人的身份.
    local page_num = request:getNumParam("page_num", false, true) --被关注人的身份.
    local result = { success = true, list = {} }
    local list, totalRow, totalPage = service.queryBAttention({ personid = personid, identityid = identityid, b_personid = b_personid, b_identityid = b_identityid, page_size = tonumber(page_size), page_num = tonumber(page_num) })
    if not list then
        ngx.say(cjson.encode({ success = false }))
        return;
    end
    result.list = list
    result.total_row = totalRow
    result.total_page = totalPage
    result.page_size = page_size
    result.page_num = page_num
    ngx.say(cjson.encode(result));
end

local function get()
    local personid = request:getStrParam("personid", false, true) --关注人id
    local identityid = request:getStrParam("identityid", false, true) --关注人id
    local type = request:getStrParam("type", true, true) --访问的类型（博文，空间）
    local b_personid = request:getStrParam("b_personid", true, true) --被关注人id
    local b_identityid = request:getStrParam("b_identityid", true, true) --被关注人的身份.
    log.debug(type)
    local result = service.get({ personid = personid, identityid = identityid, b_personid = b_personid, b_identityid = b_identityid, type = type })
    if not result then
        result.success = false
        ngx.say(cjson.encode(result))
        return;
    end
    ngx.say(cjson.encode(result));
end

------------------------------------------------------------------------------------------------------
-- 设置访问量.
-- local function access()
-- local personid = request:getStrParam("personid", false, true) --关注人id
-- local type = request:getStrParam("type", true, true) --访问的类型（博文，空间）
-- local identityid = request:getStrParam("identityid", false, true) --关注人id
-- local b_personid = request:getStrParam("b_personid", true, true) --被关注人id
-- local b_identityid = request:getStrParam("b_identityid", true, true) --被关注人的身份.
-- local result = service.access(personid, identityid, b_personid, b_identityid, type)
-- if not result then
-- ngx.say(cjson.encode({ success = false }))
-- return;
-- end
-- ngx.say(cjson.encode({ success = true }))
-- end
-- 谁看过我
local function accesslist()
    local personid = request:getStrParam("personid", true, true) --关注人id
    local identityid = request:getStrParam("identityid", true, true) --关注人id
    local type = request:getStrParam("type", true, true) --访问的类型（博文，空间）
    local page_size = request:getNumParam("page_size", false, true)
    local page_num = request:getNumParam("page_num", false, true)
    local list, totalRow, totalPage = service.accesslist(personid, identityid, type, page_size, page_num)
    local result = { success = true, list = {} }
    if not list then
        ngx.say(cjson.encode({ success = false }))
        return;
    end
    result.list = list
    result.total_row = totalRow
    result.total_page = totalPage
    result.page_size = page_size
    result.page_num = page_num
    ngx.say(cjson.encode(result));
end

--我看过谁
local function baccesslist()
    local personid = request:getStrParam("personid", true, true) --关注人id
    local identityid = request:getStrParam("identityid", true, true) --关注人id
    local type = request:getStrParam("type", true, true) --访问的类型（博文，空间）
    local page_size = request:getNumParam("page_size", false, true)
    local page_num = request:getNumParam("page_num", false, true)
    local list, totalRow, totalPage = service.accesslist_b(personid, identityid, type, page_size, page_num)
    local result = { success = true, list = {} }
    if not list then
        ngx.say(cjson.encode({ success = false }))
        return;
    end
    result.list = list
    result.total_row = totalRow
    result.total_page = totalPage
    result.page_size = page_size
    result.page_num = page_num
    ngx.say(cjson.encode(result));
end


------------------------------------------------------------------------------------------------------
-- 取消关注
local function delete()
    local personid = request:getStrParam("personid", true, true) --关注人id
    local identityid = request:getStrParam("identityid", true, true) --关注人id
    local b_personid = request:getStrParam("b_personid", true, true) --被关注人id
    local b_identityid = request:getStrParam("b_identityid", true, true) --被关注人的身份.

    local r = service.delete({ personid = personid, identityid = identityid, b_personid = b_personid, b_identityid = b_identityid })
    local service = require("space.gzip.service.InteractiveToolsUpdateTsService")
    service.updateTs(personid,identityid)
    service.updateTs(b_personid,b_identityid)
    if not r then
        ngx.say(cjson.encode({ success = false }))
        return;
    end
    ngx.say(cjson.encode({ success = true }))
end


-- 配置url.
-- 按功能分
local urls = {
    context .. '/save', save,
    no_permission_context .. '/query', query,
    no_permission_context .. '/bquery', bquery,
    no_permission_context .. '/get', get,
    -- no_permission_context .. '/access', access,
    no_permission_context .. '/list_access', accesslist,
    no_permission_context .. '/blist_access', baccesslist,
    context .. '/cancel', delete
}
local app = web.application(urls, nil)
app:start()