--[[
记录区域均衡在新闻模块中的系统号
@Author  chenxg
@Date    2015-03-19
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"



--获得get请求参数
--local qyjh_id = ngx.var.arg_qyjh_id
local qyjh_id = ngx.var.arg_qyjh_id
--类型： 1：存储 2：获取
local page_type = ngx.var.arg_page_type
--类型： 1:公告 2:新闻
local news_type = ngx.var.arg_news_type


local regist_id = ngx.var.arg_regist_id

if not qyjh_id or string.len(qyjh_id) == 0 
	or not page_type or string.len(page_type) == 0 
	or not news_type or string.len(news_type) == 0 
then
    say("{\"success\":false,\"info\":\"qyjh_id or page_type or news_type 参数错误！\"}")
    return
end

--创建ssdb连接
local ssdblib = require "resty.ssdb"
local ssdb = ssdblib:new()
ssdb:set_timeout(3000) --不设置也可以, 默认2000
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
local returnjson = {}
returnjson.success=true

if page_type == "1" then -- 存储
	ssdb:hset("qyjh_news_registid", qyjh_id.."_"..news_type,regist_id)
else --获取注册号
	local hregistid = ssdb:hget("qyjh_news_registid", qyjh_id.."_"..news_type)
	if string.len(hregistid[1])>0 then
		returnjson.regist_id = hregistid[1]
	else
		returnjson.success=false
	end
end
--return
say(cjson.encode(returnjson))

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)