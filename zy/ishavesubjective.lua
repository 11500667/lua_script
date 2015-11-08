--[[
判断是否有主观题
@Author chuzheng
@Date 2015-1-13
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


--local student_id = ngx.var.cookie_person_id
local zy_id = args["zy_id"]
if not zy_id or string.len(zy_id)==0 then
         say("{\"success\":false,\"info\":\"参数错误！\"}")
         return
end

--判断传没传学生id传了则用，没传去cookie中取
local student_id = args["student_id"]
if not student_id or string.len(student_id)==0 then
	student_id=ngx.var.cookie_person_id
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

--取ssdb中主观题的信息
--获取学生主观题答题信息
local subjective,err = ssdb:hscan("homework_answersubjective_"..student_id.."_"..zy_id,"","",100)
if not subjective then
    say("{\"success\":false,\"info\":\"学生答题查询失败！\"}")    
    return
end
if subjective[1]~="ok" then
	say("{\"success\":true,\"info\":\"学生提交主观题了！\"}")
else
	say("{\"success\":false,\"info\":\"学生,没有提交主观题！\"}")
end

ssdb:set_keepalive(0,v_pool_size)
