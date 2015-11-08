
--[[
学生删除作业
@Author chuzheng
@Date 2015-1-10
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

local student_id = ngx.var.cookie_person_id
--更改数据库中信息，把作业状态改了，再往删除表中加数据
--获取时间戳ts
local t=ngx.now()
local n=os.date("%Y%m%d%H%M%S").."00"..string.sub(t,12,14)
n=n..string.rep("0",19-string.len(n))
local ts=n


--获取关联表id

local relate = ssdb:hget("homework_zy_relateidbystudentidzyid",zy_id.."_"..student_id)

--更改作业状态	
if not relate then
	 ngx.say("{\"success\":false,\"info\":\"删除作业失败！\"}")
         return
end

ssdb:multi_hset("homework_zy_student_relate_"..relate[1],"flat",3)
local res, err, errno, sqlstate =db:query("update t_zy_zytostudent set FLAT=\'3\'  where ID="..relate[1])
if not res then                      
          ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
          return                
end


local res, err, errno, sqlstate =db:query("update t_zy_info set UPDATE_TS=\'"..ts.."\'  where ID="..zy_id)
if not res then
       ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
       return
end



say("{\"success\":true,\"info\":\"删除成功\"}")
db:set_keepalive(0,v_pool_size)
ssdb:set_keepalive(0,v_pool_size)
