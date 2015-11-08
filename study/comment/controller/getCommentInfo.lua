--
-- 学生点评 -> 获取用户（教师、学生）对指定对象的点评信息，如果没有点评过，返回默认的信息
-- 请求方式：GET
-- 作者: shenjian
-- 日期: 2015/5/5 14:27
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

if args["obj_type"] == nil or args["obj_type"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数obj_type不能为空！\"}");
    return;
elseif args["obj_id"] == nil or args["obj_id"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数obj_id不能为空！\"}");
    return;
elseif args["person_id"] == nil or args["person_id"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数person_id不能为空！\"}");
    return;
elseif args["identity_id"] == nil or args["identity_id"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数identity_id不能为空！\"}");
    return;
end


local objType    = tonumber(args["obj_type"]);
local objId      = tonumber(args["obj_id"]);
local personId   = tonumber(args["person_id"]);
local identityId = tonumber(args["identity_id"]);

local commentService = require "study.comment.services.CommentService";
local resultJsonObj  = commentService: getCommentInfo(objType, objId, personId, identityId);

local cjson = require "cjson";
ngx.print(cjson.encode(resultJsonObj));