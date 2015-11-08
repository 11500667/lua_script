#ngx.header.content_type = "text/plain;charset=utf-8"

--GroupID参数
local groupId = tostring(ngx.var.arg_groupId)
--判断是否有结点ID参数
if groupId == "nil" then
    ngx.say("{\"success\":false,\"info\":\"groupId参数错误！\"}")
    return
end

--第几页
local pageNumber = tostring(ngx.var.arg_pageNumber)
--判断是否有第几页的参数
if pageNumber == "nil" then
    ngx.say("{\"success\":false,\"info\":\"pageNumber参数错误！\"}")
    return
end

--一页显示多少
local pageSize = tostring(ngx.var.arg_pageSize)
--判断是否有一页显示多少条的参数
if pageSize == "nil" then
    ngx.say("{\"success\":false,\"info\":\"pageSize参数错误！\"}")
    return
end

--连接redis服务器
local redis = require "resty.redis"
local cache = redis.new()
local ok,err = cache.connect(cache,v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local totalRow = cache:zcount("MergeMember_"..groupId,"-inf","+inf")
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

local offset = pageSize*pageNumber-pageSize
local limit = pageSize

local ids = cache:zrangebyscore("MergeMember_"..groupId,"-inf","+inf","limit",offset,limit)


local result = ""

if #ids~=0 then
    for i=1,#ids do
	local str = "{\"id\":\"##\",\"name\":\"##\",\"member_category\":\"##\",\"member_type\":\"##\",\"org_id\":\"##\",\"org_name\":\"##\",\"bureau_name\":\"##\"}"
	local member_info = cache:hmget("MergeMemberInfo_"..groupId.."_"..ids[i],"id","name","member_category","member_type","org_id","org_name","bureau_name")
	if #member_info~=0 then
	    for j=1,#member_info do
		str = string.gsub(str,"##",member_info[j],1)
	    end
	end
	result = result..str..","
    end
end

result = string.sub(result,0,#result-1)

ngx.say("{\"success\": true,\"pageNumber\":\""..pageNumber.."\",\"pageSize\":\""..pageSize.."\",\"totalPage\":\""..totalPage.."\",\"totalRow\":\""..totalRow.."\",\"table_List\":["..result.."]}")
