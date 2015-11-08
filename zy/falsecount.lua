--[[
错题排行
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
if not teacher_id or string.len(teacher_id) == 0 or not class_id or string.len(class_id) == 0 or not group_id or string.len(group_id) == 0 or not subject_id or string.len(subject_id) == 0 or not zy_id or string.len(zy_id)==0 then
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
if class_id == "0" and group_id == "0" then
        --查询全部
	local falsetitle=ssdb:zrrange("homework_count_false_byzyid_"..zy_id,0,100)
	if not falsetitle then
		say("{\"success\":false,\"info\":\"查询错题作业失败！\"}")
		return
	end
	if falsetitle[1]~="ok" then
		local flat=1
		for i=1,#falsetitle,2 do
			local tab={}
			tab["NUM"]=falsetitle[i+1]
			tab["QUESTION_ID_CHAR"]=falsetitle[i]
			--查作业的fileid及答案
        		for j=1,#(param.kg) do
                		if tonumber((param.kg)[j].question_id_char)== tonumber(falsetitle[i]) then
					tab["FILE_ID"]=(param.kg)[j].file_id
                        		tab["QUESTION_ANSWER"]=(param.kg)[j].question_answer
				end
        		end
			tabs[flat]=tab
			flat=flat+1
		end
	end
else
        if group_id=="0" then
                 --查询班级
		 local falsetitle=ssdb:zscan("homework_count_false_byclassid_"..class_id.."_"..zy_id,"","","",100)	
		if not falsetitle then
                	say("{\"success\":false,\"info\":\"查询错题作业失败！\"}")
                	return
        	end
        	if falsetitle[1]~="ok" then
                	local flat=1
			for i=1,#falsetitle,2 do
                        	local tab={}
                        	tab["NUM"]=falsetitle[i+1]
                        	tab["QUESTION_ID_CHAR"]=falsetitle[i]
				--查作业的fileid及答案
                        	for j=1,#(param.kg) do
                                if tonumber((param.kg)[j].question_id_char)== tonumber(falsetitle[i]) then
                                    tab["FILE_ID"]=(param.kg)[j].file_id
                                    tab["QUESTION_ANSWER"]=(param.kg)[j].question_answer
                                end
                        	end
                        	tabs[flat]=tab
				flat=flat+1
                	end
        	end	
        else
                 --查询组
		 local falsetitle=ssdb:zscan("homework_count_false_bygroupid_"..group_id.."_"..zy_id,"","","",100)
		if not falsetitle then
                        say("{\"success\":false,\"info\":\"查询错题作业失败！\"}")
                        return
                end
                if falsetitle[1]~="ok" then
                        local flat=1
			for i=1,#falsetitle,2 do
                                local tab={}
                                tab["NUM"]=falsetitle[i+1]
                                tab["QUESTION_ID_CHAR"]=falsetitle[i]
				--查作业的fileid及答案
                        	for j=1,#(param.kg) do
                                	if tonumber((param.kg)[j].question_id_char)== tonumber(falsetitle[i]) then
                                        	tab["FILE_ID"]=(param.kg)[j].file_id
                                        	tab["QUESTION_ANSWER"]=(param.kg)[j].question_answer
                                	end     
                        	end
                                tabs[flat]=tab
				flat=flat+1
                        end
                end
        end

end
cjson.encode_empty_table_as_object(false)
local jsonData=cjson.encode(tabs)
say("{\"success\": true,\"table_List\":"..jsonData.."}")
ssdb:set_keepalive(0,v_pool_size)
