--[[
学生分组的学生列表
@Author chuzheng
@data 2014-12-19
--]]

local say = ngx.say
--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

--判断request类型, 获得请求参数
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
if not subject_id or string.len(subject_id)==0 or not class_id or string.len(class_id)==0 then
	
	say("{\"success\":false,\"info\":\"参数错误！\"}")
	return

end

--ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
        say("{\"success\":false,\"info\":\""..err.."\"}")
        return
end

--查询组班级下所有组
local student_group,err = ssdb:hscan("homework_student_group_"..class_id.."_"..teacher_id.."_"..subject_id,'','',100)
if  not  student_group then
	say("{\"success\":false,\"info\":\"组查询失败！\"}")
	return
end

local id=0
local tabs1={}
--组信息列表
local grouplist="[]"
if student_group[1]~="ok" then
	for j=1,#student_group,2 do  
		local tab1={}
		tab1.group_id=student_group[j]
		tab1.group_name=ngx.decode_base64(student_group[j+1])
		id=id+1
		tabs1[id]=tab1
	end
	grouplist=cjson.encode(tabs1)
end

local tabs={}
if not group_id or string.len(group_id)==0 then
	local studentes = ngx.location.capture("/dsideal_yy/base/getStudentByClassId",{
        body="class_id="..class_id
	--args={class_id=class_id}
	})
	local student
	if studentes.status == 200 then
        student = cjson.decode(studentes.body).list
	else
		say("{\"success\":false,\"info\":\"查询班级下学生失败！\"}")
		return
	end
	--查询组信息
	for i=1,#student do
		local groupid=""
		local groupname=""
		local tab={}
		tab["person_id"]=student[i].student_id
		tab["person_name"]=student[i].student_name
 		local groupids,err = ssdb:hget("homework_groupbystudent_"..class_id.."_"..student[i].student_id,teacher_id.."_"..subject_id)
		if  not  groupids then
			say("{\"success\":false,\"info\":\"组查询失败！\"}")
			return
		end
		if string.len(groupids[1])>0 then
			groupid=groupids[1]    
			local groupnames,err=ssdb:hget("homework_student_group_"..class_id.."_"..teacher_id.."_"..subject_id,groupid)
			if  not  groupnames then
				say("{\"success\":false,\"info\":\"组查询失败！\"}")
				return
			end	
			if string.len(groupnames[1])>0 then
				groupname = groupnames[1]
			end
		end
		tab["class_id"]=class_id
		tab["group_id"]=groupid
		tab["group_name"]=ngx.decode_base64(groupname)
		tabs[i]=tab
	end
	local jsonData=cjson.encode(tabs)
	say("{\"success\": \"true\",\"table_List\":"..jsonData..",\"group_number\":\""..id.."\",\"group_List\":"..grouplist.."}")
else
	local students,err = ssdb:hscan("homework_studentbygroup_"..class_id.."_"..teacher_id.."_"..subject_id.."_"..group_id,"","",200)
	if  not  students then
		say("{\"success\":false,\"info\":\"组下学生查询失败！\"}")
		return
   	end
	if students[1]~="ok" then
		local groupname=""
		local i=1
        for j=1,#students,2 do
			local tab={}
			tab["class_id"]=class_id
			tab["group_id"]=group_id
			local groupid,err = ssdb:hget("homework_groupbystudent_"..class_id.."_"..students[j],teacher_id.."_"..subject_id)
			if  not  groupid then
				say("{\"success\":false,\"info\":\"组查询失败！\"}")
				return
			end
            if string.len(groupid[1])>0 and string.len(groupname)==0 then
				groupid=groupid[1]
				local groupnames,err=ssdb:hget("homework_student_group_"..class_id.."_"..teacher_id.."_"..subject_id,groupid)
				if  not  groupnames then
					say("{\"success\":false,\"info\":\"组查询失败！\"}")
					return
				end
				if string.len(groupnames[1])>0 then
					groupname=groupnames[1]
				end
            end
			tab["group_name"]=ngx.decode_base64(groupname)
			tab["person_id"]=students[j]
			local student = ngx.location.capture("/dsideal_yy/ypt/student/getStudntNameByID",
				{
					body="id="..students[j]
					--args={id=students[j]}
				})
			local person
			if student.status == 200 then
				person= cjson.decode(student.body).list
			else
				say("{\"success\":false,\"info\":\"查询班级失败！\"}")
				return
			end
			tab["person_name"]=person[1].studentName
			tabs[i]=tab
			i=i+1
		end
	end
	local jsonData=cjson.encode(tabs)	
	say("{\"success\": \"true\",\"table_List\":"..jsonData..",\"group_number\":\""..id.."\",\"group_List\":"..grouplist.."}")
end
--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
