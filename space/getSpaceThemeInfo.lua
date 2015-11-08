--[[
读取主题、布局信息
@Author feiliming
@Date   2015-4-17
]]

local cjson = require "cjson"

local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--person_id
if not args["person_id"] or string.len(args["person_id"]) == 0 then
    ngx.say("{\"success\":\"false\",\"info\":\"person_id参数错误！\"}")
    return
end
local person_id = args["person_id"]

--identity_id
if not args["identity_id"] or string.len(args["identity_id"]) == 0 then
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

local json = cache:get("space_theme_info_"..person_id.."_"..identity_id)

local rr = {}
rr.success = false
if json and json[1] and string.len(json[1]) ~= 0 and json[1] ~= "not_found" then
	rr.success = true
	rr.theme_json = cjson.decode(json[1])
end

cache:set_keepalive(0,v_pool_size)
cjson.encode_empty_table_as_object(false)
ngx.say(cjson.encode(rr))
