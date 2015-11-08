--[[
教师获取学生主观题答题列表
@Author chuzheng
@date 2015-1-8
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
local type = args["type"]

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
			local relate=ssdb:hget("homework_zy_relateidbystudentidzyid",zy_id.."_"..student_id)
			if string.len(relate[1])>0 then
				local flat=ssdb:multi_hget("homework_zy_student_relate_"..relate[1],"flat")
				if string.len(flat[1]) then
					if flat[2]~="0" then
						--say(flat[1])
						 studentids=student_id
					end
				end			
			end
	
	
			--local counts = db:query("SELECT SQL_NO_CACHE id FROM t_zy_info_sphinxse  WHERE query=\'filter=ZY_ID,"..zy_id..";filter=FLAT,1,2;filter=STUDENT_ID,"..student_id.."\'")
			--if table.getn(counts)>0 then
				--studentids=student_id
			--end
			--studentids=student_id
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
	--local person
	if student.status == 200 then
		person= cjson.decode(student.body).list
	else
		say("{\"success\":false,\"info\":\"查询学生失败！\"}")
		return
	end
end
local tabs={}
local flat=1
if person then
	for i=1,#person do
		--person[i].studentID
		--person[i].studentName
		
		--查询关联表id失败
		local relate = ssdb:hget("homework_zy_relateidbystudentidzyid",zy_id.."_"..person[i].studentID)
		if not relate then
			say("{\"success\":flase,\"info\":\"查询关系表id失败！\"}")
			return
		end
		--查询状态
		local flattype = ssdb:multi_hget("homework_zy_student_relate_"..relate[1],"flat")
		local isture="ture"
		if not type or string.len(type)==0 or type=="0" then
			isture="ture"
		else	
			if type==flattype[2] then
				isture="false"
			end
		end
		if isture=="ture" then
			
			--local resource_ids,err = ssdb:hscan("zy_zg_answer_"..person[i].studentID.."_"..zy_id,"","",200)
			--获得resoruce_ids res_id2id1,res_id2
			local ids=""
			--获得资源list:[{iid:"223","resource_name":"张三"}{iid:"224","resource_name":"李四"}]
			--图片的资源ID 主要为了图片RESOURE_ID的排序问题
			local img_resource_ids,err = ssdb:hscan("zy_zg_answer_img"..person[i].studentID.."_"..zy_id,"","",200)
			--不是图片的资源ID
			local noimg_resource_ids,err = ssdb:hscan("zy_zg_answer_noimg"..person[i].studentID.."_"..zy_id,"","",200)
			--获得resoruce_ids res_id2id1,res_id2
			--获得资源list:[{iid:"223","resource_name":"张三"}{iid:"224","resource_name":"李四"}]
			if img_resource_ids[1]~="ok" then
				for i=1,#img_resource_ids,2 do 
					if string.len(ids) ==0 then
						ids=img_resource_ids[i+1]
					else
						ids=ids..","..img_resource_ids[i+1]
					end	
				end
			end
			
			if noimg_resource_ids[1]~="ok" then
				for i=1,#noimg_resource_ids,2 do 
					if string.len(ids) ==0 then
						ids=noimg_resource_ids[i]
					else
						ids=ids..","..noimg_resource_ids[i]
					end	
				end
			end
			
			
			--获得学生上传所有图片答案的file_id
			--local zy_zg_answer_img_fids,err = ssdb:hscan("zy_zg_answer_img_fid"..person[i].studentID.."_"..zy_id,"","",200)
			local json={}
			if string.len(ids)>0 then
				local zy_answer_res = ngx.location.capture("/dsideal_yy/resource/getResourceInfoByInfoId",{
					args={resource_info_ids=ids}
				})
				if zy_answer_res.status == 200 then
					json = cjson.decode(zy_answer_res.body).list
				end
			end
			for j=1,#json do
				--注意：这部分可以不用
				-- local checkcontent = ""
				-- for i=1,#zy_zg_answer_img_fids,2 do
					-- if(zy_zg_answer_img_fids[i] == json[j].file_id){
						-- checkcontent = zy_zg_answer_img_fids[i+1]
					-- }
				-- end
				
				if not student_name or string.len(student_name)==0 then
					local tab={}
					tab["student_name"]=person[i].studentName
					tab["student_id"]=person[i].studentID
					tab["resource_info"]=json[j]
					tab["checkcontent"]=checkcontent
					tab["type"]=flattype[2]
					tabs[flat]=tab
					flat=flat+1
				else
					if ngx.decode_base64(student_name)==person[i].studentName then
						local tab={}
						tab["student_name"]=person[i].studentName
						tab["student_id"]=person[i].studentID
						tab["resource_info"]=json[j]
						tab["checkcontent"]=checkcontent
						tab["type"]=flattype[2]
						tabs[flat]=tab
						flat=flat+1
					end
				end
				
				
			end
			
			-- local subjective=ssdb:hscan("homework_answersubjective_"..person[i].studentID.."_"..zy_id,"","",50)
			-- if subjective[1]~="ok" then
				-- for j=1,#subjective,2 do
					-- if not student_name or string.len(student_name)==0 then
						-- local tab={}
						-- tab["student_name"]=person[i].studentName
						-- tab["student_id"]=person[i].studentID
						-- tab["file_id"]=ngx.encode_base64(subjective[j])
						-- tab["checkcontent"]=subjective[j+1]
						-- tab["type"]=flattype[2]
						-- tabs[flat]=tab
									-- flat=flat+1
					-- else
						-- if ngx.decode_base64(student_name)==person[i].studentName then
							-- local tab={}
							-- tab["student_name"]=person[i].studentName
							-- tab["student_id"]=person[i].studentID
							-- tab["file_id"]=ngx.encode_base64(subjective[j])
							-- tab["checkcontent"]=subjective[j+1]
							-- tab["type"]=flattype[2]
							-- tabs[flat]=tab
							-- flat=flat+1
						-- end
					-- end
				-- end
			-- end
		end
	end
end


local jsonData=cjson.encode(tabs)
local zylist,err=ssdb:hget("homework_zy_content",zy_id)
        if  not  zylist then
                        say("{\"success\":false,\"info\":\"组查询失败！\"}")
                        return
        end

local zycontent=zylist[1]
local zycon=cjson.decode(zycontent)

local zy_name=zycon.zy_name
say("{\"success\":true,\"zy_name\":\""..zy_name.."\",\"table_List\":"..jsonData.."}")
db:set_keepalive(0,v_pool_size)
ssdb:set_keepalive(0,v_pool_size)
