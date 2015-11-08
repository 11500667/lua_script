--[[
个人中心：大学区管理员登录，获取所属和所管理的大学区[mysql版]
@Author  chenxg
@Date    2015-06-03
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
--参数 
local qyjh_id = args["qyjh_id"]
local person_id = args["person_id"]
local pageSize = ngx.var.arg_pageSize
local pageNumber = ngx.var.arg_pageNumber

--判断参数是否为空
if not person_id or string.len(person_id) == 0
	or not qyjh_id or string.len(qyjh_id) == 0
	or not pageSize or string.len(pageSize) == 0 
	or not pageNumber or string.len(pageNumber) == 0
   then
    say("{\"success\":false,\"info\":\"person_id or qyjh_id or pageSize or pageNumber 参数错误！\"}")
    return
end
pageSize = tonumber(pageSize)
pageNumber = tonumber(pageNumber)
--创建ssdb连接
local ssdblib = require "resty.ssdb"
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
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

local returnjson = {}
returnjson.pageSize = pageSize
returnjson.pageNumber = pageNumber
--获取用户管理的大学区

local dxq_sql = "select d.xzt_tj,d.xx_tj,d.js_tj,d.hd_tj,d.zy_tj,d.dtr_tj,d.dxq_id,d.dxq_name as name,d.person_id,d.description,d.district_id,d.city_id,d.province_id,d.createtime,d.logo_url,d.b_use,d.b_delete,d.qyjh_id,d.is_init  from t_qyjh_dxq d where b_delete=0 and b_use=1 and person_id = "..person_id
local has_result, err, errno, sqlstate = db:query(dxq_sql);
if not has_result then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	return;
end

--获取用户所属于的大学区开始

local cookie_identity_id = tostring(ngx.var.cookie_identity_id)
local schID = cache:hget("person_"..person_id.."_"..cookie_identity_id,"xiao")

local dxq_org_sql = "select d.xzt_tj,d.xx_tj,d.js_tj,d.hd_tj,d.zy_tj,d.dtr_tj,d.dxq_id,d.dxq_name as name,d.person_id,d.description,d.district_id,d.city_id,d.province_id,d.createtime,d.logo_url,d.b_use,d.b_delete,d.qyjh_id,d.is_init  from t_qyjh_dxq d where b_delete=0 and b_use=1 and dxq_id in(select dxq_id from t_qyjh_dxq_org where b_use=1 and org_id = "..schID..")"
local has_result2, err, errno, sqlstate = db:query(dxq_org_sql);
if not has_result2 then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	return;
end

local dxq_id = "0"
for i=1,#has_result,1 do
	dxq_id = has_result[i]["dxq_id"]..","..dxq_id
end
for i=1,#has_result2,1 do
	dxq_id = has_result2[i]["dxq_id"]..","..dxq_id
end
local zy_sql = "select pub_target as dxq_id,count(distinct obj_id_int) as zy_tj from t_base_publish where b_delete=0 and pub_type=3 and pub_target in("..dxq_id..") group by pub_target"
local zy_result, err, errno, sqlstate = db:query(zy_sql);
if not zy_result then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	return;
end

local dxqList = {}
if #has_result>=1 then
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
		
		temp.xzt_tj = has_result[i]["xzt_tj"]
		temp.xx_tj = has_result[i]["xx_tj"]
		temp.js_tj = has_result[i]["js_tj"]
		temp.hd_tj = has_result[i]["hd_tj"]
		temp.zy_tj = 0
		for j=1,#zy_result,1 do
			if temp.dxq_id == zy_result[j]["xzt_id"] then
				temp.zy_tj = zy_result[j]["zy_tj"]
				break
			end
		end
		temp.dtr_tj = has_result[i]["dtr_tj"]
		
		temp.isdxqmanager=false
		--ngx.log(ngx.ERR, "cxg_log countsql===>"..temp.person_id.."<====countsql"..person_id);
		if tonumber(temp.person_id) == tonumber(person_id) then
			temp.isdxqmanager=true
		end
		
		local personlist
		local res_person = ngx.location.capture("/dsideal_yy/person/getPersonNameListByIds?ids="..temp.person_id)
		if res_person.status == 200 then
			personlist = cjson.decode(res_person.body)
		else
			say("{\"success\":false,\"info\":\"查询用户信息失败！\"}")
			return
		end
		temp.person_name = personlist.list[1].personName
		
		
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
			temp.xzt_tj = has_result2[1]["xzt_tj"]
			temp.xx_tj = has_result2[1]["xx_tj"]
			temp.js_tj = has_result2[1]["js_tj"]
			temp.hd_tj = has_result2[1]["hd_tj"]
			temp.zy_tj = 0
			for j=1,#zy_result,1 do
				if temp.dxq_id == zy_result[j]["xzt_id"] then
					temp.zy_tj = zy_result[j]["zy_tj"]
					break
				end
			end
			temp.dtr_tj = has_result2[1]["dtr_tj"]
			
			temp.isdxqmanager=false
			if tonumber(temp.person_id) == tonumber(person_id) then
				temp.isdxqmanager=true
			end
			
			local personlist
			local res_person = ngx.location.capture("/dsideal_yy/person/getPersonNameListByIds?ids="..temp.person_id)
			if res_person.status == 200 then
				personlist = cjson.decode(res_person.body)
			else
				say("{\"success\":false,\"info\":\"查询用户信息失败！\"}")
				return
			end
			temp.person_name = personlist.list[1].personName
			
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
		
		temp.xzt_tj = has_result2[1]["xzt_tj"]
		temp.xx_tj = has_result2[1]["xx_tj"]
		temp.js_tj = has_result2[1]["js_tj"]
		temp.hd_tj = has_result2[1]["hd_tj"]
		temp.zy_tj = 0
		for j=1,#zy_result,1 do
			if temp.dxq_id == zy_result[j]["xzt_id"] then
				temp.zy_tj = zy_result[j]["zy_tj"]
				break
			end
		end
		temp.dtr_tj = has_result2[1]["dtr_tj"]
		
		temp.isdxqmanager=false
		if tonumber(temp.person_id) == tonumber(person_id) then
			temp.isdxqmanager=true
		end
		
		local personlist
		local res_person = ngx.location.capture("/dsideal_yy/person/getPersonNameListByIds?ids="..temp.person_id)
		if res_person.status == 200 then
			personlist = cjson.decode(res_person.body)
		else
			say("{\"success\":false,\"info\":\"查询用户信息失败！\"}")
			return
		end
		temp.person_name = personlist.list[1].personName

		dxqList[#dxqList+1] = temp
	end
end
local totalRow = #dxqList
local totalPage = math.floor((totalRow + pageSize - 1) / pageSize)
returnjson.totalPage = totalPage
returnjson.totalRow = totalRow

local limit = pageSize*pageNumber
if limit>=totalRow then
	limit=totalRow
end
local dxq_list = {}
for i=pageSize*pageNumber-pageSize+1,limit,1 do
	dxq_list[#dxq_list+1] = dxqList[i]
end


returnjson.list = dxq_list
returnjson.success = "true"
say(cjson.encode(returnjson))

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
-- 将redis连接归还到连接池
cache: set_keepalive(0, v_pool_size)
--mysql放回连接池
db:set_keepalive(0,v_pool_size)