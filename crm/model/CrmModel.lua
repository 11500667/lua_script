local DBUtil   = require "common.DBUtil";
local _CrmModel = {};
local cjson = require "cjson"
local quote = ngx.quote_sql_str;
local log = require("social.common.log_ruijie");

-- -----------------------------------------------------------------------------------
-- 描述：锐捷接口 -> 获取当前时间
-- 作者：刘全锋
-- 日期：2015年12月24日
-- -----------------------------------------------------------------------------------

local function getCurTime()
    return os.date("%Y-%m-%d %H:%M:%S");
end

_CrmModel.getCurTime = getCurTime;

-- -----------------------------------------------------------------------------------
-- 描述：锐捷接口 -> 根据管理员帐号查询学校id
-- 作者：刘全锋
-- 日期：2015年12月22日
-- 参数：manager_loginname	管理员帐号
-- -----------------------------------------------------------------------------------

local function queryBureauByLoginName(manager_loginname)
    local sql = "select b.person_name, o.bureau_id,o.org_name,o.teacher_limit from t_sys_loginperson l inner join t_base_person b on l.person_id=b.person_id inner join t_base_organization o on b.bureau_id=o.bureau_id where l.identity_id=4 and l.b_use=1 and l.login_name="..quote(manager_loginname);
    log.debug(getCurTime().." sql==>"..sql.."<==");
    local res = DBUtil:querySingleSql(sql);
    if not next(res) then
        return false;
    end
    return true,res;
end

_CrmModel.queryBureauByLoginName = queryBureauByLoginName;

-- -----------------------------------------------------------------------------------
-- 描述：锐捷接口 -> 根据学校名查询管理员帐号
-- 作者：刘全锋
-- 日期：2016年01月07日
-- 参数：school_name   	    学校名
-- -----------------------------------------------------------------------------------

local function queryManagerBySchoolName(school_name,province_id,city_id,district_id)
    local sql = "select l.login_name from t_sys_loginperson l inner join t_base_person b on l.person_id=b.person_id inner join t_base_organization o on b.bureau_id=o.bureau_id where l.identity_id=4 and l.b_use=1 and o.province_id="..province_id.." and o.city_id="..city_id.." and o.district_id="..district_id.." and o.org_name="..quote(school_name);
    log.debug(getCurTime().." sql==>"..sql.."<==");
    local res = DBUtil:querySingleSql(sql);
    if not next(res) then
        return false;
    end
    return true,res;
end

_CrmModel.queryManagerBySchoolName = queryManagerBySchoolName;

-- -----------------------------------------------------------------------------------
-- 描述：锐捷接口 -> 查询是否是锐捷创建的学校
-- 作者：刘全锋
-- 日期：2016年01月07日
-- 参数：manager_loginname   	    管理员帐号manager_loginname
-- -----------------------------------------------------------------------------------

local function queryRuiJieBuildSchool(manager_loginname)
    local sql = "select count(1) as COUNT from t_crm_activate_code where created_account=" ..quote(manager_loginname);
    log.debug(getCurTime().." sql==>"..sql.."<==");
    local check_res = DBUtil:querySingleSql(sql);

    if tonumber(check_res[1].COUNT) > 0 then
        return true;
    end
    return false;
end

_CrmModel.queryRuiJieBuildSchool = queryRuiJieBuildSchool;

-- -----------------------------------------------------------------------------------
-- 描述：锐捷接口 -> 根据教师帐号查询学校信息
-- 作者：刘全锋
-- 日期：2015年12月22日
-- 参数：manager_loginname	管理员帐号
-- -----------------------------------------------------------------------------------

local function queryBureauByTeacher(manager_loginname)
    local sql = "select b.person_name, o.bureau_id,o.org_name,o.teacher_limit from t_sys_loginperson l inner join t_base_person b on l.person_id=b.person_id inner join t_base_organization o on b.bureau_id=o.bureau_id where l.identity_id=5 and l.b_use=1 and l.login_name="..quote(manager_loginname);
    log.debug(getCurTime().." sql==>"..sql.."<==");
    local res = DBUtil:querySingleSql(sql);
    if not next(res) then
        return false;
    end
    return true,res;
end

