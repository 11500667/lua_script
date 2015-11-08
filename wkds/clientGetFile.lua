local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

local file_id = tostring(args["file_id"])
if file_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"file_id参数错误！\"}")
    return
end

local cjson = require "cjson";
--ngx.log(ngx.ERR, "**********客户端--获取微课上传状态开始**********");	
local CacheUtil = require "common.SSDBUtil";	
local result = CacheUtil: multi_hget_hash("client_wk_"..file_id,"file_id","file_name","ext_name","file_size","task_status")
if result[1] == nil then
  ngx.say("{\"success\":false,\"info\":\"获取失败！\"}")
  return
end
result.success = true
result.info = "获取成功"
cjson.encode_empty_table_as_object(false)
ngx.log(ngx.ERR,cjson.encode(result))
ngx.print(cjson.encode(result))
--ngx.log(ngx.ERR, "**********客户端--获取微课上传状态结束**********");	