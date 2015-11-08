--

-- Created by IntelliJ IDEA.
-- User: zh
-- Date: 2015/7/24
-- Time: 9:21
-- To change this template use File | Settings | File Templates.
-- 动态信息 controller.

ngx.header.content_type = "text/plain";
local web = require("social.router.web")
local cjson = require "cjson"
local request = require("social.common.request")
local context = ngx.var.path_uri --有权限的context.
local log = require("social.common.log")
local service = require("space.dynamic.service.DynamicService")
------------------------------------------------------------------------------------------------------------------------
-- 保存动态信息.
local function save()
    local person_id = request:getStrParam("person_id", true, true)
    local identity_id = request:getStrParam("identity_id", true, true)
    local city_id = request:getStrParam("city_id", true, true)
    local province_id = request:getStrParam("province_id", true, true)
    local area_id = request:getStrParam("area_id", true, true)
    local school_id = request:getStrParam("school_id", true, true)
    local class_id = request:getStrParam("class_id", true, true)
    local group_id = request:getStrParam("group_id", true, true)
    local message_type = request:getStrParam("message_type", true, true)
    local message = request:getStrParam("message", true, true)
    local param = { identity_id = identity_id, person_id = person_id, city_id = city_id, province_id = province_id, area_id = area_id, school_id = school_id, class_id = class_id, group_id = group_id, message_type = message_type, message = message }
    local r = { success = false }
    local result = service.saveDynamicInfo(param)
    if result then
        r.success = true;
        ngx.say(cjson.encode(r));
    end
end

------------------------------------------------------------------------------------------------------------------------
-- 动态信息查询.
local function query()
    local person_id = request:getStrParam("person_id", true, true)
    local identity_id = request:getStrParam("identity_id", false, true)
    local type = request:getNumParam("type", true, true)
    local message_type = request:getNumParam("message_type", true, true)
    local pagenum = request:getNumParam("pagenum", true, true)
    local pagesize = request:getNumParam("pagesize", true, true)

    local city_id = request:getStrParam("city_id", false, true)
    local province_id = request:getStrParam("province_id", false, true)
    local area_id = request:getStrParam("area_id", false, true)
    local school_id = request:getStrParam("school_id", false, true)
    local class_id = request:getStrParam("class_id", false, true)
    local group_id = request:getStrParam("group_id", false, true)

    local param = { person_id = person_id, identity_id = identity_id, message_type = message_type, pagenum = pagenum, pagesize = pagesize, city_id = city_id, province_id = province_id, area_id = area_id, school_id = school_id, class_id = class_id, group_id = group_id,type=type}
    local result = service.getDynamicInfoList(param)
    ngx.say(cjson.encode(result));
end


-- 配置url.
-- 按功能分
local urls = {
    context .. '/save', save,
    context .. '/query', query,
}
local app = web.application(urls, nil)
app:start()