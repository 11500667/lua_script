#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-08-19
#描述：获得当前备课包的资源个数
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

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

 --连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--传参数
if args["obj_id_int"] == nil or args["obj_id_int"] == "" then
    ngx.say("{\"success\":false,\"info\":\"obj_id_int参数错误！\"}")
    return
end
local obj_id_int  = tostring(args["obj_id_int"]);

local res_list = cache:hgetall("pack_list_".. obj_id_int)
ngx.log(ngx.ERR,"1111111111111"..#res_list)
local complete_total = #res_list/2;
local upload_info = ssdb_db:get("upload_bk_"..obj_id_int);
local upload_info_list = Split(upload_info[1],",");

local total_count;
if #upload_info[1] == 0 then
    total_count= 0;
else
    total_count= #upload_info_list;
end

local cjson = require 'cjson';
local resultJson={};
resultJson.upload_total_count = total_count;
resultJson.complete_total_count = complete_total;
resultJson.total_count = total_count+complete_total;
resultJson.success = true;

local responseJson = cjson.encode(resultJson);
--redis放回连接池
cache:set_keepalive(0,v_pool_size)

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)
ngx.say(responseJson);
