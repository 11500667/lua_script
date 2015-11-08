--[[
每道题的统计按答案进行统计
@Author chuzheng
@date 2015-1-7
--]]
local say = ngx.say

local cjson = require "cjson"
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
local zy_id = args["zy_id"]
local question_id_char=args["question_id_char"]
if not teacher_id or string.len(teacher_id) == 0 or not class_id or string.len(class_id) == 0 or not group_id or string.len(group_id) == 0 or not subject_id or string.len(subject_id) == 0 or not zy_id or string.len(zy_id)==0 or not question_id_char or string.len(question_id_char)==0 then
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

--取ssdb中作业的信息
local str=ssdb:hget("homework_zy_content",zy_id)
if string.len(str[1])==0 then
        say("{\"success\":false,\"info\":\"读取作业信息失败！\"}")
        return
end

local param = cjson.decode(str[1])

local tabs={}
local answer={}
local persons={}
if class_id == "0" and group_id == "0" then
        --查询全部
	tabs["success"]=true
	tabs["charID"]=question_id_char
	for i=1,#(param.kg) do
                if tonumber((param.kg)[i].question_id_char)== tonumber(question_id_char) then
                        
                           tabs["right"]=(param.kg)[i].question_answer
                end
        end        
	--获取这题的所有答题结果
	local answerperson = ssdb:hscan("homework_count_answerperson_byzyid_"..zy_id.."_"..question_id_char,"","",30)
	if not answerperson then
		say("{\"success\":false,\"info\":\"查询题答题结果失败！\"}")
                return
	end
	if answerperson[1]~="ok" then
		local flat=1
		local flat1=1
		for i=1,#answerperson,2 do
			local tab={}
			tab["ANSWER"]=answerperson[i]
			local args=Split(answerperson[i+1],",")
                        tab["NUM"]=table.getn(args)
			answer[flat]=tab	
			flat=flat+1	
			--获取人员信息	
			local student = ngx.location.capture("/dsideal_yy/ypt/student/getStudntNameByID",
                	{
                        	--body="id="..count[i+1]
                        	args={id=answerperson[i+1]}
                	})
                	local person
                	if student.status == 200 then
                        	person= cjson.decode(student.body).list
                	else
                        	say("{\"success\":false,\"info\":\"查询学生失败！\"}")
                        	return
                	end
                	for j=1,#person do 
                        	local la={}
                        	la["CLASSNAME"]=person[j].className
				la["ANSWER"]=answerperson[i]
                        	la["STUDENTNAME"]=person[j].studentName
                        	persons[flat1]=la
                        	flat1=flat1+1
                	end
		end
	end
	
else
        if group_id=="0" then
                 --查询班级
        	 tabs["success"]=true
        	tabs["charID"]=question_id_char
        	for i=1,#(param.kg) do
                	if tonumber((param.kg)[i].question_id_char)== tonumber(question_id_char) then

                         	  tabs["right"]=(param.kg)[i].question_answer
                	end
        	end
        	--获取这题的所有答题结果
        	local answerperson = ssdb:hscan("homework_count_answerperson_byclassid_"..class_id.."_"..zy_id.."_"..question_id_char,"","",30)
        	if not answerperson then
                	say("{\"success\":false,\"info\":\"查询题答题结果失败！\"}")
                	return
        	end
        	if answerperson[1]~="ok" then
                	local flat=1
                	local flat1=1
                	for i=1,#answerperson,2 do
                        	local tab={}
                        	tab["ANSWER"]=answerperson[i]
                        	local args=Split(answerperson[i+1],",")
                        	tab["NUM"]=table.getn(args)
                        	answer[flat]=tab
				flat=flat+1
                        	--获取人员信息
                        	local student = ngx.location.capture("/dsideal_yy/ypt/student/getStudntNameByID",
                        	{
                                	--body="id="..count[i+1]
                                	args={id=answerperson[i+1]}
                        	})
                        	local person
                        	if student.status == 200 then
                                	person= cjson.decode(student.body).list
                        	else
                                	say("{\"success\":false,\"info\":\"查询学生失败！\"}")
                                	return
                        	end
                        	for j=1,#person do
                                	local la={}
                                	la["CLASSNAME"]=person[j].className
                                	la["ANSWER"]=answerperson[i]
                                	la["STUDENTNAME"]=person[j].studentName
                                	persons[flat1]=la
                                	flat1=flat1+1
                        	end
                	end
       		 end
	
	
	else
                 --查询组
		tabs["success"]=true
                tabs["charID"]=question_id_char
                for i=1,#(param.kg) do
                        if tonumber((param.kg)[i].question_id_char)== tonumber(question_id_char) then

                                  tabs["right"]=(param.kg)[i].question_answer
                        end
                end
                --获取这题的所有答题结果
                local answerperson = ssdb:hscan("homework_count_answerperson_bygroupid_"..group_id.."_"..zy_id.."_"..question_id_char,"","",30)
                if not answerperson then
                        say("{\"success\":false,\"info\":\"查询题答题结果失败！\"}")
                        return
                end
                --say(answerperson[1])
		if answerperson[1]~="ok" then
                        local flat=1
                        local flat1=1
                        for i=1,#answerperson,2 do
                                local tab={}
                                tab["ANSWER"]=answerperson[i]
                                local args=Split(answerperson[i+1],",")
                                tab["NUM"]=table.getn(args)
                                answer[flat]=tab
				flat=flat+1
                                --获取人员信息
                                local student = ngx.location.capture("/dsideal_yy/ypt/student/getStudntNameByID",
                                {
                                        --body="id="..count[i+1]
                                        args={id=answerperson[i+1]}
                                })
                                local person
                                if student.status == 200 then
                                        person= cjson.decode(student.body).list
                                else
                                        say("{\"success\":false,\"info\":\"查询学生失败！\"}")
                                        return
                                end
                                for j=1,#person do
                                        local la={}
                                        la["CLASSNAME"]=person[j].className
                                        la["ANSWER"]=answerperson[i]
                                        la["STUDENTNAME"]=person[j].studentName
                                        persons[flat1]=la
                                        flat1=flat1+1
                                end
                        end
                 end
		


        end

end
tabs["info_List"]=persons
tabs["table_List"]=answer
local jsonData=cjson.encode(tabs)
say(jsonData)
ssdb:set_keepalive(0,v_pool_size)
