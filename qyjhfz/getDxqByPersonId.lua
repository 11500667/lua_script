--[[
根据当前用户ID获取用户所管理的和所属于的大学区列表
@Author  chenxg
@Date    2015-01-21
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"
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
--参数 
local qyjh_id = args["qyjh_id"]
local person_id = args["person_id"]

--判断参数是否为空
if not person_id or string.len(person_id) == 0
   then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

--创建ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--获取用户管理的大学区
local dqxs, err = ssdb:hget("qyjh_manager_dxqs", person_id)
if not dqxs then
   say("{\"success\":false,\"info\":\""..err.."\"}")
   return
end

--获取用户所属于的大学区开始
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)
-- 获取redis链接
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end
local schID = cache:hget("person_"..person_id.."_"..cookie_identity_id,"xiao")
-- 将redis连接归还到连接池
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
	ngx.log(ngx.ERR, "====>将Redis连接归还连接池出错！");
end

local owndqxs, err = ssdb:hget("qyjh_org_dxq", schID)
if not owndqxs then
   say("{\"success\":false,\"info\":\""..err.."\"}")
   return
end
local res = ""
if owndqxs[1] or string.len(owndqxs[1])>=2 then
	ngx.log(ngx.ERR, "owndqxs====>"..owndqxs[1].."<====owndqxs**dqxs===>"..dqxs[1].."<===dqxs****");
	if string.find(owndqxs[1],dqxs[1]) ~= nil then
		--ngx.log(ngx.ERR, "owndqxs====>"..owndqxs[1].."<====owndqxs**dqxs===>"..dqxs[1].."<===dqxs****");
		res = Split(owndqxs[1],",")
	else
		res = Split(dqxs[1]..owndqxs[1],",")
	end
else
	res = Split(dqxs[1],",")
end
	


--根据分隔符分割字符串
function Split(str, delim, maxNb)
	-- Eliminate bad cases...   
	if string.find(str, delim) == nil then  
		return { str }  
	end  
	if maxNb == nil or maxNb < 1 then  
		maxNb = 0    -- No limit   
	end  
	local result = {}  
	local pat = "(.-)" .. delim .. "()"   
	local nb = 0  
	local lastPos   
	for part, pos in string.gfind(str, pat) do  
		nb = nb + 1  
		result[nb] = part   
		lastPos = pos   
		if nb == maxNb then break end  
	end  
	-- Handle the last field   
	if nb ~= maxNb then  
		result[nb + 1] = string.sub(str, lastPos)   
	end  
	return result   
end  
local tids = {}
for i=1,#res,1 do
	table.insert(tids, res[i])
end

--获取大学区下的教师ID列表开始
local list1 = {}
--大学区列表
local dxqlist, err = ssdb:multi_hget('qyjh_dxq',unpack(tids));
for i=2,#dxqlist,2 do
	--say(cjson.decode(dxqlist[i]).person_id)
	if cjson.decode(dxqlist[i]).b_delete ~="1" and cjson.decode(dxqlist[i]).qyjh_id == qyjh_id then
		local t = cjson.decode(dxqlist[i])
		list1[#list1+1] = t
	end
	
	
end

--获取大学区下的教师ID列表结束
local returnjson = {}
returnjson.list = list1
returnjson.success = "true"
say(cjson.encode(returnjson))

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
