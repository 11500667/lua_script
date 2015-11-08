--[[学生分组
@Author chuzheng
@date 2014-12-19
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
local student_id = args["student_id"]
local subject_id = args["subject_id"]
local teacher_id = ngx.var.cookie_person_id
local group_id = args["group_id"]
local class_id = args["class_id"]
if not class_id or string.len(class_id)==0 or not group_id or string.len(group_id)==0 or not student_id or string.len(student_id)==0 or not subject_id or string.len(subject_id) == 0 or not teacher_id or string.len(teacher_id) == 0 then
        say("{\"success\":false,\"info\":\"参数错误！\"}")
        return

end
--ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end


--Split方法
function Split(szFullString, szSeparator)
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





--学生调组


local sids = Split(student_id,",")
for i=1,#sids do
       
	local groups,err = ssdb:hget("homework_groupbystudent_"..class_id.."_"..sids[i],teacher_id.."_"..subject_id)
	if not groups then
    	say("{\"success\":false,\"info\":\"组查询失败！\"}")
    		return
	end
	if string.len(groups[1])>0 then
		ssdb:hdel("homework_studentbygroup_"..class_id.."_"..teacher_id.."_"..subject_id.."_"..groups[1],sids[i])
	end
	ssdb:hset("homework_studentbygroup_"..class_id.."_"..teacher_id.."_"..subject_id.."_"..group_id,sids[i],"")
	ssdb:hset("homework_groupbystudent_"..class_id.."_"..sids[i],teacher_id.."_"..subject_id,group_id)
end


say("{\"success\":true,\"info\":\"保存成功！\"}")
--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)


