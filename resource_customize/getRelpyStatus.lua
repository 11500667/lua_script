#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#陈丽月 2015-02-04
#描述：设置资源定制自动回复
]]
local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--获取参数auto，并判断参数是否正确
if args["auto"] == nil or args["auto"] == "" then
    ngx.say("{\"success\":false,\"info\":\"auto参数错误！\"}")
    return
end

local auto = args["auto"]

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local status_info = ssdb_db:get("auto");
local relpy_status = status_info[1];
local result = {};
result.relpy_status=relpy_status;
result.success=true;
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size);
ngx.say(cjson.encode(result));

