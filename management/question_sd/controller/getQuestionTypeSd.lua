
-- -----------------------------------------------------------------------------------
-- 描述：试题后台管理 -> 查询试题类型
-- 作者：刘全锋
-- 日期：2015年8月25日
-- -----------------------------------------------------------------------------------

local cookie_subject_id = tostring(ngx.var.cookie_background_subject_id)


--判断是否有subject_id的cookie信息
if cookie_subject_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"cookie_subject_id参数错误！\"}")
    return
end

--连接redis服务器
local CacheUtil = require "common.CacheUtil";
local cache = CacheUtil: getRedisConn();

local str_result=""

local qt_id_list = cache:smembers("qt_id_list_"..cookie_subject_id)
if #qt_id_list~=0 then
    for i=1,#qt_id_list do
    local qt_info = cache:hmget("qt_list_"..cookie_subject_id.."_"..qt_id_list[i],"qt_id","qt_name","qt_type","sort_id")
        str_result = str_result.."{\"qt_id\":\""..qt_info[1].."\",\"qt_name\":\""..qt_info[2].."\",\"qt_type\":\""..qt_info[3].."\",\"sort_id\":\""..qt_info[4].."\"},"
    end
end

str_result = string.sub(str_result,0,#str_result-1)

ngx.say("{\"success\":true,\"qt_list\":["..str_result.."]}")
