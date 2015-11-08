--[[
根据资源类型[资源、试卷、备课、微课]获取发布到区域均衡栏目下的资源
@Author  chenxg
@Date    2015-03-08
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
cjson.encode_empty_table_as_object(false);

--判断request类型, 获得请求参数
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
local pageSize = args["pageSize"]

--判断参数是否为空
if not person_id or string.len(person_id) == 0 
	or not pageSize or string.len(pageSize) == 0 
	then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

pageSize = tonumber(pageSize)
local returnjson = {}
--参数

--1：培训学习，2：专家讲座，3：集体备课，4：教学观摩，5：交流研讨
local pxxxhdlist
local zjjzhdlist
local jxgmhdlist
local jtbkhdlist
local jlythdlist

local pxxxparams = "?page_type=5&hd_type=1&pageSize="..pageSize.."&pageNumber=1&Scope=-1&person_id="..person_id
local zjjzparams = "?page_type=5&hd_type=2&pageSize="..pageSize.."&pageNumber=1&Scope=-1&person_id="..person_id
local jxgmparams = "?page_type=5&hd_type=4&pageSize="..pageSize.."&pageNumber=1&Scope=-1&person_id="..person_id
local jlytparams = "?page_type=5&hd_type=5&pageSize="..pageSize.."&pageNumber=1&Scope=-1&person_id="..person_id
local jtbkparams = "?page_type=5&hd_type=3&pageSize="..pageSize.."&pageNumber=1&Scope=-1&person_id="..person_id

local res_pxxx = ngx.location.capture("/dsideal_yy/qyjhfz/getHdByParams"..pxxxparams)
local res_zjjz = ngx.location.capture("/dsideal_yy/qyjhfz/getHdByParams"..zjjzparams)
local res_jxgm = ngx.location.capture("/dsideal_yy/qyjhfz/getHdByParams"..jxgmparams)
local res_jlyt = ngx.location.capture("/dsideal_yy/qyjhfz/getHdByParams"..jlytparams)
local res_jtbk = ngx.location.capture("/dsideal_yy/qyjhfz/getHdByParams"..jtbkparams)

if res_pxxx.status == 200 then
	pxxxhdlist = (cjson.decode(res_pxxx.body))
else
	say("{\"success\":false,\"info\":\"获取活动信息失败！\"}")
	return
end
if res_zjjz.status == 200 then
	zjjzhdlist = (cjson.decode(res_zjjz.body))
else
	say("{\"success\":false,\"info\":\"获取活动信息失败！\"}")
	return
end
if res_jxgm.status == 200 then
	jxgmhdlist = (cjson.decode(res_jxgm.body))
else
	say("{\"success\":false,\"info\":\"获取活动信息失败！\"}")
	return
end
if res_jtbk.status == 200 then
	jtbkhdlist = (cjson.decode(res_jtbk.body))
else
	say("{\"success\":false,\"info\":\"获取活动信息失败！\"}")
	return
end
if res_jlyt.status == 200 then
	jlythdlist = (cjson.decode(res_jlyt.body))
else
	say("{\"success\":false,\"info\":\"获取活动信息失败！\"}")
	return
end
returnjson.pxxxhdlist = pxxxhdlist.hd_list
returnjson.zjjzhdlist = zjjzhdlist.hd_list
returnjson.jxgmhdlist = jxgmhdlist.hd_list
returnjson.jtbkhdlist = jtbkhdlist.hd_list
returnjson.jlythdlist = jlythdlist.hd_list

--创建ssdb连接
local ssdblib = require "resty.ssdb"
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--连接mysql数据库
local mysql = require "resty.mysql"
local mysql_db = mysql:new()
mysql_db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024*1024
}
--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--加码
--[[function encodeURI(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end]]
--UFT_CODE
local function urlEncode(str)
    if (str) then
        str = string.gsub (str, "\n", "\r\n")
        str = string.gsub (str, "([^%w ])",
        function (c) return string.format ("%%%%%02X", string.byte(c)) end)
    end
    return str
end


--**************************
returnjson.resource_hot_tab = resource_hot_tab
returnjson.success = "true"
returnjson.pageNumber = pageNumber
returnjson.pageSize = pageSize

say(cjson.encode(returnjson))

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
mysql_db:set_keepalive(0,v_pool_size)