#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#申健  2015-06-01
#描述：判断对象是否允许修改名称
]]

-- 1.获取参数
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["obj_type"] == nil or args["obj_type"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数obj_type不能为空！\"}");
    return;
elseif args["obj_id_int"] == nil or args["obj_id_int"]=="" then
    ngx.print("{\"success\":false,\"info\":\"参数obj_id_int不能为空！\"}");
    return;
end

local objType  = args["obj_type"];
local objIdInt = args["obj_id_int"];

local checkInfoModel = require "multi_check.model.CheckInfo";
local pathBean  = checkInfoModel: getCheckPath(objType, objIdInt);

local canRename = true;
if pathBean ~= nil then
    local checkPathStr = pathBean: getCheckPath();
    -- ngx.log(ngx.ERR, "[sj_log] -> [check_info] -> 循环级别： checkPathStr:[", checkPathStr, "]");
    for level = 4, 1, -1 do

        local status = pathBean: getCheckStatusByLevel(level);
        -- ngx.log(ngx.ERR, "[sj_log] -> [check_info] -> 循环级别： level:[", level, "], status : [" , status, "]");
        if status == "10" or status == "11" then
            canRename = false;
            level = 0;
        end
    end
end

local cjson    = require "cjson";
--ngx.log(ngx.ERR, "[sj_log] -> [share_auth] -> 参数 -> param_json:[", paramJson, "]");

local resultTable      = {};
resultTable.success    = true;
resultTable.can_rename = canRename;

ngx.print(cjson.encode(resultTable));