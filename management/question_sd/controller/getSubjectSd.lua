-- -----------------------------------------------------------------------------------
-- 描述：试题后台管理 -> 查询所有学科
-- 作者：刘全锋
-- 日期：2015年09月29日
-- -----------------------------------------------------------------------------------


--连接redis服务器
local CacheUtil = require "common.CacheUtil";
local cache = CacheUtil: getRedisConn();

local res,err = cache:get("xd_subject")
if not res then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end
ngx.say("{\"success\":\"true\","..res.."}")
