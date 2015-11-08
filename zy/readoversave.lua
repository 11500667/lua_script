
--[[
保存学生主观题信息及批阅情况
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


local student_id = args["student_id"]
local zy_id = args["zy_id"]
local file_id=args["file_id"]
local checkcontent=args["checkcontent"]

if not student_id or string.len(student_id) == 0 or not zy_id or string.len(zy_id)==0 or not file_id or string.len(file_id)==0 then
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


--查询关联表id失败
local relate = ssdb:hget("homework_zy_relateidbystudentidzyid",zy_id.."_"..student_id)
if not relate then
	say("{\"success\":flase,\"info\":\"查询关系表id失败！\"}")
	return
end
--查询状态
local flat = ssdb:multi_hget("homework_zy_student_relate_"..relate[1],"flat")

if not flat then
	 say("{\"success\":flase,\"info\":\"查询作业批阅状态失败！\"}")
        return
end
if flat[2]=="1" then
	--主观题提交情况
	ssdb:incr("homework_subjectivepy_"..zy_id)
	--获取时间戳ts
	local t=ngx.now()
	local n=os.date("%Y%m%d%H%M%S").."00"..string.sub(t,12,14)
	n=n..string.rep("0",19-string.len(n))
	local ts=n
	ssdb:multi_hset("homework_zy_student_relate_"..relate[1],"flat","2")
	--更改作业状态mysql
	local res, err, errno, sqlstate =db:query("update t_zy_zytostudent set FLAT=\'2\'  where ID="..relate[1])
        if not res then
                ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
                return
        end
	local res, err, errno, sqlstate =db:query("update t_zy_info set UPDATE_TS=\'"..ts.."\'  where ID="..zy_id)
	if not res then
       		ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
       		return
	end
end


ssdb:hset("homework_answersubjective_"..student_id.."_"..zy_id,file_id,checkcontent)

say("{\"success\":true,\"info\":\"保存成功！\"}")
db:set_keepalive(0,v_pool_size)
ssdb:set_keepalive(0,v_pool_size)
