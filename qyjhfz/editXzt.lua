--[[
保存编辑后的大学区
@Author  chenxg
@Date    2015-01-19
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"
local quote = ngx.quote_sql_str

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
local subject_id = args["subject_id"]
local name = args["name"]
local description = args["description"]
local logo_url = args["logo_url"]
local person_id = args["person_id"]

--从cookie获取当前用户的省市区ID
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)
-- 获取redis链接
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--创建ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--获取mysql数据库连接
local mysql = require "resty.mysql";
local db, err = mysql : new();
if not db then 
	ngx.log(ngx.ERR, err);
	return;
end
db:set_timeout(1000) -- 1 sec

local ok, err, errno, sqlstate = db:connect{
	host = v_mysql_ip,
	port = v_mysql_port,
	database = v_mysql_database,
	user = v_mysql_user,
	password = v_mysql_password,
	max_packet_size = 1024 * 1024 }

if not ok then
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}")
	ngx.log(ngx.ERR, "=====> 连接数据库失败!");
	return
end



--[[local province_id = cache:hget("person_"..person_id.."_"..cookie_identity_id,"sheng")
local city_id = cache:hget("person_"..person_id.."_"..cookie_identity_id,"shi")
local district_id = cache:hget("person_"..person_id.."_"..cookie_identity_id,"qu")]]


--判断参数是否为空
if not xzt_id or string.len(xzt_id) == 0  
  or not subject_id or string.len(subject_id) == 0 
  or not name or string.len(name) == 0 
  or not description or string.len(description) == 0 
  or not logo_url or string.len(logo_url) == 0
  or not person_id or string.len(person_id) == 0 
  then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

--base64
--description = ngx.decode_base64(description)
--name = ngx.decode_base64(name)

--存储详细信息
local hxzt = ssdb:hget("qyjh_xzt",xzt_id)
local xzt = cjson.decode(hxzt[1])


