local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--获取工作室ID
if args["workroom_id"] == nil or args["workroom_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"workroom_id参数错误！\"}")
    return
end
local workroom_id = args["workroom_id"]

--连接SSDB
local ssdb = require "resty.ssdb"
local db = ssdb:new()
local ok, err = db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--共有名师+1
db:hincr("workroom_tj_"..workroom_id,"teacher_count") 

--更新记录统计json的TS值
local  tj_ts = math.random(1000000)..os.time()
db:set("workroom_tj_ts_"..workroom_id,tj_ts)

--放回到SSDB连接池
db:set_keepalive(0,v_pool_size)

ngx.say("{\"success\":ture}")