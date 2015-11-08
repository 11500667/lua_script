--[[
读取好友申请消息
@Author feiliming
@Date   2015-4-2
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
if not person_id or len(person_id) == 0 or
	not identity_id or len(identity_id) == 0 then
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

--当前用户被申请
local pim = require "base.person.model.PersonInfoModel"
local applys = {}
local z0 = ssdb:zrrange("social_friend_apply_sorted_"..identity_id.."_"..person_id, 0, 10000)
if z0 and #z0 > 0 and z0[1] ~= "ok" and z0[1] ~= "not_found" then
    for i=1, #z0, 2 do
        local apply_id = z0[i]
        local t0 = ssdb:multi_hget("social_friend_apply_"..apply_id, "person_id", "identity_id", "apply_time")
        if t0 and #t0 > 0 and t0[1] ~= "ok" and t0[1] ~= "not_found" then
            local apply = {}
            apply.apply_id = apply_id
            apply.person_id = t0[2]
            apply.identity_id = t0[4]
            local person_t = pim:getPersonDetail(t0[2], t0[4])
            apply.person_name = person_t.person_name
            apply.fperson_id = person_id
            apply.fidentity_id = identity_id
            apply.apply_time = t0[6]

            applys[#applys + 1] = apply
        end
    end
end

--return
local rr = {}
rr.success = true
rr.applys = applys

cjson.encode_empty_table_as_object(false)
say(cjson.encode(rr))

--release
ssdb:set_keepalive(0,v_pool_size)