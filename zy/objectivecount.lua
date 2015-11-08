--[[
客观题统计客观题答题情况
@Author chuzheng
@date 2015-1-6
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
--连接数据库
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
if class_id == "0" and group_id == "0" then
	--查询全部
	local counts = db:query("SELECT SQL_NO_CACHE id FROM t_zy_info_sphinxse  WHERE query=\'filter=ZY_ID,"..zy_id..";limit=1000\'")
	for i=1,#counts do
		--sphinx查询的是关系id，这里查出作业id
		local student= ssdb:multi_hget("homework_zy_student_relate_"..counts[i]["id"],"student_id")
		--student_id=student[2]
		if string.len(studentids)==0 then
			studentids=student[2]
		else
			studentids=studentids..","..student[2]
		end
	end
		
else
	if group_id=="0" then
		 --查询班级
        	local counts = db:query("SELECT SQL_NO_CACHE id FROM t_zy_info_sphinxse  WHERE query=\'filter=ZY_ID,"..zy_id..";filter=CLASS_ID,"..class_id..";limit=1000\'")
        	for i=1,#counts do
                	--sphinx查询的是关系id，这里查出作业id  
                	local student= ssdb:multi_hget("homework_zy_student_relate_"..counts[i]["id"],"student_id")
                	--student_id=student[2]
                	if string.len(studentids)==0 then
                        	studentids=student[2]
                	else
                        	studentids=studentids..","..student[2]
                	end
        	end     
	else
		 --查询组
                local counts = db:query("SELECT SQL_NO_CACHE id FROM t_zy_info_sphinxse  WHERE query=\'filter=ZY_ID,"..zy_id..";filter=GROUP_ID,"..group_id..";limit=1000\'")
                for i=1,#counts do
                        --sphinx查询的是关系id，这里查出作业id
                        local student= ssdb:multi_hget("homework_zy_student_relate_"..counts[i]["id"],"student_id")
                        --student_id=student[2]
                        if string.len(studentids)==0 then
                                studentids=student[2]
                        else
                                studentids=studentids..","..student[2]
                        end
                end	
	end

end
--say(studentids)
local student = ngx.location.capture("/dsideal_yy/ypt/student/getStudntNameByID",
{
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
local tabs={}
local tabsfalse={}
if  person then
local trues=1
local falses=1

for i=1,#person do
	--person[i]
	local groupname=""
	local tab={}
	--local groupid,err = ssdb:hget("homework_groupbystudent_"..person[i].classID.."_"..person[i].studentID,teacher_id.."_"..subject_id)
	--if  not  groupid then
	--	say("{\"success\":false,\"info\":\"组查询失败！\"}")
	--	return
	--end
	--通过学生id查出关系表id，再查出留作业时的组id
	local relate,err =  ssdb:hget("homework_zy_relateidbystudentidzyid",zy_id.."_"..person[i].studentID)	
	if not relate then
		say("{\"success\":false,\"info\":\"关系表id查询失败！\"}")
		return
	end
	if string.len(relate[1])>0 then
		local groupid= ssdb:multi_hget("homework_zy_student_relate_"..relate[1],"group_id")
                --student_id=student[2]
        	if string.len(groupid[2])>0  then
			groupid=groupid[2]
			local groupnames,err=ssdb:hget("homework_student_group_"..person[i].classID.."_"..teacher_id.."_"..subject_id,groupid)
			if  not  groupnames then
				say("{\"success\":false,\"info\":\"组查询失败！\"}")
				return
			end
			if string.len(groupnames[1])>0 then
				groupname=groupnames[1]
			else
                        	local groupnamedel=ssdb:hget("homework_group_del",groupid)
                        	groupname=groupnamedel[1]
			end
            
		end
	end
	--say(tostring(person[i].studentID))
	local flat=tostring(person[i].studentID)
	local truefalses = ssdb:hget("homework_count_student_"..zy_id,flat)
	local truefalse = truefalses[1]
	local truecount = 0
	local falsecount = 0
	--say(truefalse)
	if string.len(truefalse)>0 then	
        	local sids=Split(truefalse,"_")
		truecount=sids[1]
		falsecount=sids[2]
		tab["group_name"]=ngx.decode_base64(groupname)
        	tab["student_name"]=person[i].studentName
        	tab["class_name"]=person[i].className
		tab["truecount"]=truecount
        	tab["falsecount"]=falsecount
        	tabs[trues]=tab
		trues=trues+1
	else
		tab["group_name"]=ngx.decode_base64(groupname)
                tab["student_name"]=person[i].studentName
                tab["class_name"]=person[i].className
                tab["truecount"]=truecount
                tab["falsecount"]=falsecount
                tabsfalse[falses]=tab
		falses=falses+1
	end

end
end
local jsonData=cjson.encode(tabs)
local jsonDatafalse=cjson.encode(tabsfalse)
say("{\"success\": \"true\",\"table_List\":"..jsonData..",\"table_false_List\":"..jsonDatafalse.."}")
db:set_keepalive(0,v_pool_size)
ssdb:set_keepalive(0,v_pool_size)
