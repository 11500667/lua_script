--[[
创建大学区
@Author  chenxg
@Date    2015-03-01
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
local name = args["name"]
local description = args["description"]
local logo_url = args["logo_url"]
local person_id = args["person_id"]

--从cookie获取当前用户的省市区ID
local cookie_province_id = tostring(ngx.var.cookie_background_province_id)
local cookie_city_id = tostring(ngx.var.cookie_background_city_id)
local cookie_district_id = tostring(ngx.var.cookie_background_district_id)

--判断参数是否为空
if not qyjh_id or string.len(qyjh_id) == 0 
  or not name or string.len(name) == 0 
  or not description or string.len(description) == 0 
  or not logo_url or string.len(logo_url) == 0
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
--判断是否已经开通
local b, err = ssdb:hexists("qyjh_open", qyjh_id)
if not b then 
	say("{\"success\":false,\"info\":\""..err.."\"}")
	return
end

--取大学区id
local dxq_id = ssdb:incr("qyjh_pk")[1]
local ts = os.date("%Y-%m-%d %H:%M:%S")
ts2 = os.date("%Y%m%d%H%M%S")
--(1)存储大学区跟区域均衡对应关系信息
ssdb:zset("qyjh_qyjh_dxqs_"..qyjh_id,dxq_id,ts2)

--存储详细信息
local dxq = {}
dxq.dxq_id = dxq_id
dxq.qyjh_id = qyjh_id
dxq.name = name
dxq.description = description
dxq.logo_url = logo_url
dxq.person_id = person_id
dxq.b_use = 1
dxq.b_delete = 0
dxq.createtime = ts
dxq.province_id = cookie_province_id
dxq.city_id = cookie_city_id
dxq.district_id = cookie_district_id

local ok, err = ssdb:hset("qyjh_dxq", dxq_id, cjson.encode(dxq))
if not ok then
   say("{\"success\":false,\"info\":\""..err.."\"}")
   return
end
--存储大学区--大学区管理员信息
ssdb:hset("qyjh_dxq_manager", dxq_id, person_id)

local qyjh_manager_dxqs = ssdb:hget("qyjh_manager_dxqs",person_id)
if not qyjh_manager_dxqs[1] or string.len(qyjh_manager_dxqs[1]) == 0  then
	qyjh_manager_dxqs[1] = ","
end
local ok, err = ssdb:hset("qyjh_manager_dxqs", person_id, ","..dxq_id.. qyjh_manager_dxqs[1])
if not ok then
   say("{\"success\":false,\"info\":\""..err.."\"}")
   return
end

ssdb:zset("qyjh_manager_dxqs_"..person_id,dxq_id,ts2)
--存储大学区点击量
ssdb:zset("qyjh_dxq_djl_"..qyjh_id,dxq_id,0)
--初始化大学区统计
ssdb:hset("qyjh_dxq_tj",dxq_id.."_".."xzt_tj",0)
ssdb:hset("qyjh_dxq_tj",dxq_id.."_".."xx_tj",0)
ssdb:hset("qyjh_dxq_tj",dxq_id.."_".."js_tj",0)
ssdb:hset("qyjh_dxq_tj",dxq_id.."_".."zy_tj",0)
ssdb:hset("qyjh_dxq_tj",dxq_id.."_".."hd_tj",0)
ssdb:hset("qyjh_dxq_tj",dxq_id.."_".."dtr_tj",0)
--**************

--存储区域均衡下大学区数量开始
ssdb:hincr("qyjh_qyjh_tj_"..qyjh_id,"dxq_tj", 1)
--存储区域均衡下大学区数量结束
--mysql存储大学区信息
local n = ngx.now();
local ts3 = os.date("%Y%m%d%H%M%S").."00"..string.sub(n,12,14);
ts3 = ts3..string.rep("0",19-string.len(ts3));
local insertSql = "insert into t_qyjh_dxq (id,qyjh_id,dxq_id,dxq_name,ts,person_id)values("
		..dxq_id..","..quote(qyjh_id)..","..quote(dxq_id)..","..quote(name)..","..quote(ts3)..","..quote(person_id)..")";
		
mysql_db:query(insertSql)

--return
say("{\"success\":true,\"dxq_id\":\""..dxq_id.."\",\"name\":\""..name.."\",\"info\":\"大学区创建成功！\"}")

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
--mysql放回连接池
mysql_db:set_keepalive(0,v_pool_size)
