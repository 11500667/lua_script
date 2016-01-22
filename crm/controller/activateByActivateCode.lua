-- -----------------------------------------------------------------------------------
-- 描述： -> 锐捷接口激活码使用
-- 作者：刘全锋
-- 日期：2015年12月21日
-- -----------------------------------------------------------------------------------

local request_method = ngx.var.request_method;
local cjson = require "cjson"
local crmModel = require "crm.model.CrmModel";

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


local auth_code 	= args["auth_code"];
log.debug(crmModel.getCurTime().." 获取参数auth_code==>"..tostring(auth_code));

if auth_code == nil or auth_code == "" then
    local return_info = "{\"return_code\":100001,\"return_msg\":\"缺少参数auth_code\"}";
    log.debug(crmModel.getCurTime().." return_info==>"..return_info);
    ngx.say(return_info);
    return;
end

local client_id 	= args["client_id"];
log.debug(crmModel.getCurTime().." 获取参数client_id==>"..tostring(client_id));

if client_id == nil or client_id == "" then
    local return_info = "{\"return_code\":\"100002\",\"return_msg\":\"缺少参数client_id\"}";
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


local school_name 	= args["school_name"];
log.debug(crmModel.getCurTime().." 获取参数school_name==>"..tostring(school_name));

if school_name == nil or school_name == "" then
    local return_info = "{\"return_code\":\"100006\",\"return_msg\":\"缺少参数school_name\"}";
    log.debug(crmModel.getCurTime().." return_info==>"..return_info);
    ngx.say(return_info);
    return;
end


local school_type 	= args["school_type"];
log.debug(crmModel.getCurTime().." 获取参数school_type==>"..tostring(school_type));

if school_type == nil or school_type == "" then
    local return_info = "{\"return_code\":\"100007\",\"return_msg\":\"缺少参数school_type\"}";
    log.debug(crmModel.getCurTime().." return_info==>"..return_info);
    ngx.say(return_info);
    return;
end


local school_manager 	= args["school_manager"];
log.debug(crmModel.getCurTime().." 获取参数school_manager==>"..tostring(school_manager));

if school_manager == nil or school_manager == "" then
    local return_info = "{\"return_code\":\"100008\",\"return_msg\":\"缺少参数school_manager\"}";
    log.debug(crmModel.getCurTime().." return_info==>"..return_info);
    ngx.say(return_info);
    return;
end


--验证激活码是否有效开始
local result,res = crmModel.checkAuthCode(auth_code);
log.debug(crmModel.getCurTime().." 验证激活码是否有效==>"..tostring(result));

if not result then
    local return_info = "{\"return_code\":\"100009\",\"return_msg\":\"激活码无效\"}";
    log.debug(crmModel.getCurTime().." return_info==>"..return_info);
    ngx.say(return_info);
    return;
end


log.debug(crmModel.getCurTime().." 激活码使用状态==>"..res[1].is_used);

if tonumber(res[1].is_used) == 1 then--是否已使用
    local return_info = "{\"return_code\":\"100010\",\"return_msg\":\"激活码已使用\"}";
    log.debug(crmModel.getCurTime().." return_info==>"..return_info);
    ngx.say(return_info);
    return;
end

local return_param_1 = "";

local auth_mode = res[1].auth_mode;--授权类型 1帐号 2学校
local auth_count = res[1].auth_count;--创建教师数量
local agent_id = res[1].agent_id;

log.debug(crmModel.getCurTime().." 激活码授权类型==>"..auth_mode);
log.debug(crmModel.getCurTime().." 激活码创建教师数量==>"..auth_count);

--验证激活码是否有效结束

--当新建学校或根据管理员帐号查询学校时，验证所传参数是否存在开始
if school_name == "0" and  school_manager == "0" then
    local return_info = "{\"return_code\":\"100012\",\"return_msg\":\"学校管理员帐号和学校名称不能同时0\"}";
    log.debug(crmModel.getCurTime().." return_info==>"..return_info);
    ngx.say(return_info);
    return;
else
    --学校名称和管理员帐号必须有一个为0
    if school_name ~= "0" and  school_manager ~= "0" then
        local return_info = "{\"return_code\":\"100013\",\"return_msg\":\"学校管理员帐号和学校名称必须有一个为0\"}";
        log.debug(crmModel.getCurTime().." return_info==>"..return_info);
        ngx.say(return_info);
        return;
    end

    --学校不为0时是新建学校，根据学校全名和省市区查询学校是否存在，存在则无法创建学校
    if school_name ~= "0" then
        local result = crmModel.checkSchoolExist(school_name,district_id,city_id,province_id);
        log.debug(crmModel.getCurTime().." 验证学校是否存在==>"..tostring(result));
        if result then
            local return_info = "{\"return_code\":\"100014\",\"return_msg\":\"同一个地区不能添加同名的学校\"}";
            log.debug(crmModel.getCurTime().." return_info==>"..return_info);
            ngx.say(return_info);
            return;
        end
    end

    --验证输入的管理员帐号是否存在
    if school_manager ~= "0" then
        local result = crmModel.checkManagerExist(school_manager,4);
        log.debug(crmModel.getCurTime().." 验证管理员帐号是否存在==>"..tostring(result));
        if not result then
            local return_info = "{\"return_code\":\"100015\",\"return_msg\":\"学校管理员帐号不存在或停用\"}";
            log.debug(crmModel.getCurTime().." return_info==>"..return_info);
            ngx.say(return_info);
            return;
        end
    end
