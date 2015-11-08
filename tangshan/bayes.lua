local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--资源的resource_id_int
if args["resource_id_int"] == nil or args["resource_id_int"] == "" then
    ngx.say("{\"success\":false,\"info\":\"resource_id_int参数错误！\"}")
    return
end
local resource_id_int = args["resource_id_int"]

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--基准票数
local standard_score = 3

--获取单个资源的总分和评分次数
local s_resource_info = ssdb_db:multi_hget("resource_score_"..resource_id_int,"total_score","total_count")
local s_total_score = s_resource_info[2]
local s_total_count = s_resource_info[4]

--所资源的资源总数和评分总分
local a_resource_info = ssdb_db:multi_hget("resource_score_all","resource_count","total_score")
local a_resource_count = a_resource_info[2]
local a_total_score = a_resource_info[4]

--计算贝叶斯得分
local bayes_score = s_total_score/(s_total_score+standard_score)*(s_total_score/s_total_count)+standard_score/(s_total_score+standard_score)*(a_total_score/a_resource_count)
local bayes = string.format("%6f",bayes_score)*1000000

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)

ngx.print(bayes)
