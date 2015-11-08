--[[
教师的作业列表
@Author chuzheng
@data 2014-12-23
--]]
--应用json
local cjson = require "cjson"


--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--连接ssdb服务器
local ssdblib = require "resty.ssdb"
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then        
	say("{\"success\":false,\"info\":\""..err.."\"}")        
	return
end
local log = require("social.common.log")
log.outfile = "/tmp/student.log";
log.level="trace"

--接受前台的参数
local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--结点ID
local nid = args["nid"]
--版本号
local scheme_id = args["scheme_id"]
--搜索关键字
local keyword = args["keyword"]
--第几页
local pageNumber = args["pageNumber"]
--一页显示多少
local pageSize = args["pageSize"]
--是否是根节点
local is_root = args["is_root"]
--教师id
local teacher_id = ngx.var.cookie_person_id
--拼教师条件
local person_str =""
person_str = "filter=TEACHER_ID,"..teacher_id..";"

--判断是否有结点ID参数
if not nid or string.len(nid)==0 then
    ngx.say("{\"success\":false,\"info\":\"版本结构树初始化失败！\"}")
    return
end
if not scheme_id or string.len(scheme_id)==0 then
    ngx.say("{\"success\":false,\"info\":\"scheme_id参数错误！\"}")
    return
end

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
--判断是否有是否是根节点的参数
if not is_root or string.len(is_root)==0 then
    ngx.say("{\"success\":\"false\",\"info\":\"is_root参数错误！\"}")
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
    asc_desc = "asc"
else
    asc_desc = "desc"
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


--是否包含子节点
local cnode = tostring(args["cnode"])

local structure_scheme = ""
if is_root == "1" then
    if cnode == "1" then
        structure_scheme = "filter=scheme_id,"..scheme_id..";"
    else
  structure_scheme = "filter=structure_id,"..nid..";"
    end
else
    if cnode == "2" then
        structure_scheme = "filter=structure_id,"..nid..";"
    else
        local sid = cache:get("node_"..nid)
        local sids = Split(sid,",")
        for i=1,#sids do
            structure_scheme = structure_scheme..sids[i]..","
        end
      structure_scheme = "filter=structure_id,"..string.sub(structure_scheme,0,#structure_scheme-1)..";"
    end
end



--时间排序
local sort_filed = ""
sort_filed = "sort=attr_"..asc_desc..":TS;"

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

--og.debug("SELECT SQL_NO_CACHE id FROM t_zy_info_sphinxse  WHERE query=\'"..keyword..structure_scheme..person_str..sort_filed.."filter=TYPE_ID,0;groupby=attr:zy_id;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")

zy = db:query("SELECT SQL_NO_CACHE id FROM t_zy_info_sphinxse  WHERE query=\'"..keyword..structure_scheme..person_str..sort_filed.."filter=TYPE_ID,0;filter=CLASS_ID,0;filter=GROUP_ID,0;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")

--status中截取总个数
local zy1 = db:read_result()
--ngx.say(zy1[1]["Status"])
local _,s_str = string.find(zy1[1]["Status"],"found: ")
local e_str = string.find(zy1[1]["Status"],", time:")
local totalRow = string.sub(zy1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)
--ngx.say(totalRow)
--ngx.say(totalPage)
--ngx.say(pageNumber)
--ngx.say(pageSize)

local pages={}

local zy_info = ""

for i=1,#zy do
	local page={}
	--sphinx查询的是关系id，这里查出作业id
	--ngx.log(ngx.ERR, "@@@@@@@@@@@@@@@@@@@@"..zy[i]["id"].."@@@@@@@@@@@@@@@@@@@@")
	local relate= ssdb:multi_hget("homework_zy_student_relate_"..zy[i]["id"],"zy_id")
	
	local zylist,err=ssdb:hget("homework_zy_content",relate[2])
        if  not  zylist then
			say("{\"success\":false,\"info\":\"组查询失败！\"}")
			return
	end
	if string.len(zylist[1])>0 then
		local zycontent=zylist[1]
		--ngx.log(ngx.ERR, "@@@@@@@@@@@@@@@@@@@@"..string.len(zylist[1]).."@@@@@@@@@@@@@@@@@@@@")
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
	
	
		page["fj"]=table.getn(zycon.zy_fj_list)
		--page["url_code"]=zycon.url_code
		--page["iso_url"]=zycon.iso_url
		if zycon.paper_list and (zycon.paper_list)[1] then
			page["paper_source"]=(zycon.paper_list)[1].paper_source
		else
			page["paper_source"]=""	
		end
		--page["paper_source"]=(zycon.paper_list).paper_source
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
	        --老师的作业列表上的统计信息
		-- 提交情况
		local counts = db:query("SELECT SQL_NO_CACHE id FROM t_zy_info_sphinxse  WHERE query=\'filter=ZY_ID,"..relate[2].."\';SHOW ENGINE SPHINX  STATUS;")
		local count1 = db:read_result()
		local _,s_str = string.find(count1[1]["Status"],"found: ")
		local e_str = string.find(count1[1]["Status"],", time:")
		local total = string.sub(count1[1]["Status"],s_str+1,e_str-1)
		local submissiontotal=ssdb:get("homework_answer_submissionhomework_"..relate[2])
		if string.len(submissiontotal[1])==0 then
			page["submission"]=ngx.encode_base64("0/"..(tonumber(total)-1))
		else
			page["submission"]=ngx.encode_base64(submissiontotal[1].."/"..(tonumber(total)-1))
		end

		--批阅情况
		--local teachercounts = db:query("SELECT SQL_NO_CACHE id FROM t_zy_info_sphinxse  WHERE query=\'filter=ZY_ID,"..relate[2]..";filter=FLAT,2,3\';SHOW ENGINE SPHINX  STATUS;")
		--local count1 = db:read_result()
		--local _,s_str = string.find(count1[1]["Status"],"found: ")
                --local e_str = string.find(count1[1]["Status"],", time:")
                --local total = string.sub(count1[1]["Status"],s_str+1,e_str-1)
		
		local subjectivepy=ssdb:get("homework_subjectivepy_"..relate[2])
		
		local subjective=ssdb:get("home_answersubjective_"..relate[2])
		if string.len(subjective[1])==0 then
			page["subjective"]=ngx.encode_base64("0/0")
		else
			if string.len(subjectivepy[1])==0 then
				page["subjective"]=ngx.encode_base64("0/"..subjective[1])
			else
				page["subjective"]=ngx.encode_base64(subjectivepy[1].."/"..subjective[1])
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





