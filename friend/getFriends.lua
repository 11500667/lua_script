--[[
不分组获取好友，不登录也可以访问
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

--get friend
local pim = require "base.person.model.PersonInfoModel"
local friends = {}
local pit = {}
local z0 = ssdb:zrange("social_friend_sorted_"..identity_id.."_"..person_id, 0, 10000) 
if z0 and #z0 > 0 and z0[1] ~= "ok" and z0[1] ~= "not_found" then
    for i=1, #z0, 2 do
        local friend_id = z0[i]
        local t0 = ssdb:multi_hget("social_friend_"..friend_id, "fperson_id", "fidentity_id", "apply_time")
        if t0 and #t0 > 0 and t0[1] ~= "ok" and t0[1] ~= "not_found" then
            local friend = {}
            friend.friend_id = friend_id
            --friend.group_id = group_id
            friend.fperson_id = t0[2]

            local pi = {}
            pi.person_id = t0[2]
            pi.identity_id = t0[4]
            table.insert(pit, pi)

            local fperson_t = pim:getPersonDetail(t0[2], t0[4])
            friend.fperson_name = fperson_t.person_name
            friend.fidentity_id = t0[4]
            friend.apply_time = t0[6]

            friends[#friends + 1] = friend
        end
    end
end

--查询关注情况
local attentionService = require "space.attention.service.AttentionService"
local param = {}
param.personid = person_id
param.identityid = identity_id
param.page_size = 100000
param.page_num = 1
--ngx.log(ngx.ERR,cjson.encode(param))
local at = attentionService.queryAttention(param)
for i=1,#friends do
    friends[i].attention = 0
    for _, v in ipairs(at) do
        if tostring(friends[i].fperson_id) == tostring(v.personId) then
            friends[i].attention = 1
            break
        end
    end
end

--获取头像信息
local aService = require "space.services.PersonAndOrgBaseInfoService"
local rt = aService:getPersonBaseInfoByPersonIdAndIdentityId(pit)
for i=1,#friends do
    for _, v in ipairs(rt) do
        if tostring(friends[i].fperson_id) == tostring(v.personId) then
            friends[i].avatar_fileid = v and v.avatar_fileid or ""
            friends[i].person_name = v and v.person_name or ""
            --teacherlist[i].description = v and v.person_description or ""
            break
        end
    end
end

--return
local rr = {}
rr.success = true
rr.friends = friends

cjson.encode_empty_table_as_object(false)
say(cjson.encode(rr))

--release
ssdb:set_keepalive(0,v_pool_size)