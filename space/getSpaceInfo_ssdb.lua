local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--person_id
if args["person_id"] == nil or args["person_id"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"person_id参数错误！\"}")
    return
end
local person_id = args["person_id"]

--identity_id
if args["identity_id"] == nil or args["identity_id"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"identity_id参数错误！\"}")
    return
end
local identity_id = args["identity_id"]


--连接ssdb服务器
local ssdb = require "resty.ssdb"
local cache = ssdb:new()
local ok,err = cache:connect(v_ssdb_ip,v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local json = cache:get("space_info_"..person_id.."_"..identity_id)

--ssdb放回连接池
cache:set_keepalive(0,v_pool_size)
ngx.say(json)
