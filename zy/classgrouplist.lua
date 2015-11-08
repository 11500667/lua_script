--[[
留作业时获取班级组树
@Author chuzheng
@date 2014-12-21
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

local subject_id = args["subject_id"]
local teacher_id = ngx.var.cookie_person_id

if not subject_id or string.len(subject_id) == 0 or not teacher_id or string.len(teacher_id) == 0 then
        say("{\"success\":false,\"info\":\"参数错误！\"}")
        return
end

--查询出所有班级
local classes = ngx.location.capture("/dsideal_yy/base/getClassByTeacherIdSubjectId",{
        args={teacher_id = teacher_id,subject_id=subject_id}
	--body="teacher_id="..teacher_id.."&subject_id="..subject_id
})

local class
if classes.status == 200 then
        class = cjson.decode(classes.body).list
else
        say("{\"success\":false,\"info\":\"查询班级失败！\"}")
        return
end


--创建ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local parent
local tabs={}

for i=1,#class do
	local tabgroup={}
        if not #tabs then
                parent=#tabs+1
        else
                parent=1
        end
        local tab={}
        tab["class_id"]=class[i].class_id
        tab["class_name"]=class[i].class_name
        
        local student_group,err = ssdb:hscan("homework_student_group_"..class[i].class_id.."_"..teacher_id.."_"..subject_id,'','',100)

        if  not  student_group then

                say("{\"success\":false,\"info\":\"组查询失败！\"}")
                return
        end

        if student_group[1]~="ok" then
		local id=1
                for j=1,#student_group,2 do
                       	
			local tabg={}
                        tabg["group_id"]=student_group[j]
                        tabg["group_name"]=ngx.decode_base64(student_group[j+1])
                        tabgroup[id]=tabg
			id=id+1

                end
		
        end
	--local jsongroup=cjson.encode(tabgroup)
	
	tab["group_list"]=tabgroup
	tabs[i]=tab
end
local jsonData=cjson.encode(tabs)
say(jsonData)

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
