#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-01-30
#描述：获得用户在当前业务模块中使用的头像
]]
--1.获得参数方法
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end
 local myts = require "resty.TS";
 
 --获得参数
 
 --获得person_id
if args["person_id"] == nil or args["person_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
    return
end
local person_id = args["person_id"];

 --获得identity_id
if args["identity_id"] == nil or args["identity_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"identity_id参数错误！\"}")
    return
end
local identity_id = args["identity_id"];

 --获得yw
if args["yw"] == nil or args["yw"] == "" then
    ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
    return
end
local yw = args["yw"];

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local tx_info = ssdb_db:multi_hget( yw.."_"..person_id.."_"..identity_id,"extension","file_id")
local res =  {}
if tx_info[2] == nil then
    res.extension = "jpg";
else
    res.extension = tx_info[2];
end

if tx_info[4] == nil then
    res.file_id = "0D7B3741-0C3D-D93C-BA3D-74668271F934";
else
    res.file_id = tx_info[4];
end


res.success = true;

local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);


--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)


ngx.say(cjson.encode(res));







