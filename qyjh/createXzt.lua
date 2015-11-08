--[[
创建协作体
@Author  chenxg
@Date    2015-01-20
--]]

local say = ngx.say

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
local qyjh_id = args["qyjh_id"]
local dxq_id = args["dxq_id"]
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
local sch_id = cache:hget("person_"..person_id.."_"..cookie_identity_id,"xiao")
local province_id = cache:hget("person_"..person_id.."_"..cookie_identity_id,"sheng")
local city_id = cache:hget("person_"..person_id.."_"..cookie_identity_id,"shi")
local district_id = cache:hget("person_"..person_id.."_"..cookie_identity_id,"qu")

-- 将redis连接归还到连接池
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
	ngx.log(ngx.ERR, "====>将Redis连接归还连接池出错！");
end

--判断参数是否为空
if not qyjh_id or string.len(qyjh_id) == 0 
  or not dxq_id or string.len(dxq_id) == 0 
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

--取协作体id
local xzt_id = ssdb:incr("qyjh_pk")[1]

--(1)存储协作体跟区域均衡对应关系信息
local qyjh_qyjh_xzts = ssdb:hget("qyjh_qyjh_xzts",qyjh_id)
if not qyjh_qyjh_xzts[1] or string.len(qyjh_qyjh_xzts[1]) == 0 then
	qyjh_qyjh_xzts[1] = ","
end
local ok, err = ssdb:hset("qyjh_qyjh_xzts", qyjh_id, ","..xzt_id.. qyjh_qyjh_xzts[1])
if not ok then
   say("{\"success\":false,\"info\":\""..err.."\"}")
   return
end

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

local ts = os.date("%Y-%m-%d %H:%M:%S")
--存储详细信息
local xzt = {}
xzt.xzt_id = xzt_id
xzt.qyjh_id = qyjh_id
xzt.dxq_id = dxq_id
xzt.name = name
xzt.description = description
xzt.logo_url = logo_url
xzt.person_id = person_id
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
ssdb:hset("qyjh_manager_xzts", person_id, xzt_id)
--存储协作体点击量
ssdb:zset("qyjh_qyjh_xzt_djl_"..qyjh_id, xzt_id,0)
ssdb:zset("qyjh_dxq_xzt_djl_"..dxq_id, xzt_id,0)

--初始化协作体统计
ssdb:hset("qyjh_xzt_tj_"..xzt_id,"xx_tj",0)
ssdb:hset("qyjh_xzt_tj_"..xzt_id,"js_tj",0)
ssdb:hset("qyjh_xzt_tj_"..xzt_id,"zy_tj",0)
ssdb:hset("qyjh_xzt_tj_"..xzt_id,"hd_tj",0)
--存储区域均衡下协作体数量开始

--******************陈续刚 2015.02.02添加
ssdb:hset("qyjh_xzt_tj",xzt_id.."_".."xx_tj",0)
ssdb:hset("qyjh_xzt_tj",xzt_id.."_".."js_tj",0)
ssdb:hset("qyjh_xzt_tj",xzt_id.."_".."zy_tj",0)
ssdb:hset("qyjh_xzt_tj",xzt_id.."_".."hd_tj",0)
--存储区域均衡下协作体数量开始
--[[local xztcount = ssdb:hget("qyjh_qyjh_tj_"..qyjh_id,"xzt_tj")
if not xztcount then
	xztcount = 0
end
xztcount = tonumber(xztcount[1])
ssdb:hset("qyjh_qyjh_tj_"..qyjh_id,"xzt_tj",xztcount+1)]]
ssdb:hincr("qyjh_qyjh_tj_"..qyjh_id,"xzt_tj", 1)
--存储区域均衡下协作体数量结束

--存储大学区下协作体数量开始
--[[local dxztcount = ssdb:hget("qyjh_dxq_tj_"..dxq_id,"xzt_tj")
if not dxztcount then
	dxztcount = 0
end
dxztcount = tonumber(dxztcount[1])
ssdb:hset("qyjh_dxq_tj_"..dxq_id,"xzt_tj",dxztcount+1)]]
ssdb:hincr("qyjh_dxq_tj_"..dxq_id,"xzt_tj", 1)
--存储大学区下协作体数量结束

--******************陈续刚 2015.02.02添加
--[[local dxztcount = ssdb:hget("qyjh_dxq_tj",dxq_id.."_".."xzt_tj")
if not dxztcount then
	dxztcount = 0
end
dxztcount = tonumber(dxztcount[1])
ssdb:hset("qyjh_dxq_tj",dxq_id.."_".."xzt_tj",dxztcount+1)]]
ssdb:hincr("qyjh_dxq_tj",dxq_id.."_".."xzt_tj", 1)
--存储大学区下协作体数量结束

say("{\"success\":true,\"xzt_id\":\""..xzt_id.."\",\"name\":\""..name.."\",\"info\":\"协作体创建成功！\"}")

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
