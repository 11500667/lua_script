--ngx.say(ngx.localtime())
--ngx.say(ngx.utctime())

local cjson = require "cjson"
--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
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

local uuid = require "resty.uuid"

--ssdb_db:set("network",uuid.new())
ssdb_db:set("network",args["flow"])
