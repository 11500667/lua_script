--[[
根据教师id获取班级组树
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

local subject_id = args["subject_id"]
local teacher_id = ngx.var.cookie_person_id
--type为0时没有全部，为1时有全部
local type=args["type"]
--zy_id有作业id时，树上就显示有此作业的学生
local zy_id=args["zy_id"]
if not subject_id or string.len(subject_id) == 0 or not teacher_id or string.len(teacher_id) == 0 or not type or string.len(type)==0 then
	say("{\"success\":false,\"info\":\"参数错误！\"}")
	return
end


--查询出所有班级
local classes = ngx.location.capture("/dsideal_yy/base/getClassByTeacherIdSubjectId",{
        --args={teacher_id = teacher_id,subject_id=subject_id}
        body="teacher_id="..teacher_id.."&subject_id="..subject_id
})

local class
if classes.status == 200 then
	class = cjson.decode(classes.body).list
else
	say("{\"success\":false,\"info\":\"查询班级失败！\"}")
	return
end

--创建mysql连接
local mysql = require "resty.mysql"
local db = mysql:new()
db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024*1024
}

--创建ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local id=1
local parent
local tabs={}
if type == "1" then
	local tab1={}
	tab1["id"]="1"
	tab1["pId"]="-1"
	tab1["name"]="全部"
	tab1["open"]="true"
	tab1["title"]="全部"
	tab1["drag"]=false
	tabs[id]=tab1
	id=id+1
end

--循环班级
for i=1,#class do 
	if not #tabs then 
		parent=#tabs+1	
	else
		parent=1
	end	
	local tab={}
	tab["id"]=tostring(id)
	if type=="1" then
		tab["pId"]="1"
	else
		tab["pId"]="-1"
	end
	tab["class_id"]=class[i].class_id
	tab["name"]=class[i].class_name
	tab["open"]="true"
	tab["drag"]=false
	tabs[id]=tab
	tab["title"]=class[i].class_name
	parent=id
	id=id+1
	--查询出班级下哪些组
	local student_group,err = ssdb:hscan("homework_student_group_"..class[i].class_id.."_"..teacher_id.."_"..subject_id,'','',100)	

	if  not  student_group then

		say("{\"success\":false,\"info\":\"组查询失败！\"}")
		return
	end

	if student_group[1]~="ok" then
		--循环组
		for j=1,#student_group,2 do
			local studentpid=id
			local tab={}
                	tab["id"]=tostring(id)
                	tab["pId"]=parent
			tab["class_id"]=class[i].class_id
                	tab["group_id"]=student_group[j]
                	tab["name"]=ngx.decode_base64(student_group[j+1])
                	tab["open"]="true"
			tab["drag"]=false
			tab["title"]=ngx.decode_base64(student_group[j+1])
                	tabs[id]=tab
			id=id+1
			if zy_id then
				--查该作业下该组下的学生对应的关系表id
				local studentids=""
 	                	local counts = db:query("SELECT SQL_NO_CACHE id FROM t_zy_info_sphinxse  WHERE query=\'filter=ZY_ID,"..zy_id..";filter=GROUP_ID,"..student_group[j]..";limit=1000\'")
	                	for k=1,#counts do
                        		--sphinx查询的是关系id，这里查出学生id
	                        	local student= ssdb:multi_hget("homework_zy_student_relate_"..counts[k]["id"],"student_id")
	                        	--student_id=student[2]
	                        	if string.len(studentids)==0 then
	                                	studentids=student[2]
	                        	else
	                                	studentids=studentids..","..student[2]
	                        	end
	                	end
				if string.len(studentids)>0 then
					--用学生id去基础数据取学生信息
					local student = ngx.location.capture("/dsideal_yy/ypt/student/getStudntNameByID",{
						body="id="..studentids
						--args={id=studentids}
					})
					local person
				
					if student.status == 200 then
						person= cjson.decode(student.body).list
					else
						say("{\"success\":false,\"info\":\"查询学生失败！\"}")
						return
					end
					--say(cjson.encode(person))
					for m=1,#person do
						local tab={}
						tab["id"]=tostring(id)
						tab["pId"]=studentpid
						tab["student_id"]=person[m].studentID
						tab["name"]=person[m].studentName
						tab["title"]=person[m].studentName
						tab["drag"]=false
						tabs[id]=tab
						id=id+1
					end
				end
			end	
		end    	
 	end
end
local jsonData=cjson.encode(tabs)
say(jsonData)

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)

db:set_keepalive(0,v_pool_size)


