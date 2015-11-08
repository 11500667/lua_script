--[[
删除学生
@Author cuijinlong
@date 2014-12-20
--]]
local say=ngx.say
--引用模块
local ssdblib=require "resty.ssdb"
local cjson = require "cjson"
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

--获取页面参数
local subject_id = args["subject_id"]
local class_id = args["class_id"]
local teacher_id = args["teacher_id"]
local student_id = args["student_id"]

if not class_id or string.len(class_id)==0  or  not subject_id or string.len(subject_id) == 0 or not student_id or string.len(student_id) == 0 or not teacher_id or string.len(teacher_id) == 0 then
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
--获得学生在班级下的分组
local groupids,err = ssdb:hscan("homework_groupbystudent_"..class_id.."_"..student_id,'','',100)
if  not  groupids then
	say("{\"success\":false,\"info\":\"组查询失败！\"}")
	return
end
if groupids[1]~="ok" then
	for i=1,#groupids,2 do
		--将学生移除组
		ssdb:hdel("homework_groupbystudent_"..class_id.."_"..student_id,groupids[i])
		ssdb:hdel("homework_studentbygroup_"..class_id.."_"..teacher_id.."_"..subject_id.."_"..groupids[i+1],student_id)
	end
end
--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)











