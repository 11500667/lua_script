--[[
维护协作体和教师的对应关系
@Author  chenxg
@Date    2015-01-23
--]]

local say = ngx.say
local quote = ngx.quote_sql_str

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

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
local xzt_id = args["xzt_id"]
local org_id = args["org_id"]
	--操作：1单个选中,2单个取消
local operationtype = args["operationtype"]
local person_id = args["person_id"]

--判断参数是否为空
if not xzt_id or string.len(xzt_id) == 0  
  or not org_id or string.len(org_id) == 0  
  or not operationtype or string.len(operationtype) == 0 
  or not person_id or string.len(person_id) == 0 
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

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
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

--获取协作体下的全部教师开始
local hallteaids = ssdb:hget("qyjh_xzt_teas",xzt_id)
local allteaids = hallteaids[1]

if not allteaids or string.len(allteaids) == 0 then
	allteaids =","
end
--获取协作体下的全部教师结束
--获取协作体某个学校下的教师列表开始
local horgteaids = ssdb:hget("qyjh_xzt_org_teas",xzt_id.."_"..org_id)
local orgteaids = horgteaids[1]

if not orgteaids or string.len(orgteaids) == 0 then
	orgteaids =","
end
--获取协作体某个学校下的教师列表结束
local xzt = ssdb:hget("qyjh_xzt",xzt_id)
local temp = cjson.decode(xzt[1])
local dxq_id = temp.dxq_id
local qyjh_id = temp.qyjh_id

--获取当前教师所属的协作体开始
local hxztids = ssdb:hget("qyjh_tea_xzts",person_id)
local xztids = hxztids[1]

if not xztids or string.len(xztids) == 0 then
	xztids =","
end
--获取当前用户所属的协作体结束
--获取当前教师所属大学区下所属的协作体开始
local hdxztids = ssdb:hget("qyjh_tea_xzts"..dxq_id,person_id)
local dxztids = hdxztids[1]

if not dxztids or string.len(dxztids) == 0 then
	dxztids =","
end

--获取当前教师所属大学区下所属的协作体结束
if operationtype == "1" then
	allteaids = ","..person_id.. allteaids
	orgteaids = ","..person_id.. orgteaids
	xztids = ","..xzt_id.. xztids
	dxztids = ","..xzt_id.. dxztids
	ngx.log(ngx.ERR, "&&&&&&&&&&&&&>"..qyjh_id.."<=sql=");
	ssdb:zset("qyjh_qyjh_tea_uploadcount_"..qyjh_id,person_id,0)
	ssdb:zset("qyjh_dxq_tea_uploadcount_"..dxq_id,person_id,0)
	ssdb:zset("qyjh_xzt_tea_uploadcount_"..xzt_id,person_id,0)
elseif operationtype == "2" then
	allteaids = string.gsub(allteaids, ","..person_id..",", ",")
	orgteaids = string.gsub(orgteaids, ","..person_id..",", ",")
	xztids = string.gsub(xztids, ","..xzt_id..",", ",")
	dxztids = string.gsub(dxztids, ","..xzt_id..",", ",")
	
	--陈续刚于2015.02.06添加，增加了修改教师的相关资源数量统计开始
	--教师在协作体的上传量
	local xtuc = ssdb:zget("qyjh_xzt_tea_uploadcount_"..xzt_id,person_id)
	if not xtuc[1] or string.len(xtuc[1])then
		xtuc[1] = 0
	end
	xtuc = tonumber(xtuc[1])
	--陈续刚于2015.02.06添加，增加了修改教师的相关资源数量统计开始
	--修改区域均衡资源数量
	ssdb:hincr("qyjh_qyjh_tj_"..qyjh_id,"zy_tj",-xtuc)
	--修改大学区资源数量
	ssdb:hincr("qyjh_dxq_tj_"..dxq_id,"zy_tj",-xtuc)
	--修改协作体资源总量
	ssdb:hincr("qyjh_xzt_tj_"..xzt_id,"zy_tj",-xtuc)
	--修改学校在区域均衡的资源数量
	ssdb:zincr("qyjh_qyjh_org_uploadcount_"..qyjh_id,org_id,-xtuc)
	--修改学校在大学区的资源数量
	ssdb:zincr("qyjh_dxq_org_uploadcount_"..dxq_id,org_id,-xtuc)
	--删除用户在区域均衡的上传量
	ssdb:zdel("qyjh_qyjh_tea_uploadcount_"..qyjh_id,person_id)
	--删除用户在大学区的上传量
	ssdb:zdel("qyjh_dxq_tea_uploadcount_"..dxq_id,person_id) 
	--删除用户在协作体的上传量
	ssdb:zdel("qyjh_xzt_tea_uploadcount_"..xzt_id,person_id)
	--陈续刚于2015.02.06添加，增加了修改教师的相关资源数量统计结束
	
	--从t_base_publish表删除教师上传的数据
	--*****
	--ts
	local n = ngx.now();
	local ts = os.date("%Y%m%d%H%M%S").."00"..string.sub(n,12,14);
	ts = ts..string.rep("0",19-string.len(ts));
	local ids = "";
	local ssql = "SELECT id from t_base_publish "..
		"WHERE person_id = "..quote(person_id).." "..
		"AND pub_type = 3".." "..
		"AND pub_target = "..quote(xzt_id).." "..
		"AND b_delete = 0;"
		local result = mysql_db:query(ssql)
		if result and result[1] then
			--update
			local usql = "UPDATE t_base_publish SET b_delete = 1, update_ts = "..ts.." "..
			"WHERE person_id = "..quote(person_id).." "..
			"AND pub_type = 3".." "..
			"AND pub_target = "..quote(xzt_id).." "..
			"AND b_delete = 0;"
			local ok, err = mysql_db:query(usql)
			if ok then
				--删除缓冲
				for i = 1,#result,1 do
					cache:del("publish_"..result[i].id)
				end
				
			end
		end
	--*****
end
ssdb:hset("qyjh_xzt_teas",xzt_id,allteaids)
ssdb:hset("qyjh_xzt_org_teas",xzt_id.."_"..org_id,orgteaids)
ssdb:hset("qyjh_tea_xzts",person_id,xztids)
ssdb:hset("qyjh_tea_xzts"..dxq_id,person_id,dxztids)


--修改协作体统计中的教师数量开始 【陈续刚于 2014.01.29增加】
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

local res = Split(allteaids,",")
if #res <= 2 then
	ssdb:hset("qyjh_xzt_tj_"..xzt_id,"js_tj",0)
else
	ssdb:hset("qyjh_xzt_tj_"..xzt_id,"js_tj",#res-2)	
end
--修改协作体统计中的教师数量结束

say("{\"success\":true,\"info\":\"操作成功！\"}")

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
mysql_db:set_keepalive(0,v_pool_size)
