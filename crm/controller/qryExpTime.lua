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


local account_id 	= args["account_id"];
log.debug(crmModel.getCurTime().." 获取参数account_id==>"..tostring(account_id));

if account_id == nil or account_id == "" then
    local return_info = "{\"return_code\":\"400001\",\"return_msg\":\"缺少参数account_id\"}";
    log.debug(crmModel.getCurTime().." return_info==>"..return_info);
    ngx.say(return_info);
    return;
end

local result = crmModel.checkManagerExist(account_id,5);
log.debug(crmModel.getCurTime().." 验证老师帐号是否存在==>"..tostring(result));
if not result then
    local return_info = "{\"return_code\":\"400002\",\"return_msg\":\"教师帐号不存在或停用\"}";
    log.debug(crmModel.getCurTime().." return_info==>"..return_info);
    ngx.say(return_info);
    return;
end


local result,res = crmModel.queryBureauByTeacher(account_id);
log.debug(crmModel.getCurTime().." 验证老师帐号是否存在==>"..tostring(result));
if not result then
    local return_info = "{\"return_code\":\"000001\",\"return_msg\":\"系统错误\"}";
    log.debug(crmModel.getCurTime().." 根据教师帐号查询学校信息错误return_info==>"..return_info);
    ngx.say(return_info);
    return;
end

local bureau_id= res[1].bureau_id;
local org_name= res[1].org_name;
local teacher_limit= res[1].teacher_limit;

log.debug(crmModel.getCurTime().." 查询学校id@@@@@@@@return_info==>"..bureau_id);
log.debug(crmModel.getCurTime().." 查询学校名称@@@@@@@@return_info==>"..org_name);
log.debug(crmModel.getCurTime().." 查询可创建的最大教师数量@@@@@@@@return_info==>"..teacher_limit);

local result,expire_time;

if tonumber(teacher_limit) ~= -1 then
    result,expire_time = crmModel.queryTimeLimitByManager(account_id);
    if not result then
        local return_info = "{\"return_code\":\"400002\",\"return_msg\":\"教师帐号不存在或停用\"}";
        log.debug(crmModel.getCurTime().." return_info==>"..return_info);
        ngx.say(return_info);
        return;
    end
else
    result,expire_time = crmModel.queryTimeLimitByBureauId(bureau_id);
    if not result then
        local return_info = "{\"return_code\":\"400002\",\"return_msg\":\"教师帐号不存在或停用\"}";
        log.debug(crmModel.getCurTime().." return_info==>"..return_info);
        ngx.say(return_info);
        return;
    end
end


log.debug(crmModel.getCurTime().." 查询帐号==>"..account_id);
log.debug(crmModel.getCurTime().." 到期时间==>"..expire_time);

local expireTable = crmModel.getDate(expire_time);
local data_time = tonumber(string.format('%d%02d%02d%02d%02d%02d',expireTable.year,expireTable.month,expireTable.day,expireTable.hour,expireTable.min,expireTable.sec));


--当前时间格式为20160101010101用来与数据库时间比较
local date=os.date("%Y-%m-%d %H:%M:%S");
local curTable = crmModel.getDate(date);
local cut_time = tonumber(string.format('%d%02d%02d%02d%02d%02d',curTable.year,curTable.month,curTable.day,curTable.hour,curTable.min,curTable.sec));

local return_param_2 = "";

log.debug(crmModel.getCurTime().." data_time==>"..data_time);
log.debug(crmModel.getCurTime().." cut_time==>"..cut_time);

if tonumber(data_time) > tonumber(cut_time) then
    return_param_2 = 0;
    log.debug(crmModel.getCurTime().." 帐号是否过期@@@@@@@return_info==>否");
else
    return_param_2 = 1;
    log.debug(crmModel.getCurTime().." 帐号是否过期@@@@@@@return_info==>是");
end



local return_info = "{\"return_code\":\"000000\",\"return_msg\":\"操作成功\",\"return_param_1\":\""..expire_time.."\",\"return_param_2\":\""..return_param_2.."\"}";
log.debug(crmModel.getCurTime().." 查询成功@@@@@@@return_info==>"..return_info);
ngx.print(return_info);

