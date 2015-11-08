-- -----------------------------------------------------------------------------------
-- 描述：试题后台管理 -> 根据product_id查询版本
-- 作者：刘全锋
-- 日期：2015年8月27日
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


--产品id
local product_id = tostring(args["product_id"])
if product_id == "nil" or product_id == "" then
    ngx.say("{\"success\":false,\"info\":\"product_id参数错误！\"}")
    return
end


--是否包含知识点
local zsd = tostring(args["zsd"])
if zsd == "nil" or zsd == "" then
    ngx.say("{\"success\":false,\"info\":\"zsd参数错误！\"}");
    return
end

local questionModel = require "management.question_sd.model.QuestionModelSd";


local result,returnjson = questionModel.querySchemeByProduct(product_id,zsd);


if not result then 
    local returnjson={};
    returnjson.success = false;
    returnjson.info = "获取版本信息失败！";
end

ngx.say(encodeJson(returnjson));


