#ngx.header.content_type = "text/plain;charset=utf-8"
local cookie_person_id = tostring(ngx.var.cookie_person_id)
--判断是否有person_id的cookie信息
if cookie_person_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"没有Cookie参数person_id！\"}")
    return
end

local groupId = tostring(ngx.var.arg_groupId)
--判断是否有groupId参数
if groupId == "nil" then
    ngx.say("{\"success\":false,\"info\":\"没有groupId参数！\"}")
    return
end

local orgId = tostring(ngx.var.arg_orgId)
--判断是否有orgId参数
if orgId == "nil" then
    ngx.say("{\"success\":false,\"info\":\"没有orgId参数！\"}")
    return
end


