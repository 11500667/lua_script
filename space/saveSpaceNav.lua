--[[   
    保存空间菜单的json数据.
    @Author zhanghai
    @Date   2015-4-14
--]]
--ngx.header.content_type = "text/plain;charset=utf-8"
local say = ngx.say
local len = string.len

--require model
local ssdb = require "resty.ssdb"
local cjson = require "cjson"
local cache = ssdb:new()
local ok,err = cache:connect(v_ssdb_ip,v_ssdb_port)
if not ok then
    say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end
--get args
local request_method = ngx.var.request_method
local args,err
if request_method == "GET" then
    args,err = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args,err = ngx.req.get_post_args()
end

local space_type = args["space_type"]
local person_id = args["person_id"]
local identity_id = args["identity_id"]
ngx.log(ngx.ERR,"space_type key is "..space_type)
ngx.log(ngx.ERR,"person_id key is "..person_id)
ngx.log(ngx.ERR,"identity_id key is "..identity_id)

--json串
local json = args["json"]
if not space_type or len(space_type) == 0 or
    not person_id or len(person_id) == 0 or
    not identity_id or len(identity_id) == 0 or
    not json or len(json) == 0 then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

local ssdb_space_nav_key = "space_nav_"..space_type.."_"..person_id.."_"..identity_id
--local jsonObj = cjson.decode(json)
local ok,err = cache:set(ssdb_space_nav_key,json)
if not ok then
    say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end
local rr = {}
rr.success = true
rr.info = "成功"
ngx.log(ngx.ERR,"key:"..ssdb_space_nav_key)
ssdb:set_keepalive(0,v_pool_size)
cjson.encode_empty_table_as_object(false)
say(cjson.encode(rr))
