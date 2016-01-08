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

local contact_address 	= args["contact_address"];

if contact_address == nil  then
    contact_address = ""
end


local bureau_type 	= args["bureau_type"];

if bureau_type == nil or bureau_type == "" then
    local return_info = "{\"success\":false,\"info\":\"缺少参数bureau_type\"}";
    ngx.say(return_info);
    return;
end


local edu_type 	= args["edu_type"];

if edu_type == nil or edu_type == "" then
    local return_info = "{\"success\":false,\"info\":\"缺少参数edu_type\"}";
    ngx.say(return_info);
    return;
end



-- 向客户表中插入数据
local sql = "INSERT INTO t_crm_customer (customer_id, customer_name, contact_address, bureau_type, edu_type) VALUES ("..customer_id..", "..quote(customer_name)..", "..quote(contact_address)..", "..bureau_type..", "..edu_type..")";

log.debug(" sql==>"..sql.."<==");

local res = DBUtil:querySingleSql(sql);
if not res then
    return false;
end

local result = {}
result.success = true;
result.info = "CRM新增机构成功！";
ngx.print(cjson.encode(result));

