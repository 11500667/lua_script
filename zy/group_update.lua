--[[
@Author chuzheng
@date 2014-12-18
--]]
local say = ngx.say

--引用模块
local ssdblib = require "resty.ssdb"

--获取前台传过来的参数
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

local teacher_id = ngx.var.cookie_person_id
local class_id = args["class_id"]
local group_id = args["group_id"]
local group_name = args["group_name"]
local subject_id = args["subject_id"]

if not subject_id or string.len(subject_id) == 0 or not teacher_id or string.len(teacher_id) == 0 or not class_id or string.len(class_id) == 0 or not group_name or string.len(group_name) == 0 or not group_id or string.len(group_id) == 0 then
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

--更新分组信息

group_name=ngx.encode_base64(group_name)

ssdb:hset("homework_student_group_"..class_id.."_"..teacher_id.."_"..subject_id,group_id,group_name)



say("{\"success\":true,\"info\":\"更新成功\"}")

ssdb:set_keepalive(0,v_pool_size)
