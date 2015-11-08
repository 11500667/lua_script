--[[
获取客观题列表
@Authorr chuzheng
@date 2015-1-9
--]]
local say = ngx.say

--引用模块
local ssdblib = require "resty.ssdb"

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

local teacher_id = ngx.var.cookie_person_id
local class_id = args["class_id"]
local group_id = args["group_id"]
local student_id = args["student_id"]
local zy_id = args["zy_id"]
local student_name = args["student_name"]
local subject_id = args["subject_id"]



if not zy_id or string.len(zy_id)==0 or not subject_id or string.len(subject_id)==0 then
        say("{\"success\":false,\"info\":\"参数错误！\"}")
        return
end


--第几页
local pageNumber = args["pageNumber"]
--一页显示多少
local pageSize = args["pageSize"]
--判断是否有第几页的参数
if not pageNumber or string.len(pageNumber)==0 then
    ngx.say("{\"success\":\"false\",\"info\":\"pageNumber参数错误！\"}")
    return
end
if pageNumber == "0" then
    pageNumber = "1"
end
--判断是否有一页显示多少条的参数
if not pageSize or string.len(pageSize)==0 then
    ngx.say("{\"success\":\"false\",\"info\":\"参数错误！\"}")
    return
end

local offset = pageSize*pageNumber-pageSize
local limit = pageSize
local str_maxmatches = pageNumber*100



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

