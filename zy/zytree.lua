--[[
根据作业id获取树结构
@Author chuzheng
@date 2015-1-15
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

local teacher_id = ngx.var.cookie_person_id
--type为0时没有全部，为1时有全部
local type=args["type"]
--zy_id有作业id时，树上就显示有此作业的学生
local zy_id=args["zy_id"]
--学科id
local subject_id=args["subject_id"]
--是否有学生
local hasstudent=args["hasstudent"]
if not teacher_id or string.len(teacher_id) == 0 or not type or string.len(type)==0 or not subject_id or string.len(subject_id)==0 or not hasstudent or string.len(hasstudent)==0 then
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



local id = 1
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

local classids=""
--开始查班级
local counts = db:query("SELECT SQL_NO_CACHE id FROM t_zy_info_sphinxse  WHERE query=\'filter=ZY_ID,"..zy_id..";groupby=attr:CLASS_ID;groupsort=CLASS_ID asc;limit=1000\'")
for k=1,#counts do
    --sphinx查询的是关系id，这里查出班级id
    local class= ssdb:multi_hget("homework_zy_student_relate_"..counts[k]["id"],"class_id")
    if class[2]~="0" then 
	--查询出对应班级
        local classes = ngx.location.capture("/dsideal_yy/ypt/base/class/getClassInfoByID",{
                args={class_id = class[2]}
                --body="teacher_id="..teacher_id.."&subject_id="..subject_id
        })

        local class
        if classes.status == 200 then
                class = cjson.decode(classes.body).list

                local tab={}
                tab["id"]=class[1].class_id
                if type=="1" then
                        tab["pId"]="1"
                else
                        tab["pId"]="-1"
                end
                tab["class_id"]=class[1].class_id
                tab["name"]=class[1].class_name
                tab["open"]="true"
                tab["point_no"]="0"
		tab["drag"]=false
                tab["title"]=class[1].class_name
                tabs[id]=tab
                id=id+1

        else
                say("{\"success\":false,\"info\":\"查询班级失败！\"}")
                return
        end     
    end
end

--查组
local groupids=""
local groups = db:query("SELECT SQL_NO_CACHE id FROM t_zy_info_sphinxse  WHERE query=\'filter=ZY_ID,"..zy_id..";groupby=attr:GROUP_ID;groupsort=GROUP_ID asc;limit=1000\'")
for k=1,#groups do
    --sphinx查询的是关系id，这里查出班级id
    local group= ssdb:multi_hget("homework_zy_student_relate_"..groups[k]["id"],"class_id","group_id")
    if group[4]~="0" then 
	--开始加入组
	local groupname=""
	local groupnames,err=ssdb:hget("homework_student_group_"..group[2].."_"..teacher_id.."_"..subject_id,group[4])
	if  not  groupnames then
		say("{\"success\":false,\"info\":\"组查询失败！\"}")
		return
	end
	if string.len(groupnames[1])>0 then
		groupname=groupnames[1]
	else
		local groupnamedel=ssdb:hget("homework_group_del",group[4])
		groupname=groupnamedel[1]		
	end
	local tab={}
        tab["id"]= "2_" .. group[4]
        tab["pId"]=group[2]
        tab["class_id"]=group[2]
        tab["group_id"]=group[4]
        tab["name"]=ngx.decode_base64(groupname)
        tab["point_no"]="1"
		tab["drag"]=false
        tab["title"]=ngx.decode_base64(groupname)
        tabs[id]=tab
        id=id+1
    end
end

if hasstudent=="1" then
	local studentids=""
	local students = db:query("SELECT SQL_NO_CACHE id FROM t_zy_info_sphinxse  WHERE query=\'filter=ZY_ID,"..zy_id..";filter=FLAT,1,2,3;groupby=attr:STUDENT_ID;groupsort=STUDENT_ID asc;limit=1000\'")
	for k=1,#students do
   		 --sphinx查询的是关系id，这里查出学生id
    		local student= ssdb:multi_hget("homework_zy_student_relate_"..students[k]["id"],"group_id","student_id","class_id")
    		if student[4]~="0" then 
        		--开始加入组
        		local studentname=""
        		--用学生id去基础数据取学生信息
                        local studentid = ngx.location.capture("/dsideal_yy/ypt/student/getStudntNameByID",{
                                  --body="id="..studentids
                                  args={id=student[4]}
                        })
                        local person

                        if studentid.status == 200 then
                                  person= cjson.decode(studentid.body).list
                        else
                                  say("{\"success\":false,\"info\":\"查询学生失败！\"}")
                                  return
                        end
			
			local tab={}
        		tab["id"]="3_" .. student[4]
						
			if student[2]~="0" then
	        		
				tab["pId"]="2_" ..student[2]
			else
				
				tab["pId"]=student[6]	
			end
        		tab["student_id"]=student[4]
        		tab["group_id"]=student[2]
        		tab["name"]=person[1].studentName
        		tab["point_no"]="2"
				tab["drag"]=false
        		tab["title"]=person[1].studentName
        		tabs[id]=tab
        		id=id+1
    		end
	end
end


local jsonData=cjson.encode(tabs)
say(jsonData)

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
db:set_keepalive(0,v_pool_size)