_CrmModel.queryBureauByTeacher = queryBureauByTeacher;

-- -----------------------------------------------------------------------------------
-- 描述：锐捷接口 -> 根据管理员帐号查询学校id
-- 作者：刘全锋
-- 日期：2015年12月22日
-- 参数：manager_loginname	管理员帐号
-- -----------------------------------------------------------------------------------

local function querybureauByTeacherStr(teacherStr)
    local sql = "select l.login_name,b.bureau_id from t_sys_loginperson l inner join t_base_person b on l.person_id=b.person_id  where l.identity_id=5 and l.b_use=1 and l.login_name in("..teacherStr..")";
    log.debug(getCurTime().." sql==>"..sql.."<==");
    local res = DBUtil:querySingleSql(sql);
    if not next(res) then
        return false;
    end
    return true,res;
end

_CrmModel.querybureauByTeacherStr = querybureauByTeacherStr;


-- -----------------------------------------------------------------------------------
-- 描述：锐捷接口 -> 根据学校id查普通老师帐号
-- 作者：刘全锋
-- 日期：2015年12月22日
-- 参数：bureau_id	      部门id
-- -----------------------------------------------------------------------------------

local function queryContractByBureau(bureau_id)
    local sql = "select c.contract_id from t_crm_contract_user c inner join t_base_person b on c.person_id = b.person_id where b.bureau_id="..bureau_id.." and c.identity_id=5";
    log.debug(getCurTime().." sql==>"..sql.."<==");
    local res = DBUtil:querySingleSql(sql);
    if not next(res) then
        return false;
    end
    return true,res;
end

_CrmModel.queryContractByBureau = queryContractByBureau;


-- -----------------------------------------------------------------------------------
-- 描述：锐捷接口 -> 根据管理员帐号查询学校激活类型
-- 作者：刘全锋
-- 日期：2015年12月22日
-- 参数：manager_loginname	管理员帐号
-- -----------------------------------------------------------------------------------

local function querySchoolActivateType(manager_loginname)
    local sql = "select auth_mode from t_crm_activate_code where created_account ="..quote(manager_loginname);
    log.debug(getCurTime().." sql==>"..sql.."<==");
    local res = DBUtil:querySingleSql(sql);
    if not next(res) then
        return false;
    end
    return true,res[1].auth_mode;
end

_CrmModel.querySchoolActivateType = querySchoolActivateType;



-- -----------------------------------------------------------------------------------
-- 描述：锐捷接口 -> 根据学校id更新学校创建教师的最大数量
-- 作者：刘全锋
-- 日期：2015年12月22日
-- 参数：bureau_id	  学校id
-- 参数：num	          激活所支持的最大创建教师数量
-- -----------------------------------------------------------------------------------


local function updateLimitById(bureau_id,teacher_limit,student_limit)
    local sql = "update t_base_organization set";
    if teacher_limit == "-1" then
        sql = sql.." teacher_limit=-1";
    else
        sql = sql.." teacher_limit=teacher_limit+"..teacher_limit;
    end
    sql = sql.." ,student_limit="..student_limit.." where bureau_id="..bureau_id;
    log.debug(getCurTime().." sql==>"..sql.."<==");
    local res = DBUtil:querySingleSql(sql);
    if not res then
        return false;
    end
    return true;

end

_CrmModel.updateLimitById = updateLimitById;

-- -----------------------------------------------------------------------------------
-- 描述：锐捷接口 -> 按学校创建合同时，删除按个人创建的合同
-- 作者：刘全锋
-- 日期：2015年12月22日
-- 参数：personStr         要删除的普通教师串
-- -----------------------------------------------------------------------------------

