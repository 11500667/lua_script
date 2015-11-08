#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-4-1
#描述：保存学校的管理员(统一认证调用)
]]
local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--获取参数school_id，并判断参数是否正确
if args["school_id"] == nil or args["school_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"school_id参数错误！\"}")
    return
end

local school_id = args["school_id"]

--获取参数person_id，并判断参数是否正确
if args["person_id"] == nil or args["person_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
    return
end

local person_id = args["person_id"]


--获取参数identity_id，并判断参数是否正确
if args["identity_id"] == nil or args["identity_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"identity_id参数错误！\"}")
    return
end

local identity_id = args["identity_id"]

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local ssdb_key_person="school_admin_person_"..person_id.."_"..identity_id;

local res, err = ssdb_db:set(ssdb_key_person,school_id);
if not res then 
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size);

ngx.say("{\"success\":true,\"info\":\"保存管理员数据成功\"}")