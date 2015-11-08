--
-- 学情分析 -> 获取指定科目下是否包含知识点结构，如果有，则返回根节点
-- 请求方式：GET
-- 作者: shenjian
-- 日期: 2015/5/8
--

-- 1.获取参数
local request_method = ngx.var.request_method;
local args;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["subject_id"] == nil or args["subject_id"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数subject_id不能为空！\"}");
    return;
end

local subjectId   = tonumber(args["subject_id"]);

local structureService = require "base.structure.services.StructureService";
local resultJsonObj    = structureService: getKnowledgeBySubject(subjectId);
local cjson            = require "cjson";
ngx.print(cjson.encode(resultJsonObj));