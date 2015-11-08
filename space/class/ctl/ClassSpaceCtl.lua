--
--班级空间
-- Created by IntelliJ IDEA.
-- User: zh
-- Date: 2015/8/31
-- Time: 16:56
-- To change this template use File | Settings | File Templates.
--
local web = require("social.router.web")
local request = require("social.common.request")
local cjson = require "cjson"
local context = ngx.var.path_uri --有权限的context.
local log = require("social.common.log")
local zyModel = require "yxx.zuoye.model.ZyModel";
local wkModel = require "yxx.weike.model.WkModel";


--1)	班级学习资源（按学科分类，接微课，其他待定）
local function getClassResource()
    local class_id = request:getStrParam("class_id", false, true)
    local page_size = request:getStrParam("page_size", true, true)
    local page_number = request:getStrParam("page_number", true, true)
    local subject_id = request:getStrParam("subject_id", false, true)
    local result = wkModel:getClassWkds(class_id, subject_id, page_size, page_number);
    cjson.encode_empty_table_as_object(false)
    ngx.say(cjson.encode(result));
end

--2)	班级作业（同学生作业)
local function getClassZuoye()
    local class_id = request:getStrParam("class_id", true, true)
    local subject_id = request:getStrParam("subject_id", false, true)
    local page_size = request:getStrParam("page_size", true, true)
    local page_number = request:getStrParam("page_number", true, true)
    local result = zyModel:getClassZuoye(class_id,subject_id, page_size, page_number)
    cjson.encode_empty_table_as_object(false)
    ngx.say(cjson.encode(result));
end

-- 配置url.
-- 按功能分
local urls = {
    context .. '/getClassResource', getClassResource, --1)	班级学习资源
    context .. '/getClassZuoye', getClassZuoye, --2)	班级作业
}
local app = web.application(urls, nil)
app:start()
