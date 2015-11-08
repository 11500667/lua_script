--[[
根据当前用户判断是否可以登录区域均衡，是否可以往区域均衡发布资源[mysql版]
@Author  chenxg
@Date    2015-06-01
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"

--获得get请求参数
--local person_id = ngx.var.arg_person_id
local person_id = ngx.var.arg_person_id
if not person_id or string.len(person_id) == 0 then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
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

local cookie_identity_id = tostring(ngx.var.cookie_identity_id)
local quid = {}
local sheng = cache:hget("person_"..person_id.."_"..cookie_identity_id,"sheng")
local shi = cache:hget("person_"..person_id.."_"..cookie_identity_id,"shi")
local qu = cache:hget("person_"..person_id.."_"..cookie_identity_id,"qu")
table.insert(quid,sheng)
table.insert(quid,shi)
table.insert(quid,qu)
--判断region_id是否存在, 存在则返回qyjh_id,b_use,b_open,name
local returnjson = {}

for i=1,#quid,1 do
	local querySql = "select b_open,b_use from t_qyjh_qyjhs where qyjh_id= "..quid[i];
	local result, err, errno, sqlstate = db:query(querySql);
	if not result then
		ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
		return;
	end
	if #result == 0 then
		returnjson.loginsuccess = false
		returnjson.dxqsuccess = false
		returnjson.xztsuccess = false
		returnjson.success = false
	else
		if result[1]["b_use"] == 0 then
			returnjson.loginsuccess = false
			returnjson.dxqsuccess = false
			returnjson.xztsuccess = false
			returnjson.success = false
		else
			returnjson.success = true
			returnjson.loginsuccess = true
			returnjson.dxqsuccess = false
			returnjson.xztsuccess = false
			returnjson.qyjh_id = quid[i]
			--判断用户是否有所属于的大学区
			local dxq_sql = "select dxq_id from t_qyjh_dxq where b_use=1 and person_id = "..person_id
			local has_result, err, errno, sqlstate = db:query(dxq_sql);
			if not has_result then
				ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
				return;
			end
			local schID = cache:hget("person_"..person_id.."_"..cookie_identity_id,"xiao")
			local dxq_org_sql = "select dxq_id from t_qyjh_dxq_org where b_use=1 and org_id = "..schID
			local has_result2, err, errno, sqlstate = db:query(dxq_org_sql);
			if not has_result2 then
				ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
				return;
			end
			if #has_result>=1 or #has_result2 >= 1 then
				returnjson.dxqsuccess = true
				--判断用户是否有所属于的协作体
				local xzt_sql = "select xzt_id from t_qyjh_xzt_tea where b_use=1 and tea_id = "..person_id
				local has_result, err, errno, sqlstate = db:query(xzt_sql);
				if not has_result then
					ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
					return;
				end
				if #has_result>0 then
					returnjson.xztsuccess = true
				end
			end
			break
			
		end
	end
end

--return
say(cjson.encode(returnjson))

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0,v_pool_size)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)