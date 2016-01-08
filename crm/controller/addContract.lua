-- -----------------------------------------------------------------------------------
-- 描述： -> 创建合同
-- 作者：刘全锋
-- 日期：2015年12月30日
-- -----------------------------------------------------------------------------------

local request_method = ngx.var.request_method;
local crmModel = require "crm.model.CrmModel";
local cjson = require "cjson"
local quote = ngx.quote_sql_str;
local date=os.date("%Y-%m-%d %H:%M:%S");
local DBUtil   = require "common.DBUtil";
local log = require("social.common.log_ruijie");


local curTable = crmModel.getDate(date);
curTable.year = curTable.year+1;
local expire_time = string.format('%d-%02d-%02d %02d:%02d:%02d',curTable.year,curTable.month,curTable.day,curTable.hour,curTable.min,curTable.sec);

local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end


local customer_id 	= args["customer_id"];

if customer_id == nil or customer_id == "" then
    local return_info = "{\"success\":false,\"info\":\"缺少参数customer_id\"}";
    ngx.say(return_info);
    return;
end

local customer_name 	= args["customer_name"];

if customer_name == nil or customer_name == "" then
    local return_info = "{\"success\":false,\"info\":\"缺少参数customer_name\"}";
    ngx.say(return_info);
    return;
end


local creator_id 	= args["creator_id"];

if creator_id == nil or creator_id == "" then
    local return_info = "{\"success\":false,\"info\":\"缺少参数creator_id\"}";
    ngx.say(return_info);
    return;
end


local sql = "SELECT MAX(contract_id)+1 AS contract_id FROM t_crm_contract";
local res = DBUtil:querySingleSql(sql);
local contract_id = res[1].contract_id;

log.debug(" sql==>"..sql.."<==");


-- 插入合同
local contract_name = customer_name .. "合同";
local sql = "INSERT INTO t_crm_contract (contract_id,contract_name, customer_id, creator_id, creat_time, modify_time) VALUES ("..contract_id..","..quote(contract_name)..", "..customer_id..", "..creator_id..", "..quote(date)..", "..quote(date)..");";

log.debug(" sql==>"..sql.."<==");

local res = DBUtil:querySingleSql(sql);
if not res then
    local return_info = "{\"success\":false,\"info\":\"创建合同失败\"}";
    ngx.say(return_info);
    return false;
end

local sqlTable = {};


-- 插入合同用户关系数据
local sql = "INSERT INTO t_crm_contract_user_organ (contract_id, org_id, org_name) VALUES ("..contract_id..", 0, '所有');";

log.debug(" sql==>"..sql.."<==");

table.insert(sqlTable, sql);

-- 插入合同对应的产品
local sql = "INSERT INTO t_crm_contract_product (contract_id, product_id, expire_time, client_limit) VALUES ("..contract_id..", 'dzsb', "..quote(expire_time)..", -1);";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_product (contract_id, product_id, expire_time, client_limit) VALUES ("..contract_id..", 'eduoffice', "..quote(expire_time)..", -1);";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_product (contract_id, product_id, expire_time, client_limit) VALUES ("..contract_id..", 'kj', "..quote(expire_time)..", -1);";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_product (contract_id, product_id, expire_time, client_limit) VALUES ("..contract_id..", 'ptzj', "..quote(expire_time)..", -1);";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_product (contract_id, product_id, expire_time, client_limit) VALUES ("..contract_id..", 'teachpt', "..quote(expire_time)..", -1);";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_product (contract_id, product_id, expire_time, client_limit) VALUES ("..contract_id..", 'xnfzsys', "..quote(expire_time)..", -1);";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_product (contract_id, product_id, expire_time, client_limit) VALUES ("..contract_id..", 'ybk', "..quote(expire_time)..", -1);";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_product (contract_id, product_id, expire_time, client_limit) VALUES ("..contract_id..", 'yxx', "..quote(expire_time)..", -1);";
table.insert(sqlTable, sql);

