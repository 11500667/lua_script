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

local cjson = require "cjson";

function split(s, delim)
  if type(delim) ~= "string" or string.len(delim) <= 0 then
    return
  end
  local start = 1
  local t = {}
  while true do
    local pos = string.find (s, delim, start, true) -- plain find
    if not pos then
      break
    end
    table.insert (t, string.sub (s, start, pos - 1))
    start = pos + string.len (delim)
  end
  table.insert (t, string.sub (s, start))
  return t
end

--ngx.log(ngx.ERR, "**********客户端--获取微课上传状态开始**********");	
local CacheUtil = require "common.SSDBUtil";	
local result = CacheUtil: multi_hget_hash("client_task_"..task_id,"file_ids")
if result.file_ids == nil then
  ngx.say("{\"success\":false,\"info\":\"任务不存在，请确认后重试！\"}")
  return
end
local task_list = {}
local file_ids = split(result.file_ids,",")
for i=1,#file_ids do
	-- 0 未开始， 1：开始 2： 完成 3：此任务文件取消
	local file_id = file_ids[i]
	--ngx.log(ngx.ERR,file_id)
	local result_file = CacheUtil: multi_hget_hash("client_wk_"..task_id.."_"..file_id,"file_id","file_name","ext_name","file_size","file_status")
	local status = result_file.file_status
	--ngx.log(ngx.ERR,status)
	if status == nil then
		ngx.say("{\"success\":true,\"flag\":1,\"info\":\"上传任务未完成，请确认后重试！\"}")
		return
	end
	if tonumber(status) == 0 or tonumber(status) == 1 then 
		ngx.say("{\"success\":true,\"flag\":1,\"info\":\"上传任务未完成，请确认后重试！\"}")
		return
	end
	task_list[i] = result_file
end

local returnResult = {}
returnResult.task_id = task_id
returnResult.task_list = task_list
returnResult.flag = 2
returnResult.success = true
returnResult.info = "获取成功"
cjson.encode_empty_table_as_object(false)
--ngx.log(ngx.ERR,cjson.encode(returnResult))
ngx.print(cjson.encode(returnResult))
--ngx.log(ngx.ERR, "**********客户端--获取微课上传状态结束**********");	