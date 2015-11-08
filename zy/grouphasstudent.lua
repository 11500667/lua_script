--[[
判断组下是否有学生
@Author chuzheng
@date 2014-12-18
--]]
local say = ngx.say
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


local class_id = args["class_id"]
local group_id = args["group_id"]
local subject_id = args["subject_id"]
local teacher_id = ngx.var.cookie_person_id

if not class_id or string.len(class_id)==0 or not group_id or string.len(group_id)==0 or  not subject_id or string.len(subject_id) == 0 or not teacher_id or string.len(teacher_id) == 0 then
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


--查询组下学生，没值就是没人
local students,err = ssdb:hscan("homework_studentbygroup_"..class_id.."_"..teacher_id.."_"..subject_id.."_"..group_id,"","",200)
        if  not  students then
                say("{\"success\":false,\"info\":\"组下学生查询失败！\"}")
                return
        end

        if students[1]=="ok" then
		say("{\"success\":\"0\",\"info\":\"没有人！\"}")
		return
	else
		say("{\"success\":\"1\",\"info\":\"有人！\"}")
                return
	end

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
