--[[
教师删除作业
@Author chuzheng
@Date 2015-1-10
--]]
local say = ngx.say
local service = require "space.gzip.service.BakToolsUpdateTsService"
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

--取ssdb中作业的信息
local str=ssdb:hget("homework_zy_content",zy_id)
if string.len(str[1])==0 then
        say("{\"success\":false,\"info\":\"读取作业信息失败！\"}")
        return
end
local param = cjson.decode(str[1])
-- 作业状态改为删除
param.TYPE_ID=1
ssdb:hset("homework_zy_content",zy_id,cjson.encode(param))
--更改数据库中信息，把作业状态改了，再往删除表中加数据

--获取时间戳ts
local t=ngx.now()
local n=os.date("%Y%m%d%H%M%S").."00"..string.sub(t,12,14)
n=n..string.rep("0",19-string.len(n))
local ts=n
--
--local counts = db:query("SELECT SQL_NO_CACHE id FROM t_zy_info_sphinxse  WHERE query=\'filter=ZY_ID,"..zy_id..";filter=CLASS_ID,0;filter=GROUP_ID,0;limit=10\'")
--if table.getn(counts)>0 then
--
--
--	local res, err, errno, sqlstate =db:query("insert into sphinx_zy_del_info(del_index_id) values("..counts[1]["id"]..")")
--	if not res then
--       		ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
--       		return
--	end
--end


local res, err, errno, sqlstate =db:query("update t_zy_info set TYPE_ID=\'1\',UPDATE_TS=\'"..ts.."\'  where ID="..zy_id)
if not res then
       ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
       return
end

db:set_keepalive(0,v_pool_size)
ssdb:set_keepalive(0,v_pool_size)

local zys = ngx.location.capture("/dsideal_yy/ypt/zy/cancelzy",{
    args={zy_id=zy_id,is_from_delete="yes"}
});

--ngx.log(ngx.ERR,"###############"..zys.status.."###############");
if zys.status ~= 200 then
    say("{\"success\":false,\"info\":\"删除失败！\"}")
end
service.updateTs(ngx.var.cookie_person_id,5);
say("{\"success\":true,\"info\":\"删除成功\"}")

