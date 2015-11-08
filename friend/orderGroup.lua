--[[
分组排序
@Author feiliming
@Date   2015-7-24
]]

local say = ngx.say
local len = string.len
local quote = ngx.quote_sql_str

--require model
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

--get args
local request_method = ngx.var.request_method
local args,err
if request_method == "GET" then
    args,err = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args,err = ngx.req.get_post_args()
end
if not args then 
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local person_id = args["person_id"]
local identity_id = args["identity_id"]
local group = args["group"]
if not person_id or len(person_id) == 0 or
    not identity_id or len(identity_id) == 0 or 
    not group or len(group) == 0 then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

--ssdb
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local group_t = cjson.decode(group) or {}
for _,v in pairs(group_t) do
    local group_id = v.group_id
    local sequence = v.sequence
    ssdb:hset("social_friend_group_"..group_id, "sequence", sequence)
    ssdb:zset("social_friend_group_sorted_"..identity_id.."_"..person_id, group_id, sequence)
end

--return
local rr = {}
rr.success = true

cjson.encode_empty_table_as_object(false)
say(cjson.encode(rr))

--release
ssdb:set_keepalive(0,v_pool_size)