--创建ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
local studentids=""
local totalRaw
local totalPage
--查出所有要显示的学生
--判断有没有班级id，有班级id则查班下的
if class_id and string.len(class_id)>0 then
        --班查询
        local counts = db:query("SELECT SQL_NO_CACHE id FROM t_zy_info_sphinxse  WHERE query=\'filter=ZY_ID,"..zy_id..";filter=FLAT,1,2,3;filter=CLASS_ID,"..class_id..";maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")
	--status中截取总个数
	local zy1 = db:read_result()
	--ngx.say(zy1[1]["Status"])
	local _,s_str = string.find(zy1[1]["Status"],"found: ")
	local e_str = string.find(zy1[1]["Status"],", time:")
	totalRow = string.sub(zy1[1]["Status"],s_str+1,e_str-1)
	totalPage = math.floor((totalRow+pageSize-1)/pageSize)
        
	for i=1,#counts do
                --sphinx查询的是关系id，这里查出学生id 
                local student= ssdb:multi_hget("homework_zy_student_relate_"..counts[i]["id"],"student_id")
                --student_id=student[2】
                if string.len(studentids)==0 then
                        studentids=student[2]
                else
                        studentids=studentids..","..student[2]
                end
        end 

else
        --判断有没有组id，有组id的则查询组
        if group_id and string.len(group_id)>0 then
                local counts = db:query("SELECT SQL_NO_CACHE id FROM t_zy_info_sphinxse  WHERE query=\'filter=ZY_ID,"..zy_id..";filter=FLAT,1,2,3;filter=GROUP_ID,"..group_id..";maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")
		 --status中截取总个数
        	local zy1 = db:read_result()
        	--ngx.say(zy1[1]["Status"])
        	local _,s_str = string.find(zy1[1]["Status"],"found: ")
        	local e_str = string.find(zy1[1]["Status"],", time:")
        	totalRow = string.sub(zy1[1]["Status"],s_str+1,e_str-1)
        	totalPage = math.floor((totalRow+pageSize-1)/pageSize)
                for i=1,#counts do
                        --sphinx查询的是关系id，这里查出学生id
                        local student= ssdb:multi_hget("homework_zy_student_relate_"..counts[i]["id"],"student_id")
                        if string.len(studentids)==0 then
                                studentids=student[2]
                        else
                                studentids=studentids..","..student[2]
                        end
                end
        else
                --判断有没有学生，有学生id则查询学生
                if student_id and string.len(student_id)>0 then

			local relate=ssdb:hget("homework_zy_relateidbystudentidzyid",zy_id.."_"..student_id)
                        if string.len(relate[1])>0 then
                                local flat=ssdb:multi_hget("homework_zy_student_relate_"..relate[1],"flat")
                                if string.len(flat[1]) then
                                        if flat[2]~="0" then
                                                 studentids=student_id
						totalRow=1
						totalPage=1
                                        else
						totalRaw=0
						totalPage=0
					end
                                end
                        end


                        --local counts = db:query("SELECT SQL_NO_CACHE id FROM t_zy_info_sphinxse  WHERE query=\'filter=ZY_ID,"..zy_id..";filter=FLAT,1,2;filter=STUDENT_ID,"..student_id.."\'")
                        --if table.getn(counts)>0 then
                                --studentids=student_id
                        --end
                        --studentids=student_id


                	--totalRow =1
			--totalPage =1
		else
                        --什么都没有的就参数错误
                        say("{\"success\":false,\"info\":\"参数错误！\"}")
                        return
                end
        end
end
--查出所有要显示的学生id结束
--开始查学生了--小不点
local person
if string.len(studentids)>0 then
	local student = ngx.location.capture("/dsideal_yy/ypt/student/getStudntNameByID",
	{
        	--body="id="..studentids
        	args={id=studentids}
	})

	if student.status == 200 then
        	person= cjson.decode(student.body).list
	else
        	say("{\"success\":false,\"info\":\"查询学生失败！\"}")
        	return
	end
end
local tabs={}

if person then
local flat = 1
for i=1,#person do
	local tab={}
        --person[i].studentID
        --person[i].studentName
        --person[i].className
        --有组id直接取了
        local group_name=""
        if group_id and string.len(group_id)>0 then
                local groupnames,err=ssdb:hget("homework_student_group_"..person[i].classID.."_"..teacher_id.."_"..subject_id,group_id)
                if  not  groupnames then
                        say("{\"success\":false,\"info\":\"组查询失败！\"}")
                        return
                end
                if string.len(groupnames[1])>0 then
                        groupname=groupnames[1]
                else
			local groupnamedel=ssdb:hget("homework_group_del",group_id)
			groupname=groupnamedel[1]
		end
        else
                local relate,err =  ssdb:hget("homework_zy_relateidbystudentidzyid",zy_id.."_"..person[i].studentID)
                if not relate then
                        say("{\"success\":false,\"info\":\"关系表id查询失败！\"}")
                        return
                end
                if string.len(relate[1])>0 then
                        local groupid= ssdb:multi_hget("homework_zy_student_relate_"..relate[1],"group_id")
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
        end
        
        tab["student_id"]=person[i].studentID
        tab["student_name"]=person[i].studentName
        tab["class_name"]=person[i].className
        tab["group_name"]=ngx.decode_base64(groupname)
	if not student_name or string.len(student_name)==0 then	
		tabs[i]=tab
	else
		if ngx.decode_base64(student_name)==person[i].studentName then
                	tabs[flat]=tab
			totalRow=flat
			totalPage = math.floor((totalRow+pageSize-1)/pageSize)		
			flat=flat+1
		end	
	end
end
end

local result={}
result["success"]=true
result["totalRow"]=totalRow
result["totalPage"]=totalPage
result["pageNumber"]=pageNumber
result["pageSize"]=pageSize
result["list"]=tabs
local zylist,err=ssdb:hget("homework_zy_content",zy_id)
        if  not  zylist then
                        say("{\"success\":false,\"info\":\"组查询失败！\"}")
                        return
        end

local zycontent=zylist[1]
local zycon=cjson.decode(zycontent)

result["zy_name"]=zycon.zy_name

cjson.encode_empty_table_as_object(false)
local resultjson=cjson.encode(result)
ngx.say(resultjson)


db:set_keepalive(0,v_pool_size)
ssdb:set_keepalive(0,v_pool_size)
