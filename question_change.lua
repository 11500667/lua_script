#ngx.header.content_type = "text/plain;charset=utf-8"
local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)

--判断是否有person_id的cookie信息
if cookie_person_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"person_id的cookie信息参数错误！\"}")
    return
end
--判断是否有identity_id的cookie信息
if cookie_identity_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"identity_id的cookie信息参数错误！\"}")
    return
end

local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

local structure_id = tostring(args["structure_id"])
local qt_id = tostring(args["qt_id"])
local ids = tostring(args["ids"])

--Split方法
local function Split(szFullString, szSeparator)
local nFindStartIndex = 1
local nSplitIndex = 1
local nSplitArray = {}
while true do
   local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)
   if not nFindLastIndex then
    nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))
    break
   end
   nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)
   nFindStartIndex = nFindLastIndex + string.len(szSeparator)
   nSplitIndex = nSplitIndex + 1
end
return nSplitArray
end

--连接redis服务器
local redis = require "resty.redis"
local cache = redis.new()
local ok,err = cache.connect(cache,v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--连接数据库
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

--时间戳
local ts = tostring(ngx.now()*1000)

local setA = cookie_person_id.."_"..ts.."_setA"
local setB = cookie_person_id.."_"..ts.."_setB"

--将前台传的ID存入一个临时的集合中
local sids = Split(ids,",")
for i=1,#sids do
   cache:sadd(setA,sids[i]) 
end

local res = db:query("SELECT id FROM t_tk_question_info_sphinxse WHERE query = 'filter=b_in_paper,0;filter=STRUCTURE_ID_INT,"..structure_id..";filter=QUESTION_TYPE_ID,"..qt_id..";maxmatches=100'")
--从数据库中查出的ID存入另一个临时的集合中
for i=1,#res do
    cache:sadd(setB,res[i]["id"])
end

--从数据库查出的ID和前台传的ID做差集
local sdiff = cache:sdiff(setB,setA)

--删除两个临时集合
cache:del(setB)
cache:del(setA)

if #sdiff ~= 0 then
    --从两个集合的差集里随机拿一个ID
    local q_id = sdiff[math.random(#sdiff)]
    local question_json = tostring(cache:hmget("question_"..q_id,"json_question")[1])
    ngx.say("{\"success\":true,\"id\":\""..q_id.."\",\"json_question\":"..ngx.decode_base64(question_json).."}")
else
    ngx.say("{\"success\":true,\"id\":\"\",\"json_question\":{}}")
end

