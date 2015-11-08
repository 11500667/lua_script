--[[
判断客观题是否答完
@Author chuzheng
@Date 2015-1-9
--]]
local say = ngx.say

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


local student_id = ngx.var.cookie_person_id
local zy_id = args["zy_id"]
if not zy_id or string.len(zy_id)==0 then
         say("{\"success\":false,\"info\":\"参数错误！\"}")
         return
end
--引用模块
local ssdblib = require "resty.ssdb"
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
for i=1,#(param.kg) do
	local answer = ssdb:hget("homework_answer_"..student_id.."_"..zy_id,(param.kg)[i].question_id_char)
	if not answer then
		say("{\"success\":false,\"info\":\"组查询失败！\"}")
		return
	end	
	if string.len(answer[1])==0 then
		say("{\"success\":true,\"flat\":false,\"info\":\"您的客观题作业没有答完，不能提交作业！\"}")
		return
	end
		
end


say("{\"success\":true,\"flat\":true,\"info\":\"答完题了\"}")
ssdb:set_keepalive(0,v_pool_size)
