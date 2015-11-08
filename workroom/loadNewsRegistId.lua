--[[
记录微课联盟注册号
@Author  feiliming
@Date    2015-04-07
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"

--获得get请求参数
local person_id = ngx.var.arg_person_id
local identity_id = ngx.var.arg_identity_id
local workroom_id = ngx.var.arg_workroom_id
--类型： 1：存储 2：获取
local page_type = ngx.var.arg_page_type
--类型： 1：教育科研   2：教学研究	
local news_type = ngx.var.arg_news_type

local regist_id = ngx.var.arg_regist_id

if not person_id or string.len(person_id) == 0 
	or not identity_id or string.len(identity_id) == 0 
	or not workroom_id or string.len(workroom_id) == 0 
	or not page_type or string.len(page_type) == 0 
	or not news_type or string.len(news_type) == 0 
then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

--创建ssdb连接
local ssdblib = require "resty.ssdb"
local ssdb = ssdblib:new()
ssdb:set_timeout(3000)
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local returnjson = {}
returnjson.success=true

if page_type == "1" then -- 存储
	ssdb:hset("workroom_news_registid", workroom_id.."_"..person_id.."_"..identity_id.."_"..news_type, regist_id)
else --获取注册号
	local hregistid = ssdb:hget("workroom_news_registid", workroom_id.."_"..person_id.."_"..identity_id.."_"..news_type)
	if string.len(hregistid[1]) > 0 and tonumber(hregistid[1]) ~= 0 then
		returnjson.regist_id = hregistid[1]
	else
		returnjson.success=false
	end
end
--return
say(cjson.encode(returnjson))

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)