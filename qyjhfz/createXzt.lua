--[[
创建协作体
@Author  chenxg
@Date    2015-03-02
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
local qyjh_id = args["qyjh_id"]
local dxq_id = args["dxq_id"]
local subject_id = args["subject_id"]
local name = args["name"]
local description = args["description"]
local logo_url = args["logo_url"]
local person_id = args["person_id"]

--从cookie获取当前用户的身份和person_id
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)
local cookie_person_id = tostring(ngx.var.cookie_person_id)
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

local sch_id = cache:hget("person_"..person_id.."_"..cookie_identity_id,"xiao")
local province_id = cache:hget("person_"..person_id.."_"..cookie_identity_id,"sheng")
local city_id = cache:hget("person_"..person_id.."_"..cookie_identity_id,"shi")
local district_id = cache:hget("person_"..person_id.."_"..cookie_identity_id,"qu")
local ts = os.date("%Y-%m-%d %H:%M:%S")
local n = ngx.now();
local ts2 = os.date("%Y%m%d%H%M%S").."00"..string.sub(n,12,14);
ts2 = ts2..string.rep("0",19-string.len(ts2));
local id = cache:incr("t_qyjh_xzt_pk")

--判断参数是否为空
if not qyjh_id or string.len(qyjh_id) == 0 
  or not subject_id or string.len(subject_id) == 0 
  or not dxq_id or string.len(dxq_id) == 0 
  or not name or string.len(name) == 0 
  or not description or string.len(description) == 0 
  or not logo_url or string.len(logo_url) == 0
  or not person_id or string.len(person_id) == 0 
  then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end


--取协作体id
local xzt_id = ssdb:incr("qyjh_pk")[1]

--(1)存储协作体跟区域均衡对应关系信息
ssdb:zset("qyjh_qyjh_xzts_"..qyjh_id,xzt_id,ts2)
--(2)存储协作体跟大学区对应关系信息
local qyjh_dxq_xzts = ssdb:hget("qyjh_dxq_xzts",dxq_id)
if not qyjh_dxq_xzts[1] or string.len(qyjh_dxq_xzts[1]) == 0 then
	qyjh_dxq_xzts[1] = ","
end
local ok, err = ssdb:hset("qyjh_dxq_xzts", dxq_id, ","..xzt_id.. qyjh_dxq_xzts[1])
if not ok then
   say("{\"success\":false,\"info\":\""..err.."\"}")
   return
end


--存储详细信息
local xzt = {}
xzt.xzt_id = xzt_id
xzt.qyjh_id = qyjh_id
xzt.dxq_id = dxq_id
xzt.subject_id = subject_id
xzt.name = name
xzt.description = description
xzt.logo_url = logo_url
xzt.person_id = person_id
xzt.createUeer_id = cookie_person_id
xzt.b_use = 1
xzt.b_delete = 0
xzt.createtime = ts
xzt.province_id = province_id
xzt.city_id = city_id
xzt.district_id = district_id
xzt.org_id = sch_id

local ok, err = ssdb:hset("qyjh_xzt", xzt_id, cjson.encode(xzt))
if not ok then
   say("{\"success\":false,\"info\":\""..err.."\"}")
   return
end
--存储协作体和带头人关系
ssdb:hset("qyjh_xzt_manager", xzt_id, person_id)

local qyjh_manager_xzts = ssdb:hget("qyjh_manager_xzts",person_id)
if not qyjh_manager_xzts[1] or string.len(qyjh_manager_xzts[1]) == 0  then
	qyjh_manager_xzts[1] = ","
end
local ok, err = ssdb:hset("qyjh_manager_xzts", person_id, ","..xzt_id.. qyjh_manager_xzts[1])
if not ok then
   say("{\"success\":false,\"info\":\""..err.."\"}")
   return
end

--存储带头人和大学区的对应关系开始=======================================
--陈续刚20150430添加，维护带头人
local hdtrids = ssdb:hget("qyjh_dxq_dtrs",dxq_id)
local dtrids = hdtrids[1]
if string.find(dtrids,person_id) == nil then
	ssdb:hincr("qyjh_dxq_tj",dxq_id.."_dtr_tj",1)
end


--获取大学区下的全部带头人
local hallteaids = ssdb:hget("qyjh_dxq_dtrs",dxq_id)
local allteaids = hallteaids[1]

if not allteaids or string.len(allteaids) == 0 then
	allteaids =","
end
--获取大学区下的全部带头人结束
--获取大学区某个学校下的带头人列表开始
local horgteaids = ssdb:hget("qyjh_dxq_org_dtrs",dxq_id.."_"..sch_id)
local orgteaids = horgteaids[1]

if not orgteaids or string.len(orgteaids) == 0 then
	orgteaids =","
end
--获取大学区某个学校下的带头人列表结束
allteaids = string.gsub(allteaids, ","..person_id..",", ",")
orgteaids = string.gsub(orgteaids, ","..person_id..",", ",")
ssdb:hset("qyjh_dxq_org_dtrs",dxq_id.."_"..sch_id,orgteaids..person_id..",")
ssdb:hset("qyjh_dxq_dtrs",dxq_id,allteaids..person_id..",")
ssdb:zset("qyjh_qyjh_dtrs_"..qyjh_id,person_id,ts2)
ssdb:hset("qyjh_dtr_dxq",person_id,dxq_id)
--存储带头人和大学区的对应关系结束======================================

--存储协作体点击量
ssdb:zset("qyjh_qyjh_xzt_djl_"..qyjh_id, xzt_id,0)
ssdb:zset("qyjh_dxq_xzt_djl_"..dxq_id, xzt_id,0)

--初始化协作体统计
ssdb:hset("qyjh_xzt_tj",xzt_id.."_".."js_tj",1)
ssdb:hset("qyjh_xzt_tj",xzt_id.."_".."zy_tj",0)
ssdb:hset("qyjh_xzt_tj",xzt_id.."_".."hd_tj",0)
ssdb:hset("qyjh_xzt_tj",xzt_id.."_".."wk_tj",0)
ssdb:zset("qyjh_xzt_sort_"..dxq_id,xzt_id,0)
ssdb:zset("qyjh_qyjh_xzt_sort_"..qyjh_id,xzt_id,0)

--存储区域均衡下协作体数量开始
ssdb:hincr("qyjh_qyjh_tj_"..qyjh_id,"xzt_tj", 1)

--存储大学区下协作体数量开始
ssdb:hincr("qyjh_dxq_tj",dxq_id.."_".."xzt_tj", 1)
--存储大学区下协作体数量结束


--往mysql表存储协作体信息
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

local insertSql = "insert into t_qyjh_xzt (id,qyjh_id,dxq_id,xzt_id,xzt_name,subject_id,person_name,ts,person_id,createUeer_id)values("
			..xzt_id..","..quote(qyjh_id)..","..quote(dxq_id)..","..quote(xzt_id)..","..quote(name)..","..quote(subject_id)..","..quote(person_name)..","..quote(ts2)..","..quote(person_id)..","..quote(cookie_person_id)..")";		
local ok, err = db:query(insertSql)
--[[if ok then
	cache:hmset("qyjh_xzt_"..id, "id", id, "xzt_id",xzt_id)
end]]

--将带头人存储协作体内
local params = "xzt_id="..xzt_id.."&org_id="..sch_id.."&operationtype=1&person_id="..person_id
local res_xzt = ngx.location.capture("/dsideal_yy/ypt/qyjhfz/managePersonForXzt?"..params)
if res_xzt.status ~= 200 then
	say("{\"success\":false,\"info\":\"将带头人存储协作体失败！\"}")
	return
end

say("{\"success\":true,\"xzt_id\":\""..xzt_id.."\",\"name\":\""..name.."\",\"info\":\"协作体创建成功！\"}")

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
-- 将redis连接归还到连接池
cache: set_keepalive(0, v_pool_size)
--mysql放回连接池
db:set_keepalive(0, v_pool_size)
