--[[
开通工作室
@Author  feiliming
@Date    2014-11-27
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

local region_id = args["region_id"]
local name = args["name"]
local description = args["description"]
local logo_url = args["logo_url"]
local level = args["level"]
if not region_id or string.len(region_id) == 0 
  or not name or string.len(name) == 0 
  or not description or string.len(description) == 0 
  or not logo_url or string.len(logo_url) == 0 
  or not level or string.len(level) == 0 then
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
local b, err = ssdb:hexists("workroom_region", region_id)
if not b then 
	say("{\"success\":false,\"info\":\""..err.."\"}")
	return
end
if b[1] == "1" then
	say("{\"success\":false,\"info\":\"已经开通！\"}")
	return
end

--base64
--description = ngx.encode_base64(description)
--name = ngx.encode_base64(name)

--取id
local workroom_id = ssdb:incr("workroom_pk")

--(1)地区工作室
local region = {}
region.workroom_id = workroom_id[1]
region.status = "1"

local ok, err = ssdb:hset("workroom_region", region_id, cjson.encode(region))
if not ok then
   say("{\"success\":false,\"info\":\""..err.."\"}")
   return
end

--(2)工作室
--学科
local subject = {}
subject[1] = {
	subject_id = "0",
	subject_name = "全部",
	teacher_num = 0
}
--学段
local stage = {}
stage[1] = {
	stage_id = "0",
	stage_name = "全部",
	teacher_num = 0,
	subject = subject
}
--工作室
local workroom = {}
workroom.workroom_id = workroom_id[1]
workroom.region_id = region_id
workroom.name = name
workroom.description = description
workroom.logo_url = logo_url
workroom.stage = stage
workroom.level = level

local ok, err = ssdb:hset("workroom_workrooms", workroom_id[1], cjson.encode(workroom))
if not ok then
   say("{\"success\":false,\"info\":\""..err.."\"}")
   return
end

--工作室区市省最新
local ts = os.date("%Y%m%d%H%M%S")
ssdb:zset("workroom_"..level.."_w_new", workroom_id[1], ts)
--工作室最新
ssdb:zset("workroom_0_w_new", workroom_id[1], ts)

--return
say("{\"success\":true,\"workroom_id\":\""..workroom_id[1].."\",\"name\":\""..name.."\",\"info\":\"开通成功！\"}")

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
