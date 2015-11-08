--[[
@Author chuzheng
@date 2014-12-23
--]]
local say = ngx.say

--引用模块
local ssdblib = require "resty.ssdb"

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


local param_json=args["param_json"]

local teacher_id = ngx.var.cookie_person_id

if not teacher_id or string.len(teacher_id) == 0 or not param_json or string.len(param_json) == 0  then
        say("{\"success\":false,\"info\":\"参数错误！\"}")
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

--留作业

local str = ngx.decode_base64(param_json)
local param = cjson.decode(str)


--获取mysql数据库中需要sphinx的数据
local zy_name=param.zy_name
local zy_id=param_id
--获取作业班级对象
local class_id_arrs=param.class_id_arrs
--保存学生作业对应关系
              

--获取班级组对象
local group_id_arrs=param.group_id_arrs
--保存学生作业对应关系



--获取时间戳ts
local t=ngx.now()
local n=os.date("%Y%m%d%H%M%S").."00"..string.sub(t,12,14)
n=n..string.rep("0",19-string.len(n))

local update_ts=n


--ssdb中保存所有信息

param.teacher_id=teacher_id

ssdb:hset("homework_zy_content",zy_id,cjson.encode(param))

--作业信息插入mysql数据库
local res, err, errno, sqlstate =db:query("update t_zy_info set ZY_NAME="..zy_name..",UPDATE_ID="..update_ts.." where ID="..zy_id)


if not res then
    ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
    return
end

say("{\"success\":true,\"info\":\"保存成功\"}")
ssdb:set_keepalive(0,v_pool_size)
db:set_keepalive(0,v_pool_size)
