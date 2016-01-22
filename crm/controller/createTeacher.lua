-- -----------------------------------------------------------------------------------
-- 描述： -> 锐捷接口创建教师帐号
-- 作者：刘全锋
-- 日期：2015年12月24日
-- -----------------------------------------------------------------------------------

local request_method = ngx.var.request_method;
local crmModel = require "crm.model.CrmModel";
local cjson = require "cjson"
local log = require("social.common.log_ruijie");
local CacheUtil = require "common.CacheUtil";

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


local school_manager 	= args["school_manager"];
log.debug(crmModel.getCurTime().." 获取参数school_manager==>"..tostring(school_manager));

if school_manager == nil or school_manager == "" then
    local return_info = "{\"return_code\":\"200003\",\"return_msg\":\"缺少参数school_manager\"}";
    log.debug(crmModel.getCurTime().." return_info==>"..return_info);
    ngx.say(return_info);
    return;
end

local create_num 	= args["create_num"];
log.debug(crmModel.getCurTime().." 获取参数create_num==>"..tostring(create_num));

if create_num == nil or create_num == "" then
    local return_info = "{\"return_code\":\"300002\",\"return_msg\":\"缺少参数create_num\"}";
    log.debug(crmModel.getCurTime().." return_info==>"..return_info);
    ngx.say(return_info);
    return;
end

if tonumber(create_num)<= 0 then
    local return_info = "{\"return_code\":\"300007\",\"return_msg\":\"create_num参数错误\"}";
    log.debug(crmModel.getCurTime().." return_info==>"..return_info);
    ngx.say(return_info);
    return;
end


if tonumber(create_num)> 20 then
    local return_info = "{\"return_code\":\"300006\",\"return_msg\":\"每次最多创建20个教师帐号\"}";
    log.debug(crmModel.getCurTime().." return_info==>"..return_info);
    ngx.say(return_info);
    return;
end

local return_param_1 = "";

local result = crmModel.checkManagerExist(school_manager,4);
log.debug(crmModel.getCurTime().." 验证管理员帐号是否存在==>"..tostring(result));
if not result then
    local return_info = "{\"return_code\":\"100015\",\"return_msg\":\"学校管理员帐号不存在或停用\"}";
    log.debug(crmModel.getCurTime().." return_info==>"..return_info);
    ngx.say(return_info);
    return;
end

local result,auth_mode = crmModel.querySchoolActivateType(school_manager);
log.debug(crmModel.getCurTime().." 查询学校的激活类型==>"..tostring(result)); --1按帐号授权，2授权学校授权
if not result then
    local return_info = "{\"return_code\":\"300004\",\"return_msg\":\"学校管理员对应的学校未激活\"}";
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
local org_name= res[1].org_name;
local teacher_limit= res[1].teacher_limit;
local person_name = res[1].person_name;--如果按帐户激活时，作为合同名

log.debug(crmModel.getCurTime().." 学校管理员帐号@@@@@@@@return_info==>"..school_manager);
log.debug(crmModel.getCurTime().." 学校id@@@@@@@@return_info==>"..bureau_id);
log.debug(crmModel.getCurTime().." 学校名称@@@@@@@@return_info==>"..org_name);
log.debug(crmModel.getCurTime().." 可创建的最大教师数量@@@@@@@@return_info==>"..teacher_limit);

if tonumber(teacher_limit) ~= -1 then
    local result = crmModel.queryTeacherCount(bureau_id);
    log.debug(crmModel.getCurTime().." 申请创建的教师数量@@@@@@@@return_info==>"..create_num);
    log.debug(crmModel.getCurTime().." 已创建的教师数量@@@@@@@@return_info==>"..result);
    if tonumber(create_num) + tonumber(result) > tonumber(teacher_limit) then
        local return_info = "{\"return_code\":\"300005\",\"return_msg\":\"输入创建教师数量大于该学校所能创建的最大数量\"}";
        log.debug(crmModel.getCurTime().." return_info==>"..return_info);
        ngx.say(return_info);
        return;
    end
end


