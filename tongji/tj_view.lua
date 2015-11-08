local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--获取上传的类型  1：资源  3：试卷  2：试题  4：备课   5：微课
if args["type_id"] == nil or args["type_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"type_id参数错误！\"}")
    return
end
local type_id = args["type_id"]

--连接redis服务器
local redis = require "resty.redis"
local redis_db = redis:new()
local ok,err = redis_db:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local type_name = ""
if type_id == "1" then
    type_name = "zy"
    local person_id = tostring(ngx.var.cookie_person_id)
    local bureau_id = redis_db:hget("person_"..person_id.."_5","xiao")
    ngx.location.capture("/dsideal_yy/new_djmh/setViewCount?bureau_id="..bureau_id.."&random="..math.random(1000))
elseif type_id=="2" then
    type_name = "st"
elseif type_id=="3" then
    type_name = "sj"
elseif type_id=="4" then
    type_name = "bk"
else
    type_name = "wk"
end

--连接SSDB
local ssdb = require "resty.ssdb"
local db = ssdb:new()
local ok, err = db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--云平台门户
db:init_pipeline()
--统计信息
db:hincr("tj_"..type_name.."_all","view_count") --总浏览数
--今日统计
local today = os.date("%Y%m%d")
db:hincr("tj_"..type_name.."_today".."_"..today,"view_count") --今天浏览数
--设置今日统计的过期时间
db:expire("tj_"..type_name.."_today".."_"..today,"172800")
local results, err = db:commit_pipeline()
if not results then  
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--更新记录统计json的TS值
local  tj_ts = math.random(1000000)..os.time()
db:set("tj_ts",tj_ts)
db:set("tj_today",today)

--放回到SSDB连接池
db:set_keepalive(0,v_pool_size)
redis_db:set_keepalive(0,v_pool_size)

ngx.say("{\"success\":ture}")
