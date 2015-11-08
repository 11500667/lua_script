--[[
判断当前用户获取所相关的大学区【管理、属于】[mysql版]
@Author  chenxg
@Date    2015-06-05
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
cjson.encode_empty_table_as_object(false);

--获得get请求参数
local person_id = ngx.var.arg_person_id

if not person_id or string.len(person_id) == 0
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

local dxqList = {}

local returnjson ={}
returnjson.success = true

--用户管理的大学区
local user_manage_dxq_sql = "select d.dxq_id,d.dxq_name as name,d.person_id,d.description,d.district_id,d.city_id,d.province_id,d.createtime,d.logo_url,d.b_use,d.b_delete,d.qyjh_id,d.is_init  from t_qyjh_dxq d where b_delete=0 and b_use=1 and person_id = "..person_id
local result, err, errno, sqlstate = db:query(user_manage_dxq_sql);
if not result then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	return;
end
--用户所属的大学区
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)
local schID = cache:hget("person_"..person_id.."_"..cookie_identity_id,"xiao")

local user_own_dxq_sql = "select d.dxq_id,d.dxq_name as name,d.person_id,d.description,d.district_id,d.city_id,d.province_id,d.createtime,d.logo_url,d.b_use,d.b_delete,d.qyjh_id,d.is_init  from t_qyjh_dxq d,t_qyjh_dxq_org o where d.dxq_id = o.dxq_id and d.b_use=1 and o.b_use=1 and o.org_id = "..schID..""
local result2, err, errno, sqlstate = db:query(user_own_dxq_sql);
if not result2 then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	return;
end
--ngx.log(ngx.ERR,"====*****>"..ismanager[1].."*"..owndqxs[1].."<*****====")
if #result>=1 then
	for i=1,#result,1 do
		local sum = "0"
		for i=1,#result,1 do
			local temp = {}
			temp.dxq_id = result[i]["dxq_id"]
			temp.name = result[i]["name"]
			temp.person_id = result[i]["person_id"]
			temp.description = result[i]["description"]
			temp.district_id = result[i]["district_id"]
			temp.city_id = result[i]["city_id"]
			temp.province_id = result[i]["province_id"]
			temp.createtime = result[i]["createtime"]
			temp.logo_url = result[i]["logo_url"]
			temp.b_use = result[i]["b_use"]
			temp.b_delete = result[i]["b_delete"]
			temp.qyjh_id = result[i]["qyjh_id"]
			temp.is_init = result[1]["is_init"]
			dxqList[#dxqList+1] = temp
			if #result2>=1 then
				local dtr_dxqids = result2[1]["dxq_id"]
				if tostring(result[i]["dxq_id"]) == tostring(dtr_dxqids) then
					sum = "1"
				end
			end
		end
		if tostring(sum) == "0" then
			if #result2>=1 then
				local temp = {}
				temp.dxq_id = result2[1]["dxq_id"]
				temp.name = result2[1]["name"]
				temp.person_id = result2[1]["person_id"]
				temp.description = result2[1]["description"]
				temp.district_id = result2[1]["district_id"]
				temp.city_id = result2[1]["city_id"]
				temp.province_id = result2[1]["province_id"]
				temp.createtime = result2[1]["createtime"]
				temp.logo_url = result2[1]["logo_url"]
				temp.b_use = result2[1]["b_use"]
				temp.b_delete = result2[1]["b_delete"]
				temp.qyjh_id = result2[1]["qyjh_id"]
				temp.is_init = result[1]["is_init"]
				dxqList[#dxqList+1] = temp
			end
		end
	end
else
	if #result2>=1 then
		local temp = {}
		temp.dxq_id = result2[1]["dxq_id"]
		temp.name = result2[1]["name"]
		temp.person_id = result2[1]["person_id"]
		temp.description = result2[1]["description"]
		temp.district_id = result2[1]["district_id"]
		temp.city_id = result2[1]["city_id"]
		temp.province_id = result2[1]["province_id"]
		temp.createtime = result2[1]["createtime"]
		temp.logo_url = result2[1]["logo_url"]
		temp.b_use = result2[1]["b_use"]
		temp.b_delete = result2[1]["b_delete"]
		temp.qyjh_id = result2[1]["qyjh_id"]
		temp.is_init = result2[1]["is_init"]
		dxqList[#dxqList+1] = temp
	end
end
returnjson.dxqList = dxqList

--return
say(cjson.encode(returnjson))

--mysql放回连接池
db:set_keepalive(0,v_pool_size)
cache:set_keepalive(0, v_pool_size)