for i=1,tonumber(create_num) do

    --创建老师开始
    local captureResponse = ngx.location.capture("/dsideal_yy/agent/per/teacher_add?tea_name=锐捷&xb_name=男&org_id="..bureau_id.."&org_name="..org_name.."&subject_id=2&subject_name=数学&stage_id=4");

    if captureResponse.status == ngx.HTTP_OK then
        local resultJson = cjson.decode(captureResponse.body);

        local return_code = resultJson.success;
        if return_code ~= true then
            local return_info = "{\"return_code\":\"000001\",\"return_msg\":\"系统错误\"}";
            log.debug(crmModel.getCurTime().." 调用创建学校接口返回不为true@@@@@@@return_info==>"..return_info);
            ngx.print(return_info);
            return
        end
        local person_id	      = resultJson.person_id
        local identity_id     = 5;
        local login_name      = resultJson.login_name;
        return_param_1        = return_param_1 .. login_name .. ",";

        log.debug("创建教师帐号==================>"..login_name);
        log.debug("创建教师person_id==================>"..person_id);


        local pwd = "RjDs20161818";
        --更新管理员密码
        local result = crmModel.updateManagePwd(login_name,pwd);

        if not result then
            local return_info = "{\"return_code\":\"000001\",\"return_msg\":\"系统错误\"}";
            log.debug(crmModel.getCurTime().." 更新教师密码错误@@@@@@@return_info==>"..return_info);
            ngx.print(return_info);
            return
        end

        local result = CacheUtil:hset("login_"..login_name,"pwd",ngx.md5(pwd));

        if not result then
            local return_info = "{\"return_code\":\"000001\",\"return_msg\":\"系统错误\"}";
            log.debug(crmModel.getCurTime().." 更新教师密码redis缓存错误@@@@@@@return_info==>"..return_info);
            ngx.print(return_info);
            return
        end


        local contract_id = "";

        --按帐号激活时，创建个人合同开始
        if tonumber(teacher_limit) ~= -1 then
            local captureResponse = ngx.location.capture("/dsideal_yy/crm/addContract", {
                method = ngx.HTTP_POST,
                body = "customer_id="..bureau_id.."&creator_id=-1&customer_name=锐捷&bureau_type=2&edu_type=1";
            });

            if captureResponse.status == ngx.HTTP_OK then

                local resultJson = cjson.decode(captureResponse.body);
                local return_code = resultJson.success;
                if return_code ~= true then
                    local return_info = "{\"return_code\":\"000001\",\"return_msg\":\"系统错误\"}";
                    log.debug(crmModel.getCurTime().." 新增合同失败@@@@@@@return_info==>"..captureResponse.body);
                    ngx.print(return_info);
                    return
                else
                    log.debug(crmModel.getCurTime().." 新增合同Id@@@@@@@return_info==>"..resultJson.contract_id);
                    contract_id = resultJson.contract_id;

                    log.debug("创建个人合同id==================>"..contract_id);

                    local result = crmModel.insertContractUser(contract_id,person_id,identity_id);
                    log.debug(crmModel.getCurTime().." 创建个人帐户与合同关系表数据成功==>"..tostring(result));
                    if not result then
                        local return_info = "{\"return_code\":\"000001\",\"return_msg\":\"系统错误\"}";
                        log.debug(crmModel.getCurTime().." 创建个人帐户与合同关系表数据失败@@@@@@@return_info==>"..return_info);
                        ngx.print(return_info);
                        return
                    end
                end
            else
                local return_info = "{\"return_code\":\"000001\",\"return_msg\":\"系统错误\"}";
                log.debug(crmModel.getCurTime().." 新增加合同时调用接口时错误@@@@@@@return_info==>"..return_info);
                ngx.print(return_info);
                return;
            end
        end
        --创建合同结束

    else
        local return_info = "{\"return_code\":\"000001\",\"return_msg\":\"系统错误\"}";
        log.debug(crmModel.getCurTime().." 创建教师调用接口时错误@@@@@@@return_info==>"..return_info);
        ngx.print(return_info);
        return
    end
    --按帐号激活时，创建个人合同结束

end

return_param_1 = string.sub(return_param_1,1,#return_param_1-1);

local return_info = "{\"return_code\":\"000000\",\"return_msg\":\"操作成功\",\"return_param_1\":\""..return_param_1.."\"}";
log.debug(crmModel.getCurTime().." 激活成功@@@@@@@return_info==>"..return_info);
ngx.print(return_info);

