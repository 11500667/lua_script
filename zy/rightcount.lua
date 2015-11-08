--[[
做对题数统计
@Authorr chuzheng
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
if not teacher_id or string.len(teacher_id) == 0 or not class_id or string.len(class_id) == 0 or not group_id or string.len(group_id) == 0 or not subject_id or string.len(subject_id) == 0 or not zy_id or string.len(zy_id)==0 then
        say("{\"success\":false,\"info\":\"参数错误！\"}")
        return
end



--Split方法
local function Split(szFullString, szSeparator)
local nFindStartIndex = 1
local nSplitIndex = 1
local nSplitArray = {}
while true do
   local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)
   if not nFindLastIndex then
    nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))
    break
   end
   nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)
   nFindStartIndex = nFindLastIndex + string.len(szSeparator)
   nSplitIndex = nSplitIndex + 1
end
return nSplitArray
end



--创建ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
local studentids=""
local tabs={}
--学生大的json
local tab={}
--标记学生数
local flat=1
if class_id == "0" and group_id == "0" then
        --查询全部
	local count = ssdb:hscan("homework_count_right_"..zy_id,"","",100)
        if not count then
		say("{\"success\":false,\"info\":\"查询成绩失败！\"}")
		return
	end
	
	if count[1]~="ok" then
		for i=1,#count,2 do 
			--count[i]
			--count[i+1]
			local args=Split(count[i+1],",")
			tabs[count[i]]=table.getn(args)
			--say(studentids)
			local student = ngx.location.capture("/dsideal_yy/ypt/student/getStudntNameByID",
			{
        			--body="id="..count[i+1]
        			args={id=count[i+1]}
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
				la["NUM"]=count[i]
				la["STUDENTNAME"]=person[j].studentName
				tab[flat]=la
				flat=flat+1
			end
		end
		tabs["pCount"]=flat+19
		tabs["table_List"]=tab
		tabs["success"]=true
	else
		tabs["pCount"]=20
		tabs["success"]=true
	end
		
else
	if group_id=="0" then
                 --查询班级
		
		local count = ssdb:hscan("homework_count_right_"..zy_id.."_"..class_id,"","",100)
        	if not count then
                	say("{\"success\":false,\"info\":\"查询成绩失败！\"}")
                	return
        	end

        	if count[1]~="ok" then
                	for i=1,#count,2 do 
                        	--count[i]
                        	--count[i+1]
                        	local args=Split(count[i+1],",")
                        	tabs[count[i]]=table.getn(args)
                        	--say(studentids)
                        	local student = ngx.location.capture("/dsideal_yy/ypt/student/getStudntNameByID",
                        	{
                                	--body="id="..count[i+1]
                                	args={id=count[i+1]}
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
                                	la["NUM"]=count[i]
                                	la["STUDENTNAME"]=person[j].studentName
                                	tab[flat]=la
                                	flat=flat+1
                        	end
                	end
                	tabs["pCount"]=flat+19
                	tabs["table_List"]=tab
			tabs["success"]=true
        	else
                	tabs["pCount"]=20
			tabs["success"]=true
        	end
        else
                 --查询组
		 local count = ssdb:hscan("homework_count_right_"..zy_id.."_"..class_id.."_"..group_id,"","",100)
                if not count then
                        say("{\"success\":false,\"info\":\"查询成绩失败！\"}")
                        return
                end

                if count[1]~="ok" then
                        for i=1,#count,2 do
                                --count[i]
                                --count[i+1]
                                local args=Split(count[i+1],",")
                                tabs[count[i]]=table.getn(args)
                                --say(studentids)
                                local student = ngx.location.capture("/dsideal_yy/ypt/student/getStudntNameByID",
                                {
                                        --body="id="..count[i+1]
                                        args={id=count[i+1]}
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
                                        la["NUM"]=count[i]
                                        la["STUDENTNAME"]=person[j].studentName
                                        tab[flat]=la
                                        flat=flat+1
                                end
                        end
                        tabs["pCount"]=flat+19
                        tabs["table_List"]=tab
			tabs["success"]=true
                else
                        tabs["pCount"]=20
			tabs["success"]=true
                end
        end

end
cjson.encode_empty_table_as_object(false)
local jsonData=cjson.encode(tabs)

say(jsonData)
ssdb:set_keepalive(0,v_pool_size)
