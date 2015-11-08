--[[
判断当前用户是否为大学区或者协作体管理员[mysql版]
@Author  chenxg
@Date    2015-06-02
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
cjson.encode_empty_table_as_object(false);

--获得get请求参数
local person_id = ngx.var.arg_person_id
--1：大学区2：协作体
local page_type = ngx.var.arg_page_type
local path_id = ngx.var.arg_path_id
if not person_id or string.len(person_id) == 0
	then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

-- 获取redis链接
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
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
local dxqList = {}
local xztList = {}
local returnjson ={}
returnjson.success = true

if not page_type then
	--判断是否是大学区管理员，是则返回所管理的大学区列表
	--用户管理的大学区
	local dxq_sql = "select d.dxq_id,d.dxq_name as name,d.person_id,d.description,d.district_id,d.city_id,d.province_id,d.createtime,d.logo_url,d.b_use,d.b_delete,d.qyjh_id,is_init  from t_qyjh_dxq d where b_delete=0 and b_use=1 and person_id = "..person_id
	local has_result, err, errno, sqlstate = db:query(dxq_sql);
	if not has_result then
		ngx.say("{\"success\":false,\"info\":\"查询数据失败11！\"}");
		return;
	end

	--用户在某个大学区是带头人
	local dxq_org_sql = "select d.dxq_id,d.dxq_name as name,d.person_id,d.description,d.district_id,d.city_id,d.province_id,d.createtime,d.logo_url,d.b_use,d.b_delete,d.qyjh_id,is_init  from t_qyjh_dxq d,t_qyjh_dxq_dtr o where d.dxq_id = o.dxq_id and d.b_use=1 and o.b_use=1 and o.person_id = "..person_id..""
	local has_result2, err, errno, sqlstate = db:query(dxq_org_sql);
	if not has_result2 then
		ngx.say("{\"success\":false,\"info\":\"查询数据失败22！\"}");
		return;
	end
	
	
	if #has_result>=1 then
		returnjson.isDxqManager = true
		local sum = "0"
		for i=1,#has_result,1 do
			local temp = {}
			temp.dxq_id = has_result[i]["dxq_id"]
			temp.name = has_result[i]["name"]
			temp.person_id = has_result[i]["person_id"]
			temp.description = has_result[i]["description"]
			temp.district_id = has_result[i]["district_id"]
			temp.city_id = has_result[i]["city_id"]
			temp.province_id = has_result[i]["province_id"]
			temp.createtime = has_result[i]["createtime"]
			temp.logo_url = has_result[i]["logo_url"]
			temp.b_use = has_result[i]["b_use"]
			temp.b_delete = has_result[i]["b_delete"]
			temp.qyjh_id = has_result[i]["qyjh_id"]
			temp.is_init = has_result[i]["is_init"]
			dxqList[#dxqList+1] = temp
			if #has_result2>=1 then
				local dtr_dxqids = has_result2[1]["dxq_id"]
				if tostring(has_result[i]["dxq_id"]) == tostring(dtr_dxqids) then
					sum = "1"
				end
			end
		end
		if tostring(sum) == "0" then
			if #has_result2>=1 then
				local temp = {}
				temp.dxq_id = has_result2[1]["dxq_id"]
				temp.name = has_result2[1]["name"]
				temp.person_id = has_result2[1]["person_id"]
				temp.description = has_result2[1]["description"]
				temp.district_id = has_result2[1]["district_id"]
				temp.city_id = has_result2[1]["city_id"]
				temp.province_id = has_result2[1]["province_id"]
				temp.createtime = has_result2[1]["createtime"]
				temp.logo_url = has_result2[1]["logo_url"]
				temp.b_use = has_result2[1]["b_use"]
				temp.b_delete = has_result2[1]["b_delete"]
				temp.qyjh_id = has_result2[1]["qyjh_id"]
				temp.is_init = has_result2[1]["is_init"]
				dxqList[#dxqList+1] = temp
			end
		end
	else
		if #has_result2>=1 then
			local temp = {}
			temp.dxq_id = has_result2[1]["dxq_id"]
			temp.name = has_result2[1]["name"]
			temp.person_id = has_result2[1]["person_id"]
			temp.description = has_result2[1]["description"]
			temp.district_id = has_result2[1]["district_id"]
			temp.city_id = has_result2[1]["city_id"]
			temp.province_id = has_result2[1]["province_id"]
			temp.createtime = has_result2[1]["createtime"]
			temp.logo_url = has_result2[1]["logo_url"]
			temp.b_use = has_result2[1]["b_use"]
			temp.b_delete = has_result2[1]["b_delete"]
			temp.qyjh_id = has_result2[1]["qyjh_id"]
			temp.is_init = has_result2[1]["is_init"]
			dxqList[#dxqList+1] = temp
		end
		returnjson.isDxqManager = false
	end
	returnjson.dxqList = dxqList
	
	--判断是否是协作体带头人，是则返回所管理的协作体列表
	--用户在某个大学区是带头人
	local dxq_org_sql = "select d.dxq_id,d.dxq_name as name,d.person_id,d.description,d.district_id,d.city_id,d.province_id,d.createtime,d.logo_url,d.b_use,d.b_delete,d.qyjh_id,d.is_init  from t_qyjh_dxq d,t_qyjh_dxq_dtr o where d.dxq_id = o.dxq_id and d.b_use=1 and o.b_use=1 and o.person_id = "..person_id..""
	local has_result2, err, errno, sqlstate = db:query(dxq_org_sql);
	if not has_result2 then
		ngx.say("{\"success\":false,\"info\":\"查询数据失败33！\"}");
		return;
	end

	if #has_result2>0 then
		returnjson.isXztManager = true
		returnjson.dxq_id = has_result2[1]["dxq_id"]
		returnjson.is_init = has_result2[1]["is_init"]
		
		local xzt_sql = "select qyjh_id,dxq_id,xzt_id,xzt_name as name,subject_id,person_name,ts,person_id,createUeer_id,description,district_id,city_id,province_id,createtime,logo_url,org_id,is_init from t_qyjh_xzt where b_use=1 and person_id = "..person_id.." "
		local xzt_result, err, errno, sqlstate = db:query(xzt_sql);
		if not xzt_result then
			ngx.say("{\"success\":false,\"info\":\"查询数据失败44！\"}");
			return;
		end
		if #xzt_result>0 then
			for i=1,#xzt_result,1 do
				local temp = {}
				temp.qyjh_id = xzt_result[i]["qyjh_id"]
				temp.dxq_id = xzt_result[i]["dxq_id"]
				temp.xzt_id = xzt_result[i]["xzt_id"]
				temp.name = xzt_result[i]["name"]
				temp.person_id = xzt_result[i]["person_id"]
				temp.description = xzt_result[i]["description"]
				temp.district_id = xzt_result[i]["district_id"]
				temp.city_id = xzt_result[i]["city_id"]
				temp.province_id = xzt_result[i]["province_id"]
				temp.createtime = xzt_result[i]["createtime"]
				temp.logo_url = xzt_result[i]["logo_url"]
				temp.b_use = xzt_result[i]["b_use"]
				temp.createUeer_id = xzt_result[i]["createUeer_id"]
				temp.subject_id = xzt_result[i]["subject_id"]
				temp.b_delete = xzt_result[i]["b_delete"]
				temp.org_id = xzt_result[i]["org_id"]
				temp.is_init = xzt_result[1]["is_init"]
				xztList[#xztList+1] = temp
			end
		end
	else
		returnjson.isXztManager = false
	end
	returnjson.xztList = xztList
else
	if page_type == "1" then--传入大学区ID，判断该用户的身份
		--判断是否为大学区管理员
		--用户管理的大学区
		local dxq_sql = "select d.person_id from t_qyjh_dxq d where b_use=1 and dxq_id = "..path_id
		local has_result, err, errno, sqlstate = db:query(dxq_sql);
		if not has_result then
			ngx.say("{\"success\":false,\"info\":\"查询数据失败55！\"}");
			return;
		end
		if #has_result>0 and tostring(has_result[1]["person_id"]) == tostring(person_id) then
			returnjson.isDxqManager = true
		else
			returnjson.isDxqManager = false
		end
		--判断是否为协作体带头人
		local xzt_sql = "select d.person_id from t_qyjh_dxq_dtr d where b_use=1 and dxq_id = "..path_id.." and person_id="..person_id
		local has_result, err, errno, sqlstate = db:query(xzt_sql);
		if not has_result then
			ngx.say("{\"success\":false,\"info\":\"查询数据失败66！\"}");
			return;
		end

		if #has_result>0 then
			returnjson.isXztManager = true
		else
			returnjson.isXztManager = false
		end	
	elseif page_type == "2" then--判断是否为协作体管理员
		local xzt_sql = "select d.person_id from t_qyjh_dxq_dtr d where b_use=1 and xzt_id = "..path_id.." and person_id="..person_id
		local has_result, err, errno, sqlstate = db:query(xzt_sql);
		if not has_result then
			ngx.say("{\"success\":false,\"info\":\"查询数据失败77！\"}");
			return;
		end
		if #has_result>0 then
			returnjson.isXztManager = true
		else
			returnjson.isXztManager = false
		end
	end
end
if returnjson.isXztManager then
	local cookie_identity_id = tostring(ngx.var.cookie_identity_id)
	local sheng = cache:hget("person_"..person_id.."_"..cookie_identity_id,"sheng")
	local shi = cache:hget("person_"..person_id.."_"..cookie_identity_id,"shi")
	local qu = cache:hget("person_"..person_id.."_"..cookie_identity_id,"qu")
	local xiao = cache:hget("person_"..person_id.."_"..cookie_identity_id,"xiao")
	returnjson.sheng = sheng
	returnjson.shi = shi
	returnjson.qu = qu
	returnjson.xiao = xiao
end
--return
say(cjson.encode(returnjson))

cache:set_keepalive(0, v_pool_size)
--mysql放回连接池
db:set_keepalive(0,v_pool_size)