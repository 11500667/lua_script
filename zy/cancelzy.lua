--[[
教师取消作业
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
local is_from_delete = args["is_from_delete"]
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

--看看有没有提交作业的
if not is_from_delete or string.len(is_from_delete)==0 then
    local num=ssdb:get("homework_answer_submissionhomework_"..zy_id)
    local num2=ssdb:get("teachercannotcancelzy_"..zy_id)
    if(string.len(num[1])>0 or tonumber(num2[1])==1 ) then
        say("{\"success\":false,\"info\":\"已经有学生交作业不能取消\"}")
        return
    end
end

--取ssdb中作业的信息
local str=ssdb:hget("homework_zy_content",zy_id)
if string.len(str[1])==0 then
        say("{\"success\":false,\"info\":\"读取作业信息失败！\"}")
        return
end
local param = cjson.decode(str[1])
-- 作业状态改为未发布
param.is_public=0
ssdb:hset("homework_zy_content",zy_id,cjson.encode(param))
--更改数据库中信息，把作业状态改了，再往删除表中加数据

--获取时间戳ts
local t=ngx.now()
local n=os.date("%Y%m%d%H%M%S").."00"..string.sub(t,12,14)
n=n..string.rep("0",19-string.len(n))
local ts=n


local counts = db:query("SELECT SQL_NO_CACHE id FROM t_zy_info_sphinxse  WHERE query=\'filter=ZY_ID,"..zy_id..";!filter=CLASS_ID,0;limit=1000\'")
if table.getn(counts)>0 then
	local content=""
	local delcontent=""
	for i=1,#counts do
		if string.len(content)==0 then
			content="("..counts[i]["id"]..")"
		else
			content=content..",("..counts[i]["id"]..")"
		end
		if string.len(delcontent)==0 then
                        delcontent=counts[i]["id"]
                else
                        delcontent=delcontent..","..counts[i]["id"]
                end
	
	end 
	--ngx.say("insert into sphinx_zy_del_info(del_index_id) values "..content)	
        local res, err, errno, sqlstate =db:query("insert into sphinx_zy_del_info(del_index_id) values "..content)
        if not res then
                ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
                return
        end
	--删除
	local res, err, errno, sqlstate =db:query("delete from t_zy_zytostudent where ID in ( "..delcontent..")")
        if not res then
                ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
                return
        end
end


local res, err, errno, sqlstate =db:query("update t_zy_info set IS_PUBLIC='0'  where ID="..zy_id)
if not res then
       ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
       return
end



say("{\"success\":true,\"info\":\"取消成功\"}")
db:set_keepalive(0,v_pool_size)
ssdb:set_keepalive(0,v_pool_size)
