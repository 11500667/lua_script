--[[
教师的作业列表
@Author chuzheng
@data 2014-12-24
--]]
--应用json
local cjson = require "cjson"

--连接ssdb服务器
local ssdblib = require "resty.ssdb"
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then        
        say("{\"success\":false,\"info\":\""..err.."\"}")        
        return
end


--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end



--接受前台的参数
local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end
--学科id
local subject_id = args["subject_id"]


--搜索关键字
local keyword = args["keyword"]

local structure_id = args["structure_id"]
--第几页
local pageNumber = args["pageNumber"]
--一页显示多少
local pageSize = args["pageSize"]
--学生id
local student_id = ngx.var.cookie_person_id
--local student_id="400292"
--拼学生条件
local person_str =""
person_str = "filter=STUDENT_ID,"..student_id..";"
--作业状态
local flat=args["flat"]
local flat_str=""

if flat and string.len(flat)>0 then
	flat_str="filter=flat,"..flat..";"
else

	 flat_str="filter=flat,0,1,2;"
end
--学科拼串
local subject_str=""

if subject_id and string.len(subject_id)>0 and subject_id~="-1" then
        subject_str="filter=subject_id,"..subject_id..";"
--elseif subject_id == '-1' then
--    local class_id = ngx.var.cookie_class_id;
--    local subject_table;
--    local subjects=ngx.location.capture("/dsideal_yy/base/getSubjectByStudentId",{
--        args={student_id=student_id}
--    });
--    local paper
--    if subjects.status == 200 then
--        subject_table = cjson.decode(subjects.body)
--    else
--        ngx.say("{\"success\":false,\"info\":\"查询试卷信息失败\"}")
--        return
--    end
--    for i=1,#subject_table do
--        local subject_id = subject_table[i].subject_id;
--
--    end

end


--local structure_id_str =""
--if structure_id and string.len(structure_id)>0 and structure_id~="-1"then
--    local sid = cache:get("node_"..structure_id)
--    local sids = Split(sid,",")
--    for i=1,#sids do
--        structure_id_str = structure_id_str..sids[i]..","
--    end
--    structure_id_str = "filter=structure_id,"..string.sub(structure_id_str,0,#structure_id_str-1)..";"
--    --structure_id_str="filter=structure_id,"..structure_id..";"
--end



local is_root = tostring(args["is_root"])
if is_root == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"is_root参数错误！\"}")
    return
end
--是否包含子节点
local cnode = tostring(args["cnode"])
if cnode == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"cnode参数错误！\"}")
    return
end
--版本号
local scheme_id = tostring(args["scheme_id"])
if scheme_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"scheme_id参数错误！\"}")
    return
end

local structure_id_str = "";
if structure_id and string.len(structure_id)>0 and structure_id~="-1" then
    if is_root == "1" then
        if cnode == "1" then
            structure_id_str = "filter=scheme_id,"..scheme_id..";"
        else
            structure_id_str = "filter=structure_id,"..structure_id..";"
        end
    else
        if cnode == "0" then
            structure_id_str = "filter=structure_id,"..structure_id..";"
        else
            local sid = cache:get("node_"..structure_id)
            local sids = Split(sid,",")
            for i=1,#sids do
                structure_id_str = structure_id_str..sids[i]..","
            end
            structure_id_str = "filter=structure_id,"..string.sub(structure_id_str,0,#structure_id_str-1)..";"
        end
    end
end
--ngx.log(ngx.ERR,"#######"..structure_id_str.."#########");
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

--关键字处理
if not keyword or string.len(keyword)==0 then
    keyword = ""
else  --如果搜索关键字不为空就把传过来的base64进行编码转成真实的内容
    if #keyword ~= "0" then
        keyword = ngx.decode_base64(keyword)..";"
    else
		keyword = ""
    end
end

--升序还是降序   1：ASC   2:DESC
local sort_num = tostring(args["sort_order"])
--判断是否有排序的参数
if sort_num == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"参数错误！\"}")
    return
end

--升序还是降序
local asc_desc = ""
if sort_num=="1" then
    asc_desc = "attr_asc"
else
    asc_desc = "attr_desc"
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



--时间排序
local sort_filed = ""
sort_filed = "sort="..asc_desc..":TS;"
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


local offset = pageSize*pageNumber-pageSize
local limit = pageSize

local str_maxmatches = pageNumber*100