if xzt.person_id ~= person_id then --协作体带头人发生了变化
	local old_sch_id = cache:hget("person_"..xzt.person_id.."_"..cookie_identity_id,"xiao")
	local new_sch_id = cache:hget("person_"..person_id.."_"..cookie_identity_id,"xiao")
	--删除原管理员
	--ssdb:hdel("qyjh_manager_xzts", xzt.person_id)
	local old_qyjh_manager_xzts = ssdb:hget("qyjh_manager_xzts",xzt.person_id)
	if not old_qyjh_manager_xzts[1] or string.len(old_qyjh_manager_xzts[1]) == 0  then
		old_qyjh_manager_xzts[1] = ","
	end
	old_qyjh_manager_xzts[1] = string.gsub(old_qyjh_manager_xzts[1], ","..xzt_id..",", ",")
	local ok, err = ssdb:hset("qyjh_manager_xzts", xzt.person_id, old_qyjh_manager_xzts[1])
	if not ok then
	   say("{\"success\":false,\"info\":\""..err.."\"}")
	   return
	end
	--local params = "xzt_id="..xzt_id.."&org_id="..old_sch_id.."&operationtype=2&person_id="..xzt.person_id
	--ngx.location.capture("/dsideal_yy/ypt/qyjhfz/managePersonForXzt?"..params)
	
	--存储新的管理员
	--ssdb:hset("qyjh_manager_xzts", person_id, xzt_id)
	local qyjh_manager_xzts = ssdb:hget("qyjh_manager_xzts",person_id)
	if not qyjh_manager_xzts[1] or string.len(qyjh_manager_xzts[1]) == 0  then
		qyjh_manager_xzts[1] = ","
	end
	qyjh_manager_xzts[1] = string.gsub(qyjh_manager_xzts[1], ","..xzt_id..",", ",")
	local ok, err = ssdb:hset("qyjh_manager_xzts", person_id, ","..xzt_id..qyjh_manager_xzts[1])
	if not ok then
	   say("{\"success\":false,\"info\":\""..err.."\"}")
	   return
	end
	local params = "xzt_id="..xzt_id.."&org_id="..new_sch_id.."&operationtype=1&person_id="..person_id
	ngx.location.capture("/dsideal_yy/ypt/qyjhfz/managePersonForXzt?"..params)
	ssdb:hset("qyjh_xzt_manager", xzt_id, person_id)
	
	
	--存储带头人和大学区的对应关系开始=======================================
	--获取大学区下的全部带头人
	local hallteaids = ssdb:hget("qyjh_dxq_dtrs",xzt.dxq_id)
	local allteaids = hallteaids[1]

	if not allteaids or string.len(allteaids) == 0 then
		allteaids =","
	end
	--获取大学区下的全部带头人结束
		--获取大学区某个学校下的带头人列表开始
	local old_horgteaids = ssdb:hget("qyjh_dxq_org_dtrs",xzt.dxq_id.."_"..old_sch_id)
	local old_orgteaids = old_horgteaids[1]

	if not old_orgteaids or string.len(old_orgteaids) == 0 then
		old_orgteaids =","
	end
		--获取大学区某个学校下的带头人列表开始
	local new_horgteaids = ssdb:hget("qyjh_dxq_org_dtrs",xzt.dxq_id.."_"..new_sch_id)
	local new_orgteaids = new_horgteaids[1]

	if not new_orgteaids or string.len(new_orgteaids) == 0 then
		new_orgteaids =","
	end
	--获取大学区某个学校下的带头人列表结束
	allteaids = string.gsub(allteaids, ","..person_id..",", ",")
	old_orgteaids = string.gsub(old_orgteaids, ","..xzt.person_id..",", ",")
	new_orgteaids = string.gsub(new_orgteaids, ","..person_id..",", ",")
	ssdb:hset("qyjh_dxq_org_dtrs",xzt.dxq_id.."_"..old_sch_id,old_orgteaids)
	ssdb:hset("qyjh_dxq_org_dtrs",xzt.dxq_id.."_"..new_sch_id,new_orgteaids..person_id..",")
	ssdb:hset("qyjh_dxq_dtrs",xzt.dxq_id,allteaids..person_id..",")
	ssdb:zset("qyjh_qyjh_dtrs_"..xzt.qyjh_id,person_id,os.date("%Y%m%d%H%M%S"))
	ssdb:hset("qyjh_dtr_dxq",person_id,xzt.dxq_id)
	--存储带头人和大学区的对应关系结束======================================
	
end

xzt.name = name
xzt.subject_id = subject_id
xzt.description = description
xzt.logo_url = logo_url
xzt.person_id = person_id

local ok, err = ssdb:hset("qyjh_xzt", xzt_id, cjson.encode(xzt))
if not ok then
   say("{\"success\":false,\"info\":\""..err.."\"}")
   return
end

--更新mysql表中协作体信息
--获取person_id详情, 调用java接口
local personlist
local res_person = ngx.location.capture("/dsideal_yy/person/getPersonNameListByIds?ids="..person_id)
if res_person.status == 200 then
	personlist = cjson.decode(res_person.body)
else
	say("{\"success\":false,\"info\":\"查询用户信息失败！\"}")
	return
end
local person_name = personlist.list[1].personName

local n = ngx.now();
local ts2 = os.date("%Y%m%d%H%M%S").."00"..string.sub(n,12,14);
ts2 = ts2..string.rep("0",19-string.len(ts2));
		
local updateSql = "update t_qyjh_xzt set subject_id ="..quote(subject_id)..",xzt_name = "..quote(name)..",person_name ="..quote(person_name)..",person_id ="..quote(person_id)..",ts="..quote(ts2).."   where xzt_id="..quote(xzt_id);
			
local ok, err = db:query(updateSql)

say("{\"success\":true,\"xzt_id\":\""..xzt_id.."\",\"name\":\""..name.."\",\"info\":\"协作体信息修改成功！\"}")

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
-- 将redis连接归还到连接池
cache: set_keepalive(0, v_pool_size)
--mysql放回连接池
db:set_keepalive(0, v_pool_size)
