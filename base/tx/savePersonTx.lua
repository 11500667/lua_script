#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#陈丽月 2015-01-30
#描述：保存用户所有头像的数据
]]

local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

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

--获取参数tx_json，并判断参数是否正确
if args["tx_json"] == nil or args["tx_json"] == "" then
    ngx.say("{\"success\":false,\"info\":\"tx_json参数错误！\"}")
    return
end

local tx_json = args["tx_json"]

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local ssdb_key="tx_"..person_id.."_"..identity_id;
--ngx.say("ssdb_key"..ssdb_key.."tx_json"..tx_json);
ssdb_db:set(ssdb_key,tx_json);
--local value = ssdb_db:get(ssdb_key);
--ngx.say("tx_json"..value[1]);
--ngx.say("ssdb_key_value"..ssdb_db.get(ssdb_key));
--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size);

ngx.say("{\"success\":true,\"info\":\"头像上传成功！\"}")


