--[[
作业提交
@Author chuzheng
@date 2014-12-30
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

local student_id = ngx.var.cookie_person_id
local zy_id = args["zy_id"]

local subject_id = args["subject_id"]
--say(zy_id)
--say(subject_id)

if not  zy_id or string.len(zy_id) == 0 or not subject_id or string.len(subject_id) == 0 then

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

--获取学生主观题答题信息
local subjective,err = ssdb:hscan("homework_answersubjective_"..student_id.."_"..zy_id,"","",100)
if not subjective then
    say("{\"success\":false,\"info\":\"学生答题查询失败！\"}")
    return
end
--获取关联表id
local relate = ssdb:hget("homework_zy_relateidbystudentidzyid",zy_id.."_"..student_id)

--获取时间戳ts
local t=ngx.now()
local n=os.date("%Y%m%d%H%M%S").."00"..string.sub(t,12,14)
n=n..string.rep("0",19-string.len(n))
local ts=n

--say(subjective[1].."1111")
if subjective[1]~="ok" then
	
	--主观题提交情况
	ssdb:incr("home_answersubjective_"..zy_id)
	--更改作业状态
	ssdb:multi_hset("homework_zy_student_relate_"..relate[1],"flat",1)
	--更改作业状态mysql
	local res, err, errno, sqlstate =db:query("update t_zy_zytostudent set FLAT=\'1\'  where ID="..relate[1])
        if not res then
                ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
                return
        end
else
	--更改作业状态
        ssdb:multi_hset("homework_zy_student_relate_"..relate[1],"flat",2)
        --更改作业状态mysql
	--ngx.say(relate[1].."---")
        local res, err, errno, sqlstate =db:query("update t_zy_zytostudent set FLAT=\'2\'  where ID="..relate[1])
        if not res then                
                ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")                
                return        
        end
end

local res, err, errno, sqlstate =db:query("update t_zy_info set UPDATE_TS=\'"..ts.."\'  where ID="..zy_id)
if not res then
       ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
       return
end


--获取学生主观题答题信息
--获取学生客观题答题信息
local answer,err = ssdb:hscan("homework_answer_"..student_id.."_"..zy_id,'','',100)

if  not  answer then
    say("{\"success\":false,\"info\":\"学生答题查询失败！\"}")
    return
end
if answer[1]~="ok" then
      --查询该学生属于哪个班级
   local persons = ngx.location.capture("/dsideal_yy/ypt/student/getStudntNameByID",
   {
        body="id="..student_id
   }
   )
   local person
   if persons.status == 200 then
       person = (cjson.decode(persons.body)).list
   else
       say("{\"success\":false,\"info\":\"学生信息查询失败！\"}")
       return
   end
   local class_id=person[1].classID
   --查询该学生属于哪个班级结束
   --查询该学生属于哪个组
   local groupids,err = ssdb:hscan("homework_groupbystudent_"..class_id.."_"..student_id,'','',20)
   if  not  groupids then
        say("{\"success\":false,\"info\":\"组查询失败！\"}")
        return
   end
   local group_id=""
   if groupids[1]~="ok" then
        for i=1,#groupids,2 do
                --将学生移除组
                --ssdb:hdel("homework_groupbystudent_"..class_id.."_"..student_id,groupids[i])
                --ssdb:hdel("homework_studentbygroup_"..class_id.."_"..teacher_id.."_"..subject_id.."_"..groupids[i+1],student_id)
                local subject = Split(groupids[i],"_")
                if subject[2]==subject_id then
                        group_id=groupids[i+1]
                end
        end
   end
   --查询该学生属于哪个组结束


   --作对题数
   local truecount=0
   --做错题数
   local falsecount=0
   for j=1,#answer,2 do
           local tabg={}
           local file_id=answer[j]
           local studentanswer=answer[j+1]
	   --分割学生的答案与正确答案
	   local sids = Split(studentanswer,"_")
	   --判断学生是否答错题
	   if sids[1] == sids[2] then
	   	truecount=truecount+1
	   else
	   	falsecount=falsecount+1
	        --学生答错题了开始处理
		--按全部学生统计
		ssdb:zincr("homework_count_false_byzyid_"..zy_id,file_id,1)
		--按班级学生统计
		ssdb:zincr("homework_count_false_byclassid_"..class_id.."_"..zy_id,file_id,1)
		--按组进行统计
		ssdb:zincr("homework_count_false_bygroupid_"..group_id.."_"..zy_id,file_id,1)
		--学生错题集
		local falsecollection = ssdb:incr("homework_falsecollection")
		ssdb:zset("homework_count_falsetostudent_"..subject_id.."_"..student_id,zy_id.."_"..file_id,falsecollection[1])
				
                --学生打错题了处理结束 
	   end	  
		--按全部统计回答这题一样答案的人             
		local falseperson = ssdb:hget("homework_count_answerperson_byzyid_"..zy_id.."_"..file_id,sids[1])
                if not falseperson then
                        say("{\"success\":false,\"info\":\"全部统计查询失败！\"}")
                        return
                end
                if string.len(falseperson[1])>0 then

                        ssdb:hset("homework_count_answerperson_byzyid_"..zy_id.."_"..file_id,sids[1],falseperson[1]..","..student_id)
                else
                        ssdb:hset("homework_count_answerperson_byzyid_"..zy_id.."_"..file_id,sids[1],student_id)
                end
                --按班统计回答这题一样答案的人
                local falseperson = ssdb:hget("homework_count_answerperson_byclassid_"..class_id.."_"..zy_id.."_"..file_id,sids[1])
                if not falseperson then
                        say("{\"success\":false,\"info\":\"查询错题题班级人失败\"}")
                        return
                end
                if string.len(falseperson[1])>0 then

                        ssdb:hset("homework_count_answerperson_byclassid_"..class_id.."_"..zy_id.."_"..file_id,sids[1],falseperson[1]..","..student_id)
                else
                        ssdb:hset("homework_count_answerperson_byclassid_"..class_id.."_"..zy_id.."_"..file_id,sids[1],student_id)
                end
                --按组统计回答这题一样答案的人
                local falseperson = ssdb:hget("homework_count_answerperson_bygroupid_"..group_id.."_"..zy_id.."_"..file_id,sids[1])
                if not falseperson then
                        say("{\"success\":false,\"info\":\"查询错题题组人失败\"}")
                        return
                end
                if string.len(falseperson[1])>0 then

                        ssdb:hset("homework_count_answerperson_bygroupid_"..group_id.."_"..zy_id.."_"..file_id,sids[1],falseperson[1]..","..student_id)
                else
                        ssdb:hset("homework_count_answerperson_bygroupid_"..group_id.."_"..zy_id.."_"..file_id,sids[1],student_id)
                end
	   
   end
   --ssdb:incr("homework_answer_submissionhomework_"..zy_id)
   ssdb:hset("homework_count_student_"..zy_id,student_id,truecount.."_"..falsecount)
   --做对题数统计(全部)开始
   local rightcount = ssdb:hget("homework_count_right_"..zy_id,truecount)
   if not rightcount then
	say("{\"success\":false,\"info\":\"全部统计查询失败！\"}")
        return
   end
   if string.len(rightcount[1])>0 then
	
   	ssdb:hset("homework_count_right_"..zy_id,truecount,rightcount[1]..","..student_id)
   else
	ssdb:hset("homework_count_right_"..zy_id,truecount,student_id)
   end	
	
   --做对题数统计（全部）结束   
   --做对题数统计（按班级）开始
   local rightcountclass = ssdb:hget("homework_count_right_"..zy_id.."_"..class_id,truecount) 
   if not rightcountclass then
        say("{\"success\":false,\"info\":\"按班级统计查询失败！\"}")                                                                    
        return                                                            
   end
   if string.len(rightcountclass[1])>0 then

        ssdb:hset("homework_count_right_"..zy_id.."_"..class_id,truecount,rightcountclass[1]..","..student_id)
   else
        ssdb:hset("homework_count_right_"..zy_id.."_"..class_id,truecount,student_id)
   end 

   --做对题数统计（按班）结束
   --作对题统计（ 按组）开始
   if string.len(group_id)>0 then
   	local rightcountgroup = ssdb:hget("homework_count_right_"..zy_id.."_"..class_id.."_"..group_id,truecount)
   	if not rightcountgroup then
        	say("{\"success\":false,\"info\":\"按组统计查询失败！\"}")
        	return
   	end
   	if string.len(rightcountgroup[1])>0 then

        	ssdb:hset("homework_count_right_"..zy_id.."_"..class_id.."_"..group_id,truecount,rightcountgroup[1]..","..student_id)
   	else
        	ssdb:hset("homework_count_right_"..zy_id.."_"..class_id.."_"..group_id,truecount,student_id)
   	end  
   end
   --做对题统计（按组）结束   
end
ssdb:incr("homework_answer_submissionhomework_"..zy_id)
say("{\"success\":true,\"info\":\"保存成功\"}")
db:set_keepalive(0,v_pool_size)
ssdb:set_keepalive(0,v_pool_size)
