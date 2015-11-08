--[[
空间中保存个性签名
@Author chuzheng
@Date 2015-02-09
--]]

local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)

--判断是否有person_id的cookie信息
if cookie_person_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"cookie_person_id参数错误！\"}")
    return
end
--判断是否有identity_id的cookie信息
if cookie_identity_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"cookie_identity_id参数错误！\"}")
    return
end

--连接ssdb服务器
local ssdb = require "resty.ssdb"
local cache = ssdb:new()
local ok,err = cache:connect(v_ssdb_ip,v_ssdb_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--签名
local signature = tostring(args["signature"])
if signature == "nil" then
    ngx.say("{\"success\":false,\"info\":\"signature参数错误！\"}")
    return
end
--ngx.encode_base64(signature)
cache:set("space_signature_"..cookie_person_id.."_"..cookie_identity_id,signature)

--redis放回连接池
cache:set_keepalive(0,v_pool_size)

ngx.say("{\"success\":true}")

