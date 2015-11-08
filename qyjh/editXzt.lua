--[[
保存编辑后的大学区
@Author  chenxg
@Date    2015-01-19
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
local xzt_id = args["xzt_id"]
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
if not xzt_id or string.len(xzt_id) == 0  
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

--base64
--description = ngx.decode_base64(description)
--name = ngx.decode_base64(name)

--存储详细信息
local hxzt = ssdb:hget("qyjh_xzt",xzt_id)
local xzt = cjson.decode(hxzt[1])
--删除原管理员
ssdb:hdel("qyjh_manager_xzts", xzt.person_id)
xzt.name = name
xzt.description = description
xzt.logo_url = logo_url
xzt.person_id = person_id
xzt.province_id = province_id
xzt.city_id = city_id
xzt.district_id = district_id
xzt.org_id = sch_id

local ok, err = ssdb:hset("qyjh_xzt", xzt_id, cjson.encode(xzt))
if not ok then
   say("{\"success\":false,\"info\":\""..err.."\"}")
   return
end
--ssdb:zset("qyjh_xztcount_"..qyjh_id, xzt_id, cjson.encode(qyjh_xzt))
ssdb:hset("qyjh_xzt_manager", xzt_id, person_id)
ssdb:hset("qyjh_manager_xzts", person_id, xzt_id)
--return
say("{\"success\":true,\"xzt_id\":\""..xzt_id.."\",\"name\":\""..name.."\",\"info\":\"协作体信息修改成功！\"}")

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