end
--当新建学校或根据管理员帐号查询学校时，验证所传参数是否存在结束


--school_name不等0时，创建学校
if school_name ~= "0" and school_name ~= 0 then


    local area_id = "0";

    if district_id ~= "0" then
        area_id = district_id;
    elseif city_id ~= "0" then
        area_id = city_id;
    elseif city_id ~= "0" then
        area_id = province_id;
    end

    local captureResponse = ngx.location.capture("/dsideal_yy/crm/addEduUnit?area_id="..area_id.."&pId1="..province_id.."&pId2="..city_id.."&pId3="..district_id.."&org_type=2&unit_name="..school_name.."&edu_type=1&register_flag=0&business_system=COMMON&school_type="..school_type);

    local return_code = "";

    if captureResponse.status == ngx.HTTP_OK then

        local resultJson = cjson.decode(captureResponse.body);

        local return_code = resultJson.success;
        local return_orgId = resultJson.org_id;

        if return_code ~= true then
            local return_info = "{\"return_code\":\"000001\",\"return_msg\":\"系统错误\"}";
            log.debug(crmModel.getCurTime().." 调用创建学校接口返回不为true@@@@@@@return_info==>"..return_info);
            ngx.print(return_info);
            return
        end

        if tonumber(auth_mode) == 1 then--按帐号授权时，设置创建教师最大数量
            local result = crmModel.updateLimitByName(school_name,auth_count,0);
            if not result then
                local return_info = "{\"return_code\":\"000001\",\"return_msg\":\"系统错误\"}";
                log.debug(crmModel.getCurTime().." 创建学校后更新教师最大数量时错误@@@@@@@return_info==>"..return_info);
                ngx.print(return_info);
                return
            end
        else--按学校授权时，不限制创建教师数量
            local result = crmModel.updateLimitByName(school_name,-1,0);
            if not result then
                local return_info = "{\"return_code\":\"000001\",\"return_msg\":\"系统错误\"}";
                log.debug(crmModel.getCurTime().." 创建学校后更新不限制教师数量时错误@@@@@@@return_info==>"..return_info);
                ngx.print(return_info);
                return
            end
        end

        --获取管理员帐号
        local result,school_manager = crmModel.qryManagerBySchoolName(return_orgId);

        if not result then
            local return_info = "{\"return_code\":\"000001\",\"return_msg\":\"系统错误\"}";
            log.debug(crmModel.getCurTime().." 创建学校后获取管理员帐号错误@@@@@@@return_info==>"..return_info);
            ngx.print(return_info);
            return
        end

        --更新激活码的将管理员帐号和卡的使用状态
        local result = crmModel.updateAuthCodeInfo(auth_code,school_manager);

        if not result then
            local return_info = "{\"return_code\":\"000001\",\"return_msg\":\"系统错误\"}";
            log.debug(crmModel.getCurTime().." 创建学校后更新激活码信息时错误@@@@@@@return_info==>"..return_info);
            ngx.print(return_info);
            return
        end

        return_param_1 = school_manager;

        local pwd = "RjDs20161818";
        --更新管理员密码
        local result = crmModel.updateManagePwd(school_manager,pwd);

        if not result then
            local return_info = "{\"return_code\":\"000001\",\"return_msg\":\"系统错误\"}";
            log.debug(crmModel.getCurTime().." 更新管理员密码错误@@@@@@@return_info==>"..return_info);
            ngx.print(return_info);
            return
        end


        --新建学校时，在t_crm_customer新增机构，用来与合同关联开始
        local captureResponse = ngx.location.capture("/dsideal_yy/crm/addCustomer", {
            method = ngx.HTTP_POST,
            body = "customer_id="..return_orgId.."&customer_name="..school_name.."&bureau_type=2&edu_type=1"
        });

        if captureResponse.status == ngx.HTTP_OK then
            local resultJson = cjson.decode(captureResponse.body);
            local return_code = resultJson.success;
            if return_code ~= true then
                local return_info = "{\"return_code\":\"000001\",\"return_msg\":\"系统错误\"}";
                log.debug(crmModel.getCurTime().." 新增机构，用来与合同关联失败@@@@@@@return_info==>"..captureResponse.body);
                ngx.print(return_info);
                return
            end
        else
            local return_info = "{\"return_code\":\"000001\",\"return_msg\":\"系统错误\"}";
            log.debug(crmModel.getCurTime().." 新增机构，用来与合同关联接口时错误@@@@@@@return_info==>"..return_info);
            ngx.print(return_info);
            return;
        end
        --新建学校时，在t_crm_customer新增机构，用来与合同关联结束

        if tonumber(auth_mode) == 2 then

            local captureResponse = ngx.location.capture("/dsideal_yy/crm/addContract", {
                method = ngx.HTTP_POST,
                body = "customer_id="..return_orgId.."&creator_id=-1&customer_name="..school_name.."&bureau_type=2&edu_type=1"
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
                end
            else
                local return_info = "{\"return_code\":\"000001\",\"return_msg\":\"系统错误\"}";
                log.debug(crmModel.getCurTime().." 新增加合同时调用接口时错误@@@@@@@return_info==>"..return_info);
                ngx.print(return_info);
                return;
            end
        end

    else
        local return_info = "{\"return_code\":\"000001\",\"return_msg\":\"系统错误\"}";
        log.debug(crmModel.getCurTime().." 创建管理员调用接口时错误@@@@@@@return_info==>"..return_info);
        ngx.print(return_info);
        return
    end

--给已经存在的学校扩充创建教师的最大数量
else
    --根据管理员帐号查询学校
    local result,res = crmModel.queryBureauByLoginName(school_manager);

    local bureau_id = res[1].bureau_id;

    if not result then
        local return_info = "{\"return_code\":\"100011\",\"return_msg\":\"管理员对应的学校不存在\"}";
        log.debug(crmModel.getCurTime().." return_info==>"..return_info);
        ngx.print(return_info)
        return
    end

    if res[1].teacher_limit == -1 then
        local return_info = "{\"return_code\":\"100016\",\"return_msg\":\"该学校创建教师数量无限制，不允许使用激活码\"}";
        log.debug(crmModel.getCurTime().." return_info==>"..return_info);
        ngx.print(return_info);
        return
    end

    if tonumber(auth_mode) == 1 then--按帐号授权时，设置创建教师最大数量

        local result = crmModel.updateLimitById(bureau_id,auth_count,0);--第三个参数学生最大创建数量为0
        if not result then
            local return_info = "{\"return_code\":\"000001\",\"return_msg\":\"系统错误\"}";
            log.debug(crmModel.getCurTime().." 学校已存在按帐号授权时，更新激活码信息时错误@@@@@@@return_info==>"..return_info);
            ngx.print(return_info);
            return
        end
    else--按学校授权时，不限制创建教师数量
        local result = crmModel.updateLimitById(bureau_id,"-1",0);--第三个参数学生最大创建数量为0
        if not result then
            local return_info = "{\"return_code\":\"000001\",\"return_msg\":\"系统错误\"}";
            log.debug(crmModel.getCurTime().." 学校已存在按学校授权时，更新激活码信息时错误@@@@@@@return_info==>"..return_info);
            ngx.print(return_info);
            return
        end

        --按学校激活时，新增合同
        local captureResponse = ngx.location.capture("/dsideal_yy/crm/addContract", {
            method = ngx.HTTP_POST,
            body = "customer_id="..bureau_id.."&creator_id=-1&customer_name="..res[1].org_name.."&bureau_type=2&edu_type=1"
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
                log.debug(crmModel.getCurTime().." 将帐激活改为学校激活新增合同Id@@@@@@@return_info==>"..resultJson.contract_id);
            end
        else
            local return_info = "{\"return_code\":\"000001\",\"return_msg\":\"系统错误\"}";
            log.debug(crmModel.getCurTime().." 新增加合同时调用接口时错误@@@@@@@return_info==>"..return_info);
            ngx.print(return_info);
            return;
        end

        local result,res = crmModel.queryContractByBureau(bureau_id);

        if not result then
            local return_info = "{\"return_code\":\"000001\",\"return_msg\":\"系统错误\"}";
            log.debug(crmModel.getCurTime().." 根据学校id查询普通教师时错误@@@@@@@return_info==>"..return_info);
            ngx.print(return_info);
            return
        end

        local contractStr = "";
        for i=1,#res do
            contractStr = contractStr..res[i].contract_id..",";
        end

        contractStr = string.sub(contractStr,1,#contractStr-1);

        if #contractStr > 1 then
            local result = crmModel.delContractByStr(contractStr);

            if not result then
                local return_info = "{\"return_code\":\"000001\",\"return_msg\":\"系统错误\"}";
                log.debug(crmModel.getCurTime().."按学校创建合同时，删除按个人创建的合同失败@@@@@@@return_info==>"..return_info);
                ngx.print(return_info);
                return;
            end
        end
    end

    --更新激活码信息
    local result = crmModel.updateAuthCodeInfo(auth_code,"0");

    local result,res = crmModel.queryBureauByLoginName(school_manager);

    return_param_1 = res[1].teacher_limit;

    log.debug(crmModel.getCurTime().." 使用的激活码@@@@@@@return_info==>"..auth_code);
    log.debug(crmModel.getCurTime().." 学校管理员帐号@@@@@@@return_info==>"..school_manager);
    log.debug(crmModel.getCurTime().." 该学校可创建的最大教师数量@@@@@@@return_info==>"..return_param_1);


end

local return_info = "{\"return_code\":\"000000\",\"return_msg\":\"操作成功\",\"return_param_1\":\""..return_param_1.."\"}";
log.debug(crmModel.getCurTime().." 激活成功@@@@@@@return_info==>"..return_info);
ngx.print(return_info);