#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#陈丽月 2015-02-04
#描述：获取学校所有风光
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

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local fg_info = ssdb_db:get("sch_fg_"..school_id);
local fg_json = fg_info[1];

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size);

if #fg_json == 0 then
ngx.say("{\"success\":true,\"list\":\""..fg_json.."\"}")
else
ngx.say("{\"success\":true,\"list\":\""..fg_json.."\"}")
end
