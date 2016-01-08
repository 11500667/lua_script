-- -----------------------------------------------------------------------------------
-- 描述： -> 锐捷接口创建教师帐号
-- 作者：刘全锋
-- 日期：2015年12月24日
-- -----------------------------------------------------------------------------------

local request_method = ngx.var.request_method;
local crmModel = require "crm.model.CrmModel";
local cjson = require "cjson"
local log = require("social.common.log_ruijie");

local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end


local signature 	= args["signature"];
log.debug(crmModel.getCurTime().." 获取参数signature==>"..tostring(signature));
if signature == nil or signature == "" then
    local return_info = "{\"return_code\":\"000002\",\"return_msg\":\"缺少参数signature\"}";
    log.debug(crmModel.getCurTime().." return_info==>"..return_info);
    ngx.say(return_info);
    return;
end

local timestamp 	= args["timestamp"];
log.debug(crmModel.getCurTime().." 获取参数timestamp==>"..tostring(timestamp));
if timestamp == nil or timestamp == "" then
    local return_info = "{\"return_code\":\"000003\",\"return_msg\":\"缺少参数timestamp\"}";
    log.debug(crmModel.getCurTime().." return_info==>"..return_info);
    ngx.say(return_info);
    return;
end

local nonce 	= args["nonce"];
log.debug(crmModel.getCurTime().." 获取参数nonce==>"..tostring(nonce));
if nonce == nil or nonce == "" then
    local return_info = "{\"return_code\":\"000004\",\"return_msg\":\"缺少参数nonce\"}";
    log.debug(crmModel.getCurTime().." return_info==>"..return_info);
    ngx.say(return_info);
    return;
end

local result = crmModel.checkSignature(signature, timestamp, nonce);
log.debug(crmModel.getCurTime().." 安全验证是否成功==>"..tostring(result));
if not result then
    local return_info = "{\"return_code\":\"000005\",\"return_msg\":\"验证失败\"}";
    log.debug(crmModel.getCurTime().." return_info==>"..return_info);
    ngx.say(return_info);
    return;
end


local school_name 	= args["school_name"];
log.debug(crmModel.getCurTime().." 获取参数school_name==>"..tostring(school_name));

if school_name == nil or school_name == "" then
    local return_info = "{\"return_code\":\"500001\",\"return_msg\":\"缺少参数school_name\"}";
    log.debug(crmModel.getCurTime().." return_info==>"..return_info);
    ngx.say(return_info);
    return;
end

local province_id 	= args["province_id"];
log.debug(crmModel.getCurTime().." 获取参数province_id==>"..tostring(province_id));

if province_id == nil or province_id == "" then
    local return_info = "{\"return_code\":\"100003\",\"return_msg\":\"缺少参数province_id\"}";
    log.debug(crmModel.getCurTime().." return_info==>"..return_info);
    ngx.say(return_info);
    return;
end

local city_id 	= args["city_id"];
log.debug(crmModel.getCurTime().." 获取参数city_id==>"..tostring(city_id));

if city_id == nil or city_id == "" then
    local return_info = "{\"return_code\":\"100004\",\"return_msg\":\"缺少参数city_id\"}";
    log.debug(crmModel.getCurTime().." return_info==>"..return_info);
    ngx.say(return_info);
    return;
end


local district_id 	= args["district_id"];
log.debug(crmModel.getCurTime().." 获取参数district_id==>"..tostring(district_id));

if district_id == nil or district_id == "" then
    local return_info = "{\"return_code\":\"100005\",\"return_msg\":\"缺少参数district_id\"}";
    log.debug(crmModel.getCurTime().." return_info==>"..return_info);
    ngx.say(return_info);
    return;
end


local return_param_1 = "0";--学校是否存在      0不存在    1存在
local return_param_2 = "0";--是否是锐捷创建     0不是锐捷创建    1是锐捷创建
local return_param_3 = "0";--如果是锐捷创建返回管理员帐号
local login_name = "0";

local result,res = crmModel.queryManagerBySchoolName(school_name,tonumber(province_id),tonumber(city_id),tonumber(district_id));
log.debug(crmModel.getCurTime().." 根据学校名查询管理员帐号是否存在==>"..tostring(result));
if result then
    return_param_1 = "1";
    login_name = res[1].login_name;

    local result = crmModel.queryRuiJieBuildSchool(login_name);

    if result then
        return_param_2 = "1";
        return_param_3 = login_name;
    end
end


local return_info = "{\"return_code\":\"000000\",\"return_msg\":\"操作成功\",\"return_param_1\":\""..return_param_1.."\",\"return_param_2\":\""..return_param_2.."\",\"return_param_3\":\""..return_param_3.."\"}";
log.debug(crmModel.getCurTime().." 查询成功@@@@@@@return_info==>"..return_info);
ngx.print(return_info);

