--[[
根据活动ID进入活动[mysql版]
@Author  chenxg
@Date    2015-06-04
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local returnjson={}

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
local hd_id = args["hd_id"]
local person_id = args["person_id"]
local pwd = args["pwd"]


--判断参数是否为空
if not hd_id or string.len(hd_id) == 0 
	or not person_id or string.len(person_id) == 0 
	or not pwd or string.len(pwd) == 0 
   then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

--连接mysql数据库
local mysql = require "resty.mysql"
local db = mysql:new()
db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024*1024
}
-- 获取redis链接
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
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
--获取详细信息
local t = {}
local querySql = "select start_time as start_date,end_time as end_date,hd_confid,con_pass from t_qyjh_hd where hd_id = "..hd_id
local result, err, errno, sqlstate = db:query(querySql);
if not result then
	ngx.say("{\"success\":false,\"info\":\"查询协作体数据失败！\"}");
	return;
end

t.hd_confid = result[1]["hd_confid"]
t.start_date = result[1]["start_date"]
t.end_date = result[1]["end_date"]
t.con_pass=result[1]["con_pass"]

local page_type = t.page_type
local hd_confid = t.hd_confid

local ts = os.date("%Y%m%d%H%M")
local sdate = t.start_date
local edate = t.end_date
local stonum = string.gsub(string.gsub(string.gsub(sdate,"-",""),":","")," ","")
local etonum = string.gsub(string.gsub(string.gsub(edate,"-",""),":","")," ","")
if etonum < ts then
	returnjson.success = false
	returnjson.info = "活动已经结束，不可以进入！"
    --return
else
	local cookie_identity_id = tostring(ngx.var.cookie_identity_id)
	local show_name = cache:hget("person_"..person_id.."_"..cookie_identity_id,"person_name")
	
	--进入活动
	local res_hd, err = ngx.location.capture("/joinHDForGBT", {
		args = {hd_confid = hd_confid,show_name = show_name,con_pass = pwd}
	})
	if res_hd.status == 200 then
		local conf = Split(res_hd.body,"***")[1]
		local url = Split(res_hd.body,"***")[2]
		returnjson.success = true
		returnjson.conf = conf
		returnjson.url = url
	else
		returnjson.success = false
		returnjson.info = "连接高百特进入活动失败！"
		--return	
	end
	
end

say(cjson.encode(returnjson))

-- 将redis连接归还到连接池
cache:set_keepalive(0, v_pool_size)
--mysql放回连接池
db:set_keepalive(0, v_pool_size)

