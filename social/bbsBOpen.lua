--[[
判断论坛是否开通
@Author feiliming
@Date   2015-3-21
]]

local say = ngx.say
local len = string.len

--require model
local cjson = require "cjson"
local mysqllib = require "resty.mysql"

--get args
local region_id = ngx.var.arg_region_id
local social_type = ngx.var.arg_social_type

if not region_id or len(region_id) == 0 or
	not social_type or len(social_type) ==0 then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

--mysql
local mysql, err = mysqllib:new()
if not mysql then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
local ok, err = mysql:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024 * 1024 }
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--从mysql判断
local ssql = "select id,region_id,name,logo_url,icon_url,domain,status,social_type from t_social_bbs where region_id = "..region_id.." and social_type = "..social_type
local sresult, err = mysql:query(ssql)
if not sresult then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local bopen = false
local status = false
--opened
if sresult and #sresult > 0 then
	bopen = true
	if sresult[1].status == 0 then
		status = true
	end

	local rr = {}
	rr.success = true
	rr.bopen = bopen
	rr.status = status
	rr.bbs = sresult[1]
	cjson.encode_empty_table_as_object(false)
	say(cjson.encode(rr))
else
	local rr = {}
	rr.success = true
	rr.bopen = bopen
	rr.status = status
	say(cjson.encode(rr))
end

--release
--ssdb:set_keepalive(0,v_pool_size)
mysql:set_keepalive(0,v_pool_size)