local function delContractByStr(contractStr)

    local sqlTable = {};

    local sql = "delete from t_crm_contract where contract_id in ("..contractStr..");";
    log.debug(getCurTime().." sql==>"..sql.."<==");
    table.insert(sqlTable, sql);
    local sql = "delete from t_crm_contract_user where contract_id in ("..contractStr..");";
    log.debug(getCurTime().." sql==>"..sql.."<==");
    table.insert(sqlTable, sql);
    local sql = "delete from t_crm_contract_user_organ where contract_id in ("..contractStr..");";
    log.debug(getCurTime().." sql==>"..sql.."<==");
    table.insert(sqlTable, sql);
    local sql = "delete from t_crm_contract_product where contract_id in ("..contractStr..");";
    log.debug(getCurTime().." sql==>"..sql.."<==");
    table.insert(sqlTable, sql);
    local sql = "delete from t_crm_contract_module where contract_id in ("..contractStr..");";
    log.debug(getCurTime().." sql==>"..sql.."<==");
    table.insert(sqlTable, sql);
    local sql = "delete from t_crm_contract_subject_version where contract_id in ("..contractStr..");";
    log.debug(getCurTime().." sql==>"..sql.."<==");
    table.insert(sqlTable, sql);

    if #sqlTable>0 then
        local boolResult = DBUtil: batchExecuteSqlInTx(sqlTable, #sqlTable);
        if boolResult then
            ngx.log(ngx.ERR, ">>>>>>>>>>>>>>> 批量更新[成功] <<<<<<<<<<<<<<<<<<<<");
            return true;
        else
            ngx.log(ngx.ERR, ">>>>>>>>>>>>>>> 批量更新[失败] <<<<<<<<<<<<<<<<<<<<");
            return false;
        end
    end
end

_CrmModel.delContractByStr = delContractByStr;


-- -----------------------------------------------------------------------------------
-- 描述：锐捷接口 -> 根据学校名称更新学校创建教师的最大数量
-- 作者：刘全锋
-- 日期：2015年12月22日
-- 参数：school_name	  学校名称
-- 参数：num	          激活所支持的最大创建教师数量
-- -----------------------------------------------------------------------------------

local function updateLimitByName(school_name,teacher_limit,student_limit)
    local sql = "update t_base_organization set teacher_limit="..teacher_limit..",student_limit="..student_limit.." where org_name="..quote(school_name);

    log.debug(getCurTime().." sql==>"..sql.."<==");
    local res = DBUtil:querySingleSql(sql);
    if not next(res) then
        return false;
    end
    return true;
end

_CrmModel.updateLimitByName = updateLimitByName;


-- -----------------------------------------------------------------------------------
-- 描述：锐捷接口 -> 查询激活码，用来验证码是否有效
-- 作者：刘全锋
-- 日期：2015年12月22日
-- 参数：auth_code	激活码
-- -----------------------------------------------------------------------------------


local function checkAuthCode(auth_code)
    local sql = "select auth_mode,auth_count,is_used,created_account,agent_id from t_crm_activate_code where auth_code="..quote(auth_code);

    log.debug(getCurTime().." sql==>"..sql.."<==");
    local res = DBUtil:querySingleSql(sql);
    if not next(res) then
        return false;
    end
    return true,res;
end

_CrmModel.checkAuthCode = checkAuthCode;

-- -----------------------------------------------------------------------------------
-- 描述：锐捷接口 -> 查询续费码，用来验证码是否有效
-- 作者：刘全锋
-- 日期：2015年12月24日
-- 参数：renew_code	续费码
-- -----------------------------------------------------------------------------------

local function checkRenewCode(renew_code)
    local sql = "select renew_mode,renew_count,agent_id,is_used,already_count from t_crm_renew_code where renew_code = "..quote(renew_code);

    log.debug(getCurTime().." sql==>"..sql.."<==");
    local res = DBUtil:querySingleSql(sql);
    if not next(res) then
        return false;
    end
    return true,res;
end

_CrmModel.checkRenewCode = checkRenewCode;


-- -----------------------------------------------------------------------------------
-- 描述：锐捷接口 -> 根据学校名称和所在省市区查询学校是否存在
-- 作者：刘全锋
-- 日期：2015年12月22日
-- 参数：school_name	  学校名称
-- 参数：district_id	  区的id
-- 参数：city_id	      市的id
-- 参数：unit_name	  省的id
-- -----------------------------------------------------------------------------------

local function checkSchoolExist(school_name, district_id, city_id, province_id)
    local sql = "select bureau_id from t_base_organization where org_name = '"..school_name.."' and district_id ="..district_id.." and city_id ="..city_id.." and province_id ="..province_id;
    log.debug(getCurTime().." 验证学校是否存在sql==>"..sql.."<==");
    local check_res=DBUtil:querySingleSql(sql);
    if not next(check_res) then
        return false;
    end
    return true,check_res[1].bureau_id;
end

_CrmModel.checkSchoolExist = checkSchoolExist;

-- -----------------------------------------------------------------------------------
-- 描述：锐捷接口 -> 查询管理员帐号是否有效
-- 作者：刘全锋
-- 日期：2015年12月22日
-- 参数：school_manager	  管理员帐号
-- -----------------------------------------------------------------------------------

local function checkManagerExist(school_manager,identity_id)
    local sql = "select count(1) as COUNT from t_sys_loginperson where identity_id=" ..identity_id.." and b_use=1 and login_name = "..quote(school_manager);
    log.debug(getCurTime().." sql==>"..sql.."<==");
    local check_res = DBUtil:querySingleSql(sql);

    if tonumber(check_res[1].COUNT) > 0 then
        return true;
    end
    return false;
end

_CrmModel.checkManagerExist = checkManagerExist;

-- -----------------------------------------------------------------------------------
-- 描述：锐捷接口 -> 查询创建的教师帐号数量
-- 作者：刘全锋
-- 日期：2015年12月28日
-- 参数：bureau_id	      学校id
-- -----------------------------------------------------------------------------------

local function queryTeacherCount(bureau_id)
    local sql = "select count(1) as COUNT from t_base_person where identity_id=5 and b_use=1 and bureau_id = "..bureau_id;
    log.debug(getCurTime().." sql==>"..sql.."<==");
    local res = DBUtil:querySingleSql(sql);

    return res[1].COUNT;
end

_CrmModel.queryTeacherCount = queryTeacherCount;


-- -----------------------------------------------------------------------------------
-- 描述：锐捷接口 -> 查询普通教师帐号是否有效
-- 作者：刘全锋
-- 日期：2015年12月22日
-- 参数：accountsStr	  普通教师帐号字符串 'ruijie1','ruijie2'
-- -----------------------------------------------------------------------------------

local function checkTeacherContract(accountsStr)
    local sql = "select u.contract_id,l.login_name from t_crm_contract_user u inner join t_sys_loginperson l on u.person_id = l.person_id where l.identity_id=5 and l.b_use=1 and l.login_name in ("..accountsStr..")";
    log.debug(getCurTime().." sql==>"..sql.."<==");
    local res = DBUtil:querySingleSql(sql);
    if not next(res) then
        return false;
    end
    return true,res;
end

_CrmModel.checkTeacherContract = checkTeacherContract;

-- -----------------------------------------------------------------------------------
-- 描述：锐捷接口 -> 用户使用期限表(t_crm_person_time_limit)中查询可以续费的帐号
-- 作者：刘全锋
-- 日期：2015年12月24日
-- 参数：res	  table
-- -----------------------------------------------------------------------------------

local function checkRenewAccounts(contract_id)
    local sql = "select expire_time from t_crm_contract_product where contract_id="..contract_id;
    log.debug(getCurTime().." sql==>"..sql.."<==");
    local res = DBUtil:querySingleSql(sql);
    if not next(res) then
        return false;
    end
    return true,res[1].expire_time;
end

_CrmModel.checkRenewAccounts = checkRenewAccounts;

-- -----------------------------------------------------------------------------------
-- 描述：锐捷接口 -> 用户使用期限表
-- 作者：刘全锋
-- 日期：2015年12月24日
-- 参数：res	  school_manager        教师登录帐号
-- -----------------------------------------------------------------------------------

local function queryTimeLimitByManager(school_manager)
    local sql = "select p.expire_time from t_crm_contract_user c inner join t_sys_loginperson l on c.person_id=l.person_id inner join t_crm_contract_product p on c.contract_id=p.contract_id where l.identity_id=5 and l.b_use=1 and l.login_name =" .. quote(school_manager).." limit 1";
    log.debug(getCurTime().." sql==>"..sql.."<==");
    local res = DBUtil:querySingleSql(sql);
    if not next(res) then
        return false;
    end
    return true,res[1].expire_time;
end

_CrmModel.queryTimeLimitByManager = queryTimeLimitByManager;


-- -----------------------------------------------------------------------------------
-- 描述：锐捷接口 -> 根据教师查询学校使用期限表
-- 作者：刘全锋
-- 日期：2015年12月24日
-- 参数：res	  school_manager        教师登录帐号
-- -----------------------------------------------------------------------------------

local function queryTimeLimitByBureauId(bureau_id)
    local sql = "select p.expire_time from t_crm_contract c inner join t_crm_contract_product p on c.contract_id=p.contract_id where c.customer_id =" .. bureau_id.." order by creat_time desc limit 1";
    log.debug(getCurTime().." sql==>"..sql.."<==");

    local res = DBUtil:querySingleSql(sql);
    if not next(res) then
        return false;
    end
    return true,res[1].expire_time;
end

_CrmModel.queryTimeLimitByBureauId = queryTimeLimitByBureauId;


-- -----------------------------------------------------------------------------------
-- 描述：锐捷接口 -> 查询合同id
-- 作者：刘全锋
-- 日期：2015年12月24日
-- 参数：bureau_id	  部门id
-- -----------------------------------------------------------------------------------

local function queryContractId(bureau_id)
    local sql = "select contract_id from t_crm_contract where customer_id=" .. bureau_id;
    log.debug(getCurTime().." sql==>"..sql.."<==");
    local res = DBUtil:querySingleSql(sql);
    if not next(res) then
        return false;
    end
    return true,res[1].contract_id;
end

_CrmModel.queryContractId = queryContractId;

-- -----------------------------------------------------------------------------------
-- 描述：锐捷接口 -> 查询合同id查询产品
-- 作者：刘全锋
-- 日期：2015年12月28日
-- 参数：contract_id	  合同id
-- -----------------------------------------------------------------------------------

local function queryProdectExpireTime(contract_id)
    local sql = "select product_id,expire_time from t_crm_contract_product where contract_id=" .. contract_id;
    log.debug(getCurTime().." sql==>"..sql.."<==");
    local res = DBUtil:querySingleSql(sql);
    if not next(res) then
        return false;
    end
    return true,res;
end

_CrmModel.queryProdectExpireTime = queryProdectExpireTime;


-- -----------------------------------------------------------------------------------
-- 描述：锐捷接口 -> 续费教师帐号，更新续费时间
-- 作者：刘全锋
-- 日期：2015年12月28日
-- 参数：expire_time	      过期时间
-- 参数：person_id	      教师id
-- 参数：identity_id	      身份id
-- -----------------------------------------------------------------------------------

local function updateProductExpireTime(contract_id,product_id,expire_time)

    local sql = "update t_crm_contract_product set expire_time = "..quote(expire_time);
    sql = sql .. " where product_id = "..quote(product_id).." and contract_id = "..contract_id;
    log.debug(getCurTime().." sql==>"..sql.."<==");
    local res = DBUtil:querySingleSql(sql);
    if not next(res) then
        return false;
    end
    return true;
end

_CrmModel.updateProductExpireTime = updateProductExpireTime;


-- -----------------------------------------------------------------------------------
-- 描述：锐捷接口 -> 创建帐号成功时，向t_crm_person_time_limit表中插入限制时间的数据
-- 作者：刘全锋
-- 日期：2015年12月29日
-- 参数：person_id	      教师id
-- 参数：identity_id	      身份id
-- 参数：login_name	      登录名
-- 参数：expire_time	      到期时间
-- -----------------------------------------------------------------------------------

local function insertPersonTimeLimit(person_id,identity_id,login_name,expire_time)

    local sql = "insert into t_crm_person_time_limit(person_id,identity_id,login_name,expire_time) values("..person_id..","..identity_id..","..quote(login_name)..","..quote(expire_time)..")";
    log.debug(getCurTime().." sql==>"..sql.."<==");
    local res = DBUtil:querySingleSql(sql);
    if not res then
        return false;
    end
    return true;
end

_CrmModel.insertPersonTimeLimit = insertPersonTimeLimit;



-- -----------------------------------------------------------------------------------
-- 描述：锐捷接口 -> 创建个人合同，向t_crm_contract_user表记录合同与人的关系
-- 作者：刘全锋
-- 日期：2016年01月04日
-- 参数：contract_id	      合同id
-- 参数：person_id	      用户id
-- 参数：identity_id	      身份id
-- -----------------------------------------------------------------------------------

local function insertContractUser(contract_id,person_id,identity_id)

    local sql = "insert into t_crm_contract_user(contract_id,person_id,identity_id) values("..contract_id..","..person_id..","..identity_id..")";
    log.debug(getCurTime().." sql==>"..sql.."<==");
    local res = DBUtil:querySingleSql(sql);
    if not res then
        return false;
    end
    return true;
end

_CrmModel.insertContractUser = insertContractUser;

-- -----------------------------------------------------------------------------------
-- 描述：锐捷接口 -> 记录续费明细（t_crm_renew_detail表）
-- 作者：刘全锋
-- 日期：2015年12月29日
-- 参数：person_id	      教师id
-- 参数：identity_id	      身份id
-- 参数：login_name	      登录名
-- 参数：expire_time	      到期时间
-- -----------------------------------------------------------------------------------


local function insertRenewDetail(renew_code,account_type,account_id,use_person_id)
    local date=os.date("%Y-%m-%d %H:%M:%S");
    local sql = "insert into t_crm_renew_detail(renew_code, account_type, account_id, use_time, use_person_id) values("..quote(renew_code)..","..account_type..","..quote(account_id)..","..quote(date)..","..use_person_id..")";
    log.debug(getCurTime().." sql==>"..sql.."<==");
    local res = DBUtil:querySingleSql(sql);
    if not res then
        return false;
    end
    return true;
end

_CrmModel.insertRenewDetail = insertRenewDetail;

-- -----------------------------------------------------------------------------------
-- 描述：锐捷接口 -> 续费教师帐号，更新续费时间
-- 作者：刘全锋
-- 日期：2015年12月28日
-- 参数：expire_time	      过期时间
-- 参数：person_id	      教师id
-- 参数：identity_id	      身份id
-- -----------------------------------------------------------------------------------

local function updateExpireTime(expire_time,contract_id)

    local sql = "update t_crm_contract_product set expire_time = "..quote(expire_time);
    sql = sql .. " where contract_id = "..contract_id;

    log.debug(getCurTime().." sql==>"..sql.."<==");
    local res = DBUtil:querySingleSql(sql);
    if not next(res) then
        return false;
    end
    return true;
end

_CrmModel.updateExpireTime = updateExpireTime;


-- -----------------------------------------------------------------------------------
-- 描述：锐捷接口 -> 续费教师帐号成功后更新续费码的可续费帐号数
-- 作者：刘全锋
-- 日期：2015年12月28日
-- 参数：renew_code	      续费码

-- -----------------------------------------------------------------------------------

local function updateAlreadyCount(renew_code)

    local sql = "update t_crm_renew_code set already_count = already_count+1,is_used=1 where renew_code = "..quote(renew_code);

    log.debug(getCurTime().." sql==>"..sql.."<==");
    local res = DBUtil:querySingleSql(sql);
    if not res then
        return false;
    end
    return true;
end

_CrmModel.updateAlreadyCount = updateAlreadyCount;


-- -----------------------------------------------------------------------------------
-- 描述：锐捷接口 -> 更新续费码状态
-- 作者：刘全锋
-- 日期：2015年12月28日
-- 参数：renew_code	      续费码

-- -----------------------------------------------------------------------------------

local function updateRenewUse(renew_code)

    local sql = "update t_crm_renew_code set is_used=1 where renew_code = "..quote(renew_code);

    log.debug(getCurTime().." sql==>"..sql.."<==");
    local res = DBUtil:querySingleSql(sql);
    if not res then
        return false;
    end
    return true;
end

_CrmModel.updateRenewUse = updateRenewUse;

-- -----------------------------------------------------------------------------------
-- 描述：锐捷接口 -> 激活码使用后，将激活码使用信息记录下来
-- 作者：刘全锋
-- 日期：2015年12月22日
-- 参数：school_name	      学校名称
-- 参数：auth_code	      激活码
-- 参数：created_account	  创建管理员帐号
-- -----------------------------------------------------------------------------------

local function updateAuthCodeInfo(auth_code,school_manager)

    local date=os.date("%Y-%m-%d %H:%M:%S");
    local sql = "update t_crm_activate_code set use_time = "..quote(date);
    if school_manager~="0" then
        sql = sql .. ",created_account = "..quote(school_manager);
    end
    sql = sql .. ",is_used=1 where auth_code="..quote(auth_code);
    log.debug(getCurTime().." sql==>"..sql.."<==");
    local res = DBUtil:querySingleSql(sql);
    if not next(res) then
        return false;
    end
    return true;
end

_CrmModel.updateAuthCodeInfo = updateAuthCodeInfo;


-- -----------------------------------------------------------------------------------
-- 描述：锐捷接口 -> 根据创建的学校id查询管理员帐号
-- 作者：刘全锋
-- 日期：2015年12月22日
-- 参数：school_name	      学校名称
-- -----------------------------------------------------------------------------------

local function qryManagerBySchoolName(org_id)
    local sql = "select l.login_name from t_sys_loginperson l inner join t_base_person b on l.person_id = b.person_id where l.identity_id = 4 and l.b_use = 1 and b.bureau_id = " ..org_id.." limit 1";
    log.debug(getCurTime().." sql==>"..sql.."<==");
    local res = DBUtil:querySingleSql(sql);
    if not next(res) then
        return false;
    end
    return true,res[1].login_name;
end

_CrmModel.qryManagerBySchoolName = qryManagerBySchoolName;


-- -----------------------------------------------------------------------------------
-- 描述：锐捷接口 -> 格式化时间
-- 作者：刘全锋
-- 日期：2015年12月28日
-- 参数：srcDateTime	      传入时间字符串
-- -----------------------------------------------------------------------------------

local function getDate(srcDateTime)
    --从日期字符串中截取出年月日时分秒
    local Y = string.sub(srcDateTime,1,4)
    local M = string.sub(srcDateTime,6,7)
    local D = string.sub(srcDateTime,9,10)
    local H = string.sub(srcDateTime,12,13)
    local MM = string.sub(srcDateTime,15,16)
    local SS = string.sub(srcDateTime,18,19)

    --把日期时间字符串转换成对应的日期时间
    local dt1 = os.time{year=Y, month=M, day=D, hour=H,min=MM,sec=SS }
    local newTime = os.date("*t", dt1)
    return newTime;
end

_CrmModel.getDate = getDate;


-- -----------------------------------------------------------------------------------
-- 描述：锐捷接口 -> 更新管理员密码
-- 作者：刘全锋
-- 日期：2016年01月06日
-- 参数：school_manager	      管理员帐号
-- 参数：pwd	                  管理员密码
-- -----------------------------------------------------------------------------------

local function updateManagePwd(school_manager,pwd)

    local sql = "update t_sys_loginperson set login_password = "..quote(ngx.md5(pwd));
    sql = sql .. " where login_name = "..quote(school_manager);
    log.debug(getCurTime().." sql==>"..sql.."<==");
    local res = DBUtil:querySingleSql(sql);
    if not next(res) then
        return false;
    end
    return true;
end

_CrmModel.updateManagePwd = updateManagePwd;


-- -----------------------------------------------------------------------------------
-- 描述：锐捷接口 -> 安全校验
-- 作者：刘全锋
-- 日期：2016年01月06日
-- 参数：signature	      验证字符串
-- 参数：timestamp	      时间戳
-- 参数：nonce	          随机字符串
-- -----------------------------------------------------------------------------------
local function  checkSignature(signature, timestamp, nonce)

    if tonumber(os.time()) - tonumber(timestamp)>60 then
        return false;
    end

    local token = "dsideal";
    local tab = {};
    table.insert(tab,token);
    table.insert(tab,tostring(timestamp));
    table.insert(tab,nonce);
    table.sort(tab);
    local str = table.concat(tab, "");

    local md5_str = ngx.md5(str);

    log.debug(getCurTime().." signature==>"..signature);

    if signature ~= md5_str then
        return false;
    end
    return true;
end

_CrmModel.checkSignature = checkSignature;
-- -----------------------------------------------------------------------------------

return _CrmModel




