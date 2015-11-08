
--[[
主观题信息及批阅情况
@Author chuzheng
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

if not zy_id or string.len(zy_id)==0 then
        say("{\"success\":false,\"info\":\"参数错误！\"}")
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

--创建ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
local studentids=""
--查出所有要显示的学生
--判断有没有班级id，有班级id则查班下的
if class_id and string.len(class_id)>0 then
        --班查询
        local counts = db:query("SELECT SQL_NO_CACHE id FROM t_zy_info_sphinxse  WHERE query=\'filter=ZY_ID,"..zy_id..";filter=FLAT,1,2;filter=CLASS_ID,"..class_id..";limit=1000\'")
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
                local counts = db:query("SELECT SQL_NO_CACHE id FROM t_zy_info_sphinxse  WHERE query=\'filter=ZY_ID,"..zy_id..";filter=FLAT,1,2;filter=GROUP_ID,"..group_id..";limit=1000\'")
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
                        studentids=student_id
                else
                        --什么都没有的就参数错误
                        say("{\"success\":false,\"info\":\"参数错误！\"}")
                        return
                end
        end
end
--查出所有要显示的学生id结束
--开始查学生了--小不点
local student = ngx.location.capture("/dsideal_yy/ypt/student/getStudntNameByID",
{
        --body="id="..studentids
        args={id=studentids}
})
local person
if student.status == 200 then
        person= cjson.decode(student.body).list
else
        say("{\"success\":false,\"info\":\"查询学生失败！\"}")
        return
end

--local flat=1
local tabssss={}
local tabsss={}
local title
--查作业名称
local zylist,err=ssdb:hget("homework_zy_content",zy_id)
        if  not  zylist then
			say("{\"success\":false,\"info\":\"组查询失败！\"}")
			return
	end
	if string.len(zylist[1])>0 then
		local zycontent=zylist[1]
				
		local zycon=cjson.decode(zycontent)
		title=zycon.zy_name
	end

tabssss["success"]=true
tabssss["title"]=title
local n=1
if person then
for i=1,#person do
        --person[i].studentID
        --person[i].studentName
	local tabss={}
	local tabs={}
	tabss["class_name"]=person[i].className
	tabss["student_id"]=person[i].studentID
	tabss["student_name"]=person[i].studentName

        local subjective=ssdb:hscan("homework_answersubjective_"..person[i].studentID.."_"..zy_id,"","",50)
        if not subjective then
                say("{\"success\":false,\"info\":\"组下学生查询失败！\"}")
                return
        end
        if subjective[1]~="ok" then
		local flat=1 
               for j=1,#subjective,2 do
			--local flat=1
                        if not student_name or string.len(student_name)==0 then
                                local tab={}
                                --tab["student_name"]=person[i].studentName
                                --tab["student_id"]=person[i].studentID
                                tab["file_id"]=ngx.encode_base64(subjective[j])
				tab["checkcontent"]=subjective[j+1]
                                tabs[flat]=tab
                                flat=flat+1
                        else
                                if ngx.decode_base64(student_name)==person[i].studentName then
                                        local tab={}
                                  --      tab["student_name"]=person[i].studentName
                                    --    tab["student_id"]=person[i].studentID
                                        tab["file_id"]=ngx.encode_base64(subjective[j])
                                        tabs[flat]=tab
                                        flat=flat+1
                                end
                        end
                end
        end
	if table.getn(tabs)>0 then
		tabss["list"]=tabs
	
		tabsss[n]=tabss
		n=n+1
	end

end
tabssss["list"]=tabsss
end
local jsonData=cjson.encode(tabssss)
say(jsonData)
db:set_keepalive(0,v_pool_size)
ssdb:set_keepalive(0,v_pool_size)
