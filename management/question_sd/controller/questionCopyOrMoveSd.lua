-- -----------------------------------------------------------------------------------
-- 描述：试题后台管理 -> 试题复制或移动
-- 作者：刘全锋
-- 日期：2015年8月26日
-- -----------------------------------------------------------------------------------


local request_method = ngx.var.request_method;
local cjson = require "cjson";


local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end


--连接redis服务器
local CacheUtil = require "common.CacheUtil";
local cache = CacheUtil: getRedisConn();


local structure_ids = tostring(args["structure_ids"])
--判断是否有显示类型参数
if structure_ids == "nil" or structure_ids == "" then
    ngx.say("{\"success\":false,\"info\":\"structure_ids参数错误！\"}")
    return
end


local version_id = tostring(args["version_id"])
--判断是否有显示类型参数
if version_id == "nil" or version_id == "" then
    ngx.say("{\"success\":false,\"info\":\"version_id参数错误！\"}")
    return
end



local question_ids = tostring(args["question_ids"])
--判断是否有显示类型参数
if question_ids == "nil" or question_ids == "" then
    ngx.say("{\"success\":false,\"info\":\"question_ids参数错误！\"}")    
    return
end

local op_type = tostring(args["op_type"])
--判断是复制操作还是移动操作
if op_type == "nil" or op_type == "" then
    ngx.say("{\"success\":false,\"info\":\"op_type参数错误！\"}")    
    return
end


question_ids = ngx.unescape_uri(question_ids);


local question_ids_table = cjson.decode(question_ids);


local questionModel = require "management.question_sd.model.QuestionModelSd";


local structure_ids_table = Split(structure_ids, ",");


local result = questionModel.questionCopyOrMove(version_id,structure_ids_table,question_ids_table,tonumber(op_type));


local returnjson={};
if not result then 
    returnjson.success = false;
    if op_type == 1 then
        returnjson.info = "试题复制失败！";
    else
        returnjson.info = "试题移动失败！";
    end
else
    returnjson.success = true;
    if op_type == 2 then
        returnjson.info = "试题复制成功！";
    else
        returnjson.info = "试题移动成功！";
    end
end



--放回连接池
cache:set_keepalive(0,v_pool_size);

ngx.say(encodeJson(returnjson));

