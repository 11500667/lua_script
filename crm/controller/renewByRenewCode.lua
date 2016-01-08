-- -----------------------------------------------------------------------------------
-- 描述： -> 锐捷接口续费码使用
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


local renew_code 	= args["renew_code"];
log.debug(crmModel.getCurTime().." 获取参数renew_code==>"..tostring(renew_code));

if renew_code == nil or renew_code == "" then
    local return_info = "{\"return_code\":\"200001\",\"return_msg\":\"缺少参数renew_code\"}";
    log.debug(crmModel.getCurTime().." return_info==>"..return_info);
    ngx.say(return_info);
    return;
end

local client_id 	= args["client_id"];
log.debug(crmModel.getCurTime().." 获取参数client_id==>"..tostring(client_id));

if client_id == nil or client_id == "" then
    local return_info = "{\"return_code\":\"200002\",\"return_msg\":\"缺少参数client_id\"}";
    log.debug(crmModel.getCurTime().." return_info==>"..return_info);
    ngx.say(return_info);
    return;
end

local school_manager 	= args["school_manager"];
log.debug(crmModel.getCurTime().." 获取参数school_manager==>"..tostring(school_manager));

if school_manager == nil or school_manager == "" then
    local return_info = "{\"return_code\":\"200003\",\"return_msg\":\"缺少参数school_manager\"}";
    log.debug(crmModel.getCurTime().." return_info==>"..return_info);
    ngx.say(return_info);
    return;
end


--验证续费码是否有效开始
local result,res = crmModel.checkRenewCode(renew_code);
log.debug(crmModel.getCurTime().." 验证续费码是否有效==>"..tostring(result));

if not result then
    local return_info = "{\"return_code\":\"200005\",\"return_msg\":\"续费码无效\"}";
    log.debug(crmModel.getCurTime().." return_info==>"..return_info);
    ngx.say(return_info);
    return;
end


local return_param_1 = "";

local renew_mode = res[1].renew_mode;--授权类型 1帐号 2学校
local renew_count = res[1].renew_count;--续费帐号数量
local agent_id = res[1].agent_id;--分销商id
local already_count = res[1].already_count;--已使用续费帐号数量
local is_used = res[1].is_used;--已使用续费帐号数量


log.debug(crmModel.getCurTime().." 续费码授权类型==>"..renew_mode);
log.debug(crmModel.getCurTime().." 续费帐号数量==>"..renew_count);
log.debug(crmModel.getCurTime().." 已使用续费帐号数量==>"..already_count);

if tonumber(is_used) == 1 and tonumber(renew_mode) == 2 then--是否已使用
    local return_info = "{\"return_code\":\"100010\",\"return_msg\":\"激活码已使用\"}";
    log.debug(crmModel.getCurTime().." return_info==>"..return_info);
    ngx.say(return_info);
    return;
end

--验证激活码是否有效结束

local result = crmModel.checkManagerExist(school_manager,4);
log.debug(crmModel.getCurTime().." 验证管理员帐号是否存在==>"..tostring(result));
if not result then
    local return_info = "{\"return_code\":\"100015\",\"return_msg\":\"学校管理员帐号不存在或停用\"}";
    log.debug(crmModel.getCurTime().." return_info==>"..return_info);
    ngx.say(return_info);
    return;
end


local result,res = crmModel.queryBureauByLoginName(school_manager);
log.debug(crmModel.getCurTime().." 根据管理员帐号查询学校信息==>"..tostring(result));
if not result then
    local return_info = "{\"return_code\":\"100011\",\"return_msg\":\"管理员对应的学校不存在\"}";
    log.debug(crmModel.getCurTime().." return_info==>"..return_info);
    ngx.say(return_info);
    return;
end

local bureau_id= res[1].bureau_id;
local teacher_limit= res[1].teacher_limit;



if tonumber(renew_mode) == 1 then

    if tonumber(teacher_limit) == -1 then
        local return_info = "{\"return_code\":\"200009\",\"return_msg\":\"该学校已激活学校授权，不允许使用帐号续费码\"}";
        log.debug(crmModel.getCurTime().." return_info==>"..return_info);
        ngx.say(return_info);
        return;
    end

    local renew_accounts 	= args["renew_accounts"];
    log.debug(crmModel.getCurTime().." 获取参数renew_accounts==>"..tostring(renew_accounts));

    if renew_accounts == nil or renew_accounts == "" then
        local return_info = "{\"return_code\":\"200004\",\"return_msg\":\"缺少参数renew_accounts\"}";
        log.debug(crmModel.getCurTime().." return_info==>"..return_info);
        ngx.say(return_info);
        return;
    end

    local accounts = Split(renew_accounts,",");

    local accountsStr = "";
    for i=1,#accounts do
        accountsStr = accountsStr .. "'"..accounts[i].."',";
    end

    accountsStr = string.sub(accountsStr,1,#accountsStr-1);

    local result,res = crmModel.querybureauByTeacherStr(accountsStr);
    log.debug(crmModel.getCurTime().." 根据普通教师串查询学校id状态==>"..tostring(result));
    if not result then
        local return_info = "{\"return_code\":\"000001\",\"return_msg\":\"系统错误\"}";
        log.debug(crmModel.getCurTime().." 根据普通教师串查询学校id失败@@@@@@@return_info==>"..return_info);
        ngx.say(return_info);
        return;
    end

    for i=1,#res do
        if tonumber(res[i].bureau_id)~=tonumber(bureau_id) then
            local return_info = "{\"return_code\":\"200011\",\"return_msg\":\""..res[i].login_name.."不是该学校帐号\"}";
            log.debug(crmModel.getCurTime().." @@@@@@@return_info==>"..return_info);
            ngx.say(return_info);
            return;
        end
    end


    if #accounts > (renew_count-already_count) then
        local return_info = "{\"return_code\":\"200009\",\"return_msg\":\"续费帐号数量大于续费码可续费帐号数量\"}";
        log.debug(crmModel.getCurTime().." return_info==>"..return_info);
        ngx.say(return_info);
        return;
    end

    --如果续费类型是按帐号续费，查询存在的教师帐号
    local result,res = crmModel.checkTeacherContract(accountsStr);
    log.debug(crmModel.getCurTime().." 查询普通教师帐号是否有效==>"..tostring(result));
    if not result then
        local return_info = "{\"return_code\":\"200008\",\"return_msg\":\"续费帐号不存在\"}";
        log.debug(crmModel.getCurTime().." return_info==>"..return_info);
        ngx.say(return_info);
        return;
    end


    for i=1,#res do

        local contract_id = res[i].contract_id;
        local login_name = res[i].login_name;

        local result,expire_time = crmModel.checkRenewAccounts(contract_id);
        log.debug(crmModel.getCurTime().." 续费前时间========>"..tostring(expire_time));
        if not result then
            local return_info = "{\"return_code\":\"200008\",\"return_msg\":\"续费帐号不存在\"}";
        end

        return_param_1 = return_param_1 .. login_name..",";

        --从数据库是查询的到期日志格式为20160101010101用来与当前时间比较

        local expireTable = crmModel.getDate(expire_time);
        local data_time = tonumber(string.format('%d%02d%02d%02d%02d%02d',expireTable.year,expireTable.month,expireTable.day,expireTable.hour,expireTable.min,expireTable.sec));

        --当前时间格式为20160101010101用来与数据库时间比较
        local date=os.date("%Y-%m-%d %H:%M:%S");
        local curTable = crmModel.getDate(date);
        local cut_time = tonumber(string.format('%d%02d%02d%02d%02d%02d',curTable.year,curTable.month,curTable.day,curTable.hour,curTable.min,curTable.sec));

        local expire_time = "";
        if data_time > cut_time then
            expireTable.year = expireTable.year+1;
            expire_time = string.format('%d-%02d-%02d %02d:%02d:%02d',expireTable.year,expireTable.month,expireTable.day,expireTable.hour,expireTable.min,expireTable.sec);
        else
            curTable.year = curTable.year + 1;
            expire_time = string.format('%d-%02d-%02d %02d:%02d:%02d',curTable.year,curTable.month,curTable.day,curTable.hour,curTable.min,curTable.sec);
        end

        log.debug(crmModel.getCurTime().." 续费合同========>"..tostring(contract_id));
        log.debug(crmModel.getCurTime().." 续费登录帐号========>"..tostring(login_name));
        log.debug(crmModel.getCurTime().." 续费后时间========>"..tostring(expire_time));

        local result = crmModel.updateExpireTime(expire_time,contract_id);
        log.debug(crmModel.getCurTime().." 更新过期时间是否成功==>"..tostring(result));
        if not result then
            local return_info = "{\"return_code\":\"000001\",\"return_msg\":\"系统错误\"}";
            log.debug(crmModel.getCurTime().." 更新过期时间失败@@@@@@@return_info==>"..return_info);
            ngx.print(return_info);
            return
        end

        local result = crmModel.updateAlreadyCount(renew_code);
        log.debug(crmModel.getCurTime().." 更新续费帐号个数是否成功==>"..tostring(result));
        if not result then
            local return_info = "{\"return_code\":\"000001\",\"return_msg\":\"系统错误\"}";
            log.debug(crmModel.getCurTime().." 更新续费帐号个数失败@@@@@@@return_info==>"..return_info);
            ngx.print(return_info);
            return
        end

        local result = crmModel.insertRenewDetail(renew_code,renew_mode,login_name,agent_id);
        log.debug(crmModel.getCurTime().." 续费明细表插入数据状态==>"..tostring(result));
        if not result then
            local return_info = "{\"return_code\":\"000001\",\"return_msg\":\"系统错误\"}";
            log.debug(crmModel.getCurTime().." 续费明细表插入数据失败@@@@@@@return_info==>"..return_info);
            ngx.print(return_info);
            return
        end
    end
else

    if tonumber(teacher_limit) ~= -1 then
        local return_info = "{\"return_code\":\"200010\",\"return_msg\":\"该学校已激活帐号授权，不允许使用学校续费码\"}";
        log.debug(crmModel.getCurTime().." return_info==>"..return_info);
        ngx.say(return_info);
        return;
    end

    local result,contract_id = crmModel.queryContractId(bureau_id);
    if not result then
        local return_info = "{\"return_code\":\"000001\",\"return_msg\":\"系统错误\"}";
        log.debug(crmModel.getCurTime().." 查询合同不存在@@@@@@@return_info==>"..return_info);
        ngx.print(return_info);
        return
    end

    local result,res = crmModel.queryProdectExpireTime(contract_id);
    if not result then
        local return_info = "{\"return_code\":\"000001\",\"return_msg\":\"系统错误\"}";
        log.debug(crmModel.getCurTime().." 根据合同查询产品错误@@@@@@@return_info==>"..return_info);
        ngx.print(return_info);
        return
    end
    for i=1,#res do
        log.debug(crmModel.getCurTime().." 续费前时间========>"..tostring(res[i].expire_time));
        local expireTable = crmModel.getDate(res[i].expire_time);
        local data_time = tonumber(string.format('%d%02d%02d%02d%02d%02d',expireTable.year,expireTable.month,expireTable.day,expireTable.hour,expireTable.min,expireTable.sec));

        --当前时间格式为20160101010101用来与数据库时间比较
        local date=os.date("%Y-%m-%d %H:%M:%S");
        local curTable = crmModel.getDate(date);
        local cut_time = tonumber(string.format('%d%02d%02d%02d%02d%02d',curTable.year,curTable.month,curTable.day,curTable.hour,curTable.min,curTable.sec));

        local expire_time = "";
        if data_time > cut_time then
            expireTable.year = expireTable.year+1;
            expire_time = string.format('%d-%02d-%02d %02d:%02d:%02d',expireTable.year,expireTable.month,expireTable.day,expireTable.hour,expireTable.min,expireTable.sec);
        else
            curTable.year = curTable.year + 1;
            expire_time = string.format('%d-%02d-%02d %02d:%02d:%02d',curTable.year,curTable.month,curTable.day,curTable.hour,curTable.min,curTable.sec);
        end

        local product_id = res[i].product_id;

        log.debug(crmModel.getCurTime().." 续费合同========>"..tostring(contract_id));
        log.debug(crmModel.getCurTime().." 续费产品========>"..tostring(product_id));
        log.debug(crmModel.getCurTime().." 续费后时间========>"..tostring(expire_time));

        local result = crmModel.updateProductExpireTime(contract_id,product_id,expire_time);
        if not result then
            local return_info = "{\"return_code\":\"000001\",\"return_msg\":\"系统错误\"}";
            log.debug(crmModel.getCurTime().." 根据产品id更新到期时间错误@@@@@@@return_info==>"..return_info);
            ngx.print(return_info);
            return
        end
    end

    local result = crmModel.updateRenewUse(renew_code);
    if not result then
        local return_info = "{\"return_code\":\"000001\",\"return_msg\":\"系统错误\"}";
        log.debug(crmModel.getCurTime().." 更新续费码状态时错误@@@@@@@return_info==>"..return_info);
        ngx.print(return_info);
        return
    end
end

return_param_1 = string.sub(return_param_1,1,#return_param_1-1);

local return_info = "{\"return_code\":\"000000\",\"return_msg\":\"操作成功\",\"return_param_1\":\""..return_param_1.."\"}";
log.debug(crmModel.getCurTime().." 激活成功@@@@@@@return_info==>"..return_info);
ngx.print(return_info);

