--[[
学生错题集
@Author chuzheng
@data 2015-1-10
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


--第几页
local pageNumber = args["pageNumber"]
--一页显示多少
local pageSize = args["pageSize"]
--学生id
local studentid = ngx.var.cookie_person_id


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
--获取总条数
local count = ssdb:zcount("homework_count_falsetostudent_"..subject_id.."_"..studentid,"","")
local totalRow = count[1]
--偏移量
local offset = pageSize*pageNumber-pageSize
local limit = pageSize
--多少页
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)
--获取题
local title = ssdb:zrrange("homework_count_falsetostudent_"..subject_id.."_"..studentid,offset,limit)
if not title then
	ngx.say("{\"success\":false,\"info\":\"取错题集错误！\"}")	
	return
end
local pages={}
local j=1
if title[1]~="ok" then

for i=1,#title,2 do 
	--title[i]
	local page={}
	local titles= Split(title[i],"_")
	--判断是多选还是单选题
	--取ssdb中作业的信息
	local str=ssdb:hget("homework_zy_content",titles[1])
	if string.len(str[1])==0 then
	        say("{\"success\":false,\"info\":\"读取作业信息失败！\"}")
	        return
	end	
	local param = cjson.decode(str[1])
	for i=1,#(param.kg) do
		if (param.kg)[i].question_id_char == titles[2] then
			page["question_type_id"]=(param.kg)[i].question_type_id
			break
		end
	end


	
	page["title"]=titles[2]
	local answers=ssdb:hget("homework_answer_"..studentid.."_"..titles[1],titles[2])
	if string.len(answers[1])>0 then
		local studentanswer=Split(answers[1],"_")
		page["answer"]=studentanswer[1]
		page["question_answer"]=studentanswer[2]
	end
	pages[j]=page
	j=j+1
end
end
local result={}
result["success"]=true
result["totalRow"]=totalRow
result["totalPage"]=totalPage
result["pageNumber"]=pageNumber
result["pageSize"]=pageSize
result["list"]=pages


local resultjson=cjson.encode(result)
cjson.encode_empty_table_as_object(false);
ngx.say(resultjson)

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
