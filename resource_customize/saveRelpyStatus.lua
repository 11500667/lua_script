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


--获取参数relpy_status，并判断参数是否正确
if args["relpy_status"] == nil or args["relpy_status"] == "" then
    ngx.say("{\"success\":false,\"info\":\"relpy_status参数错误！\"}")
    return
end

local relpy_status = args["relpy_status"]

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local ssdb_key="auto";
local res, err = ssdb_db:set(ssdb_key,relpy_status);
if not res then 
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end


--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size);

ngx.say("{\"success\":true,\"info\":\"配置项上传成功relpy_status\"}")