-- 插入合同和模块的对应关系
local sql = "INSERT INTO t_crm_contract_module (contract_id, product_id, module_id) VALUES ("..contract_id..", 'dzsb', 'dzsb_cs');";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_module (contract_id, product_id, module_id) VALUES ("..contract_id..", 'dzsb', 'dzsb_dzs');";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_module (contract_id, product_id, module_id) VALUES ("..contract_id..", 'dzsb', 'dzsb_hx');";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_module (contract_id, product_id, module_id) VALUES ("..contract_id..", 'dzsb', 'dzsb_xa');";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_module (contract_id, product_id, module_id) VALUES ("..contract_id..", 'dzsb', 'dzsb_bjb');";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_module (contract_id, product_id, module_id) VALUES ("..contract_id..", 'eduoffice', 'eduoffice_hx');";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_module (contract_id, product_id, module_id) VALUES ("..contract_id..", 'eduoffice', 'eduoffice_xkgj');";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_module (contract_id, product_id, module_id) VALUES ("..contract_id..", 'kj', 'kj_hx');";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_module (contract_id, product_id, module_id) VALUES ("..contract_id..", 'ptzj', 'ptzj_hx');";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_module (contract_id, product_id, module_id) VALUES ("..contract_id..", 'teachpt', 'teachpt_gj');";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_module (contract_id, product_id, module_id) VALUES ("..contract_id..", 'teachpt', 'teachpt_hx');";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_module (contract_id, product_id, module_id) VALUES ("..contract_id..", 'xnfzsys', 'xnfzsys_hx');";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_module (contract_id, product_id, module_id) VALUES ("..contract_id..", 'ybk', 'ybk_bkk');";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_module (contract_id, product_id, module_id) VALUES ("..contract_id..", 'ybk', 'ybk_bkx');";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_module (contract_id, product_id, module_id) VALUES ("..contract_id..", 'ybk', 'ybk_hx');";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_module (contract_id, product_id, module_id) VALUES ("..contract_id..", 'ybk', 'ybk_sjk');";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_module (contract_id, product_id, module_id) VALUES ("..contract_id..", 'ybk', 'ybk_stk');";
local sql = "INSERT INTO t_crm_contract_module (contract_id, product_id, module_id) VALUES ("..contract_id..", 'ybk', 'ybk_wkk');";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_module (contract_id, product_id, module_id) VALUES ("..contract_id..", 'ybk', 'ybk_yp');";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_module (contract_id, product_id, module_id) VALUES ("..contract_id..", 'ybk', 'ybk_zyk');";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_module (contract_id, product_id, module_id) VALUES ("..contract_id..", 'yxx', 'yxx_ctb');";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_module (contract_id, product_id, module_id) VALUES ("..contract_id..", 'yxx', 'yxx_hx');";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_module (contract_id, product_id, module_id) VALUES ("..contract_id..", 'yxx', 'yxx_rwddx');";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_module (contract_id, product_id, module_id) VALUES ("..contract_id..", 'yxx', 'yxx_wk');";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_module (contract_id, product_id, module_id) VALUES ("..contract_id..", 'yxx', 'yxx_xqfx');";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_module (contract_id, product_id, module_id) VALUES ("..contract_id..", 'yxx', 'yxx_yx');";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_module (contract_id, product_id, module_id) VALUES ("..contract_id..", 'yxx', 'yxx_zt');";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_module (contract_id, product_id, module_id) VALUES ("..contract_id..", 'yxx', 'yxx_zuoy');";
table.insert(sqlTable, sql);

-- 插入合同中产品和科目之间的对应关系
local sql = "INSERT INTO t_crm_contract_subject_version (contract_id, product_id, stage_id,subject_id, scheme_id, is_visiable) VALUES ("..contract_id..", 'dzsb',-1, -1, 0, 1);";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_subject_version (contract_id, product_id, stage_id,subject_id, scheme_id, is_visiable) VALUES ("..contract_id..", 'eduoffice',-1, -1, 0, 1);";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_subject_version (contract_id, product_id, stage_id,subject_id, scheme_id, is_visiable) VALUES ("..contract_id..", 'kj',-1, -1, 0, 1);";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_subject_version (contract_id, product_id, stage_id,subject_id, scheme_id, is_visiable) VALUES ("..contract_id..", 'ptzj',-1, 2, 0, 1);";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_subject_version (contract_id, product_id, stage_id,subject_id, scheme_id, is_visiable) VALUES ("..contract_id..", 'teachpt',-1, -1, 0, 1);";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_subject_version (contract_id, product_id, stage_id,subject_id, scheme_id, is_visiable) VALUES ("..contract_id..", 'xnfzsys',-1, 8, 0, 1);";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_subject_version (contract_id, product_id, stage_id,subject_id, scheme_id, is_visiable) VALUES ("..contract_id..", 'xnfzsys',-1, 9, 0, 1);";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_subject_version (contract_id, product_id, stage_id,subject_id, scheme_id, is_visiable) VALUES ("..contract_id..", 'xnfzsys',-1, 15, 0, 1);";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_subject_version (contract_id, product_id, stage_id,subject_id, scheme_id, is_visiable) VALUES ("..contract_id..", 'xnfzsys',-1, 19, 0, 1);";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_subject_version (contract_id, product_id, stage_id,subject_id, scheme_id, is_visiable) VALUES ("..contract_id..", 'xnfzsys',-1, 20, 0, 1);";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_subject_version (contract_id, product_id, stage_id,subject_id, scheme_id, is_visiable) VALUES ("..contract_id..", 'xnfzsys',-1, 21, 0, 1);";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_subject_version (contract_id, product_id, stage_id,subject_id, scheme_id, is_visiable) VALUES ("..contract_id..", 'ybk',-1, -1, -1, 1);";
table.insert(sqlTable, sql);
local sql = "INSERT INTO t_crm_contract_subject_version (contract_id, product_id, stage_id,subject_id, scheme_id, is_visiable) VALUES ("..contract_id..", 'yxx',-1, -1, 0, 1);";
table.insert(sqlTable, sql);

if #sqlTable>0 then
    local boolResult = DBUtil: batchExecuteSqlInTx(sqlTable, #sqlTable);
    if boolResult then
        ngx.log(ngx.ERR, ">>>>>>>>>>>>>>> 批量更新[成功] <<<<<<<<<<<<<<<<<<<<");
    else
        ngx.log(ngx.ERR, ">>>>>>>>>>>>>>> 批量更新[失败] <<<<<<<<<<<<<<<<<<<<");
    end
end

local result = {}
result.success = true;
result.info = "新增合同成功！";
result.contract_id = contract_id;
ngx.print(cjson.encode(result));

