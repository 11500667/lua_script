local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

local file_ids = tostring(args["file_ids"])
if file_ids == "nil" then
    ngx.say("{\"success\":false,\"info\":\"file_ids参数错误！\"}")
    return
end
local task_id = tostring(args["task_id"])
if task_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"task_id参数错误！\"}")
    return
end
local cjson = require "cjson";
--ngx.log(ngx.ERR, "**********客户端--保存微课上传状态开始**********");
local CacheUtil = require "common.SSDBUtil";	
local insTable = {}
insTable.file_ids = file_ids
local result = CacheUtil: multi_hset("client_task_"..task_id,insTable)
local returnResult ={}
returnResult.success = true
returnResult.info = "保存成功"
cjson.encode_empty_table_as_object(false)
ngx.log(ngx.ERR,cjson.encode(returnResult))
ngx.print(cjson.encode(returnResult))
--ngx.log(ngx.ERR, "**********客户端--保存微课上传状态开始**********");	