#ngx.header.content_type = "text/plain;charset=utf-8"
local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)

--第几页
local pageNumber = tostring(ngx.var.arg_pageNumber)
--判断是否有第几页的参数
if pageNumber == "nil" then
    ngx.say("{\"success\":false,\"info\":\"pageNumber参数错误！\"}")
    return
end
if pageNumber == "0" then
    pageNumber = "1"
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
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local offset = pageSize*pageNumber-pageSize
local limit = pageSize

local strResult = ""

local list_info = cache:zrevrangebyscore("paperlist_"..cookie_person_id,"+inf","-inf","limit",offset,limit)
for i=1,#list_info do
    local paper_info = cache:hmget("paperinfo_"..list_info[i],"paper_id","paper_name","stage_id","subject_id","stage_name","subject_name","question_count","create_time")
    local paper_list = "{\"paper_id\":\""..paper_info[1].."\",\"paper_name\":\""..paper_info[2].."\",\"stage_id\":\""..paper_info[3].."\",\"subject_id\":\""..paper_info[4].."\",\"stage_name\":\""..paper_info[5].."\",\"subject_name\":\""..paper_info[6].."\",\"ti_num\":\""..paper_info[7].."\",\"create_time\":\""..paper_info[8].."\"}"
    strResult = strResult..paper_list..","
end
strResult = string.sub(strResult,0,#strResult-1)

local totalRow = cache:zcount("paperlist_"..cookie_person_id,"-inf","+inf")
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

ngx.say("{\"success\":true,\"totalRow\":\""..totalRow.."\",\"totalPage\":\""..totalPage.."\",\"pageNumber\":\""..pageNumber.."\",\"pageSize\":\""..pageSize.."\",\"list\":["..strResult.."]}")

