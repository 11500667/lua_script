--[[
获取用户最后的访问痕迹
@Author  chenxg
@Date    2015-01-30
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

--判断request类型, 获得请求参数
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
--参数
--当前用户ID
local person_id = args["person_id"]
--访问栏目类型：1：门户大学区 2：门户协作体 3、个人中心大学区 4、个人中心协作体
local type_id = args["type_id"]

--判断参数是否为空
if not person_id or string.len(person_id) == 0
	or not type_id or string.len(type_id) == 0
then
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

local hpath_id = ssdb:hget("qyjh_person_path",person_id.."_"..type_id)
if not hpath_id then
	say("{\"success\":false}")
end
local path_id = hpath_id[1]

if not path_id or string.len(path_id) == 0 then
	path_id = "\"\""
end
say("{\"success\":true,\"path_id\":"..path_id.."}")
--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
