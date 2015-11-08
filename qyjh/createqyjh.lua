--[[
开通区域均衡
@Author  chenxg
@Date    2015-01-14
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
local region_id = args["region_id"]
local name = args["name"]
local description = args["description"]
local logo_url = args["logo_url"]

--从cookie获取当前用户的省市区ID
local cookie_province_id = tostring(ngx.var.cookie_background_province_id)
local cookie_city_id = tostring(ngx.var.cookie_background_city_id)
local cookie_district_id = tostring(ngx.var.cookie_background_district_id)

--判断参数是否为空
if not region_id or string.len(region_id) == 0 
  or not name or string.len(name) == 0 
  or not description or string.len(description) == 0 
  or not logo_url or string.len(logo_url) == 0 
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

--判断是否已经开通
local b, err = ssdb:hexists("qyjh_open", region_id)
if not b then 
	say("{\"success\":false,\"info\":\""..err.."\"}")
	return
end
if b[1] == "1" then
	say("{\"success\":false,\"info\":\"已经开通！\"}")
	return
end

--base64
--description = ngx.decode_base64(description)
--name = ngx.decode_base64(name)

--取id
--local qyjh_id = region_id;--ssdb:incr("workroom_pk")

--(1)存储开通信息
local region = {}
region.region_id = region_id
region.b_use = "1"

local ok, err = ssdb:hset("qyjh_open", region_id, cjson.encode(region))
if not ok then
   say("{\"success\":false,\"info\":\""..err.."\"}")
   return
end

local ts = os.date("%Y%m%d%H%M%S")
--存储详细信息
local qyjh = {}
qyjh.qyjh_id = region_id
qyjh.name = name
qyjh.description = description
qyjh.logo_url = logo_url
qyjh.b_open = 1
qyjh.b_use = 1
qyjh.createtime = ts
qyjh.province_id = cookie_province_id
qyjh.city_id = cookie_city_id
qyjh.district_id = cookie_district_id

local ok, err = ssdb:hset("qyjh_qyjhs", region_id, cjson.encode(qyjh))
if not ok then
   say("{\"success\":false,\"info\":\""..err.."\"}")
   return
end
--初始化统计信息开始
ssdb:hset("qyjh_qyjh_tj_"..region_id,"dxq_tj",0) 
ssdb:hset("qyjh_qyjh_tj_"..region_id,"xzt_tj",0)
--ssdb:hset("qyjh_qyjh_tj_"..region_id,"xx_tj",0)
--ssdb:hset("qyjh_qyjh_tj_"..region_id,"js_tj",0)
ssdb:hset("qyjh_qyjh_tj_"..region_id,"zy_tj",0)
ssdb:hset("qyjh_qyjh_tj_"..region_id,"hd_tj",0)
--初始化统计信息结束
ngx.location.capture("/dsideal_yy/qyjh/initTongJi?region_id="..region_id)
--return
say("{\"success\":true,\"qyjh_id\":\""..region_id.."\",\"name\":\""..name.."\",\"b_use\":1,\"info\":\"开通成功！\"}")

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
