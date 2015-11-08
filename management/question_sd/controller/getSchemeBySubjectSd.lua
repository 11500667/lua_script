-- -----------------------------------------------------------------------------------
-- 描述：试题后台管理 -> 查询版本
-- 作者：刘全锋
-- 日期：2015年8月26日
-- -----------------------------------------------------------------------------------


local request_method = ngx.var.request_method
local DBUtil   = require "common.DBUtil";
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end



--科目
local subject_id = tostring(args["subject_id"])
if subject_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"subject_id参数错误！\"}")
    return
end


--连接redis服务器
local CacheUtil = require "common.CacheUtil";
local cache = CacheUtil: getRedisConn();


--生成一个临时的有序集合key
local temp_key = ngx.time()..tostring(ngx.now()*1000)

local result = ""


--参数说明 学科 试题 web version_id固定1
local product_key = subject_id..211
product_key = ngx.md5(product_key);


--根据科目ID和系统ID平台id版本类型id获得产品id
local product_id = cache:get("product_"..product_key)


if product_id == ngx.null then 
        ngx.say("{\"success\":false,\"info\":\"没有找到该产品\"}")
   return
end

local questionModel = require "management.question.model.QuestionModel";


local result,returnjson = questionModel.querySchemeByProduct(product_id,false);


if not result then 
    local returnjson={};
    returnjson.success = false;
    returnjson.info = "获取版本信息失败！";
end



--放回连接池
cache:set_keepalive(0,v_pool_size);

ngx.say(encodeJson(returnjson));


