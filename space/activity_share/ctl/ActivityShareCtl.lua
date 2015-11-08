--
-- Created by IntelliJ IDEA.
-- User: zh
-- Date: 2015/7/13
-- Time: 13:58
-- To change this template use File | Settings | File Templates.
--

ngx.header.content_type = "text/plain";
local web = require("social.router.web")
local cjson = require "cjson"
local request = require("social.common.request")
local log = require("social.common.log")
local service = require("space.activity_share.service.ActivityShareService")
local context = ngx.var.path_uri --有权限的context.
local no_permission_context = ngx.var.path_uri_no_permission --无权限的context.
--Title
--Context
--Person_id
--Person_name
--Identity_id
--Message_type
--File_id
local function save()
    local title = request:getStrParam("title", true, true) --title
    local _context = request:getStrParam("context", false, true) --context
    local person_id = request:getStrParam("person_id", true, true) --person_id
    local person_name = request:getStrParam("person_name", true, true) --person_name
    local identity_id = request:getStrParam("identity_id", true, true) --identity_id
    local message_type = request:getStrParam("message_type", true, true) --message_type
    local org_ids = request:getStrParam("org_ids", false, true)
    local seq_id = request:getStrParam("seq_id", true, true)
    --local source = request:getStrParam("source", true, true) --message_type
    local list = request:getStrParam("list", true, true) --list
    log.debug(list);
    local list_t = cjson.decode(list)
    local param = {}
    param.title = title
    param.context = _context
    param.person_id = person_id
    param.person_name = person_name
    param.identity_id = identity_id
    param.message_type = message_type
    param.list = list_t
    param.org_ids = org_ids;
    param.seq_id = seq_id;
    -- param.source = source;
    --修改ts值.
    local interactiveToolsUpdateTsService = require("space.gzip.service.InteractiveToolsUpdateTsService")
    interactiveToolsUpdateTsService.updateTs(person_id,identity_id)

    local result = service.save(param)
    if result then
        ngx.say(cjson.encode({ success = true }))
    else
        ngx.say(cjson.encode({ success = false }))
    end
end

--person_id
--identity_id
--message_type
--page_num
--page_size

local function list()
    local person_id = request:getStrParam("person_id", false, true) --person_id
    local identity_id = request:getStrParam("identity_id", false, true) --identity_id
    local message_type = request:getStrParam("message_type", false, true) --person_id
    local org_id = request:getStrParam("org_id")
    message_type = ((message_type == nil or string.len(message_type) == 0) and "1") or message_type
    local page_num = request:getStrParam("page_num", true, true) --page_num
    local page_size = request:getStrParam("page_size", true, true) --page_size
    local param = { person_id = person_id, identity_id = identity_id, message_type = message_type, page_num = page_num, page_size = page_size, orgid = org_id }
    local result = service.list(param)
    if result then
        result.success = true;
    else
        result.success = false
    end
    ngx.say(cjson.encode(result))
end

local function update()
    local id = request:getStrParam("id", true, true);
    local title = request:getStrParam("title", true, true) --title
    local _context = request:getStrParam("context", false, true) --context
    local person_id = request:getStrParam("person_id", true, true) --person_id
    local person_name = request:getStrParam("person_name", true, true) --person_name
    local identity_id = request:getStrParam("identity_id", true, true) --identity_id
    local message_type = request:getStrParam("message_type", true, true) --message_type
    local seq_id = request:getStrParam("seq_id", true, true)
    local list = request:getStrParam("list", true, true) --list
    local list_t = cjson.decode(list)
    local param = {}
    param.id = id;
    param.title = title
    param.context = _context
    param.person_id = person_id
    param.person_name = person_name
    param.identity_id = identity_id
    param.message_type = message_type
    param.list = list_t
    param.seq_id = seq_id;

    --修改ts值.
    local interactiveToolsUpdateTsService = require("space.gzip.service.InteractiveToolsUpdateTsService")
    interactiveToolsUpdateTsService.updateTs(person_id,identity_id)

    local result = service.update(param)
    if result then
        ngx.say(cjson.encode({ success = true }))
    else
        ngx.say(cjson.encode({ success = false }))
    end
end

local function delete()
    local id = request:getStrParam("id", true, true);
    local org_id = request:getStrParam("org_id", false, true);
    log.debug(id);
    log.debug(org_id)
    local result = service.delete(org_id, id)
    if result then
        ngx.say(cjson.encode({ success = true }))
    else
        ngx.say(cjson.encode({ success = false }))
    end
end

local function deleteDetail()
    local id = request:getStrParam("id", true, true);
    local result = service.deleteDetail(id)
    if result then
        ngx.say(cjson.encode({ success = true }))
    else
        ngx.say(cjson.encode({ success = false }))
    end
end

local function view()
    local id = request:getStrParam("id", true, true);
    local isAdmin = request:getStrParam("is_admin", false, true);
    if string.len(isAdmin)==0 then
        isAdmin = false;
    end
    local result = service.view(id,isAdmin)
    if result then
        result.success = true;
    else
        result.success = false
    end
    ngx.say(cjson.encode(result))
end

----------------------------------------------------------------------------
-- 通过分享id获取orgid列表.
local function getOrgListByShareId()
    local id = request:getStrParam("id", true, true);
    local result = service.getOrgListByShareId(id)
    ngx.say(cjson.encode(result))
end

----------------------------------------------------------------------------
-- 修改共享.
local function updateShare()
    local id = request:getStrParam("id", true, true);
    local identity_id = request:getStrParam("identity_id", true, true);
    local org_ids = request:getStrParam("org_ids", false, true);
    local _org_ids;
    if org_ids and string.len(org_ids) > 0 then
        _org_ids = Split(org_ids, ",")
    end
    local r = { success = false }
    local result = service.updateShare(identity_id, id, _org_ids);
    r.success = result;
    ngx.say(cjson.encode(r))
end

--log.debug(context);
--log.debug(no_permission_context);
-- 配置url.
-- 按功能分
local urls = {
    context .. '/save', save,
    no_permission_context .. '/list', list,
    context .. '/update$', update,
    context .. '/delete', delete,
    context .. '/delete_detail', deleteDetail,
    no_permission_context .. '/view', view,
    no_permission_context .. '/org_list', getOrgListByShareId,
    context .. '/update_share', updateShare
}
local app = web.application(urls, nil)
app:start()