--[[
统计发布到工作室的资源总数(包括资源、试卷、备课、微课)
发布的时候调用
@Author feiliming
@Date 2015-1-12
]]
local say = ngx.say
local len = string.len
local gsub = string.gsub

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

--获得请求参数
local addArray = ngx.unescape_uri(args["addArray"])
if not addArray or len(addArray) == 0 then
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

--插入发布
addArray = gsub(addArray, "[%[%]\" ]", "")
if addArray and len(addArray) > 0 then
	local add = Split(addArray, ",")
	for i=1,#add do
		--统计数加1
		ssdb:hincr("workroom_tj_all", "resource_count", 1)
	end
end

say("{\"success\":true,\"info\":\"发布成功！\"}")

--放回连接池
ssdb:set_keepalive(0,v_pool_size)