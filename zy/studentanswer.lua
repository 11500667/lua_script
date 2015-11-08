--[[
学生答客观题
@Author chuzheng
@date 2014-12-30
--]]
local say = ngx.say

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
--这里读取学生对应的cookie
local student_id = ngx.var.cookie_person_id
--作业id
local zy_id = args["zy_id"]
--试题id
local question_id_char = args["question_id_char"]
--结果
local studentanswer = args["studentanswer"]
--正确答案
local trueanswer = args["trueanswer"]
if not zy_id or string.len(zy_id)==0 or not question_id_char or string.len(question_id_char)==0 or not studentanswer or string.len(studentanswer)==0 or not trueanswer or string.len(trueanswer)==0  then
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

--ssdb存储学生客观题答题信息
--ngx.log(ngx.ERR,"++++++++++++++++++"..student_id.."------------"..zy_id.."==============="..question_id_char.."**********"..studentanswer.."&&&&&&&&&&&"..trueanswer)
if tostring(studentanswer) ~= 'answer' then
    ssdb:hset("homework_answer_"..student_id.."_"..zy_id,question_id_char,studentanswer.."_"..trueanswer);
    ssdb:set("teachercannotcancelzy_"..zy_id,1);--告诉老师不要取消作业了。
else
    ssdb:hdel("homework_answer_"..student_id.."_"..zy_id,question_id_char);
end



say("{\"success\":true,\"info\":\"保存成功\"}")

ssdb:set_keepalive(0,v_pool_size)
