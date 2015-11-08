local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

local task_id = tostring(args["task_id"])
if task_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"task_id参数错误！\"}")
    return
end
local file_id = tostring(args["file_id"])
if file_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"file_id参数错误！\"}")
    return
end
local file_name = tostring(args["file_name"])
if file_name == "nil" then
    ngx.say("{\"success\":false,\"info\":\"file_name参数错误！\"}")
    return
end
local ext_name = tostring(args["ext_name"])
if ext_name == "nil" then
    ngx.say("{\"success\":false,\"info\":\"ext_name参数错误！\"}")
    return
end
local file_size = tostring(args["file_size"])
if file_size == "nil" then
    ngx.say("{\"success\":false,\"info\":\"file_size参数错误！\"}")
    return
end
local file_status = tostring(args["file_status"])
if file_status == "nil" then
    ngx.say("{\"success\":false,\"info\":\"file_status参数错误！\"}")
    return
end
local cjson = require "cjson";
--ngx.log(ngx.ERR, "**********客户端--保存微课上传状态开始**********");
local CacheUtil = require "common.SSDBUtil";	
local insTable = {}
insTable.task_id = task_id
insTable.file_id = file_id
insTable.file_name = file_name
insTable.ext_name = ext_name
insTable.file_size = file_size
insTable.file_status = file_status
local result = CacheUtil: multi_hset("client_wk_"..task_id.."_"..file_id,insTable)
local result ={}
result.success = true
result.info = "保存成功"
cjson.encode_empty_table_as_object(false)
ngx.log(ngx.ERR,cjson.encode(result))
ngx.print(cjson.encode(result))
--ngx.log(ngx.ERR, "**********客户端--保存微课上传状态开始**********");	