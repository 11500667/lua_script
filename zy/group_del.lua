--[[
@Author chuzheng
@date 2014-12-10
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
local subject_id = args["subject_id"]
if not teacher_id or string.len(teacher_id) == 0 or not class_id or string.len(class_id) == 0 or not group_id or string.len(group_id) == 0 or not subject_id or string.len(subject_id)==0  then
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

--删除组下面的学生信息




local students,err = ssdb:hscan("homework_studentbygroup_"..class_id.."_"..teacher_id.."_"..subject_id.."_"..group_id,"","",200)
if  not  students then
        say("{\"success\":false,\"info\":\"删除组下学生失败！\"}")
        return
end
if students[1]~="ok" then
        local groupname=""
        local i=1
        for j=1,#students,2 do
                --删除学生组对应的两个缓存        
		ssdb:hdel("homework_groupbystudent_"..class_id.."_"..students[j],teacher_id.."_"..subject_id)
                ssdb:hdel("homework_studentbygroup_"..class_id.."_"..teacher_id.."_"..subject_id.."_"..group_id,students[j])      
        end
end
        
--组信息保存到ssdb中

local group=ssdb:hget("homework_student_group_"..class_id.."_"..teacher_id.."_"..subject_id,group_id)
	ssdb:hset("homework_group_del",group_id,group[1])
--删除分组信息

ssdb:hdel("homework_student_group_"..class_id.."_"..teacher_id.."_"..subject_id,group_id)


say("{\"success\":true,\"info\":\"删除成功\"}")

ssdb:set_keepalive(0,v_pool_size)
