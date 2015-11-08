--[[
保存一个json串，a_type=表示保存的是什么，不要重复
@Author feiliming
@Date   2015-4-21
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

local a_id = args["a_id"]
local a_identity_id = args["a_identity_id"]
local a_type = args["a_type"]
if not a_id or len(a_id) == 0 or
	not a_identity_id or len(a_identity_id) == 0 or
	not a_type or len(a_type) == 0 then
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

local ok, err = ssdb:get("space_ajson_"..a_type.."_"..a_id.."_"..a_identity_id)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local rr = {}
rr.success = false
if ok and ok[1] and string.len(ok[1]) ~= 0 and ok[1] ~= "not_found" then
    ngx.log(ngx.ERR,"============"..ok[1])
    rr.success = true
    rr.a_json = cjson.decode(ok[1])
end

ssdb:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false)
say(cjson.encode(rr))