local zy = ""
--ngx.say("SELECT SQL_NO_CACHE id FROM t_zy_info_sphinxse  WHERE query=\'"..keyword..person_str..sort_filed..flat_str..subject_str.."filter=TYPE_ID,0;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")
--ngx.say("SELECT SQL_NO_CACHE id FROM t_zy_info_sphinxse  WHERE query=\'"..keyword..person_str..sort_filed..flat_str..subject_str.."maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")
zy = db:query("SELECT SQL_NO_CACHE id FROM t_zy_info_sphinxse  WHERE query=\'"..keyword..person_str..structure_id_str..sort_filed..flat_str..subject_str.."maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")
--ngx.say("SELECT SQL_NO_CACHE id FROM t_zy_info_sphinxse  WHERE query=\'"..keyword..person_str..sort_filed..flat_str..subject_str.."maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")
--status中截取总个数
local zy1 = db:read_result()
--ngx.say(zy1[1]["Status"])
local _,s_str = string.find(zy1[1]["Status"],"found: ")
local e_str = string.find(zy1[1]["Status"],", time:")
local totalRow = string.sub(zy1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

local pages={}

local zy_info = ""

for i=1,#zy do
		
        local page={}
        --sphinx查询的是关系id，这里查出作业id
		--ngx.log(ngx.ERR, "@@@@@@@@@@@@@@@@@@@@"..zy[i]["id"].."@@@@@@@@@@@@@@@@@@@@")
        local relate= ssdb:multi_hget("homework_zy_student_relate_"..zy[i]["id"],"zy_id","flat")

        local zylist,err=ssdb:hget("homework_zy_content",relate[2])
        if  not  zylist then
                        say("{\"success\":false,\"info\":\"组查询失败！\"}")
                        return
        end
		
        if string.len(zylist[1])>0 then
			local zycontent=zylist[1]
			local zycon=cjson.decode(zycontent)
			page["zy_id"]=relate[2]
			page["zy_name"]=zycon.zy_name
			local curr_path = ""
			--获取当前位置
			local structures = cache:zrange("structure_code_"..zycon.structure_id,0,-1)
			for i=1,#structures do
					local structure_info = cache:hmget("t_resource_structure_"..structures[i],"structure_name")
					curr_path = curr_path..structure_info[1].."->"
			end
			curr_path = string.sub(curr_path,0,#curr_path-2)
			--判断当前作业有没有主观题
			--获取学生主观题答题信息
			local subjective,err = ssdb:hscan("homework_answersubjective_"..student_id.."_"..relate[2],"","",100)
			if not subjective then
					say("{\"success\":false,\"info\":\"学生答题查询失败！\"}")
					return
			end
			if subjective[1]~="ok" then
				page["issubjective"]="1"
			else
				page["issubjective"]="0"
			end
			page["parent_structure_name"]=curr_path                
			page["public_time"]=zycon.create_time
			page["is_public"]=zycon.is_public
			page["is_download"]=zycon.is_download
			page["is_look_answer"]=zycon.is_look_answer
			if table.getn(zycon.zy_fj_list)==0 then
					page["is_have_res"]=0
			else
					page["is_have_res"]=1
			end
			page["subject_id"]=zycon.subject_id
			page["subject_name"]=zycon.subject_name
			--前台显示状态，在缓存中存的是flat
			page["submit_status"]=relate[4]
			--ngx.say(relate[4])
			--ngx.say(relate[3])
			--ngx.say(relate[2])
			--ngx.say(relate[1])
			if zycon.paper_list and (zycon.paper_list)[1] then
				page["paper_source"]=(zycon.paper_list)[1].paper_source
			else
				page["paper_source"]=""
			end
			--加入试卷信息
			--ngx.say(cjson.encode(zycon.zg))
			if zycon.zg and (zycon.zg)[1] then
				page["is_have_zg"]="1"
			else
				page["is_have_zg"]="0"
			end
			if zycon.kg and (zycon.kg)[1] then
							page["is_have_kg"]="1"
			else
				page["is_have_kg"]="0"
			end
			--判断有无试卷，取试卷信息
			if zycon.paper_list and (zycon.paper_list)[1] then
			--	ngx.say((zycon.paper_list)[1].iid)
			--	 ngx.say((zycon.paper_list)[1].paper_type)
				if (zycon.paper_list)[1].paper_source=="1" then
					page["paper_id"]=(zycon.paper_list)[1].paper_id
					page["paper_file_id"]=(zycon.paper_list)[1].paper_file_id
					page["paper_name"]=(zycon.paper_list)[1].paper_name
					page["extenstion"]=(zycon.paper_list)[1].extenstion
					page["paper_source"]=(zycon.paper_list)[1].paper_source
					page["url_code"]=(zycon.paper_list)[1].url_code
					page["for_urlencoder_url"]=(zycon.paper_list)[1].for_urlencoder_url
							page["for_iso_url"]=(zycon.paper_list)[1].for_iso_url
				end
				if (zycon.paper_list)[1].paper_source=="2" then
					 local id  = (zycon.paper_list)[1].iid
						 local paper_type = (zycon.paper_list)[1].paper_type
					 local papers=ngx.location.capture("/dsideal_yy/ypt/paper/getInfoByPaperId", 
									 {
										args={id=id,paper_type=paper_type}
								 })
								 local paper
								 if papers.status == 200 then 
										paper = cjson.decode(papers.body)  
										--paper[1]["paper_type"]=paper_type 
								 else 
										ngx.say("{\"success\":false,\"info\":\"查询试卷信息失败\"}") 
										return
								end
									page["paper_id"]=paper.paper_id
									page["paper_file_id"]=paper.file_id
									page["paper_name"]=paper.paper_name
									page["extenstion"]=paper.extenstion
									page["paper_source"]=paper.paper_source and paper.paper_source or ""
									page["url_code"]=paper.url_code
									page["for_urlencoder_url"]=paper.for_urlencoder_url
									page["for_iso_url"]=paper.for_iso_url
							end
			end
				--page["zy_content"]=zycon.zy_content
		end
		pages[i]=page

end
--local jsonData=cjson.encode(pages)

local result={}
result["success"]="true"
result["totalRow"]=totalRow
result["totalPage"]=totalPage
result["pageNumber"]=pageNumber
result["pageSize"]=pageSize
result["list"]=pages
cjson.encode_empty_table_as_object(false)

local resultjson=cjson.encode(result)
ngx.say(resultjson)

--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0,v_pool_size)
--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
