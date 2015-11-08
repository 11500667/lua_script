--[[
启用、停用工作室
@Author  feiliming
@Date    2014-11-27
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

local region_id = args["region_id"]
local workroom_id = args["workroom_id"]
local status = args["status"]
if not region_id or string.len(region_id) == 0 or not workroom_id or string.len(workroom_id) == 0 or not status or string.len(status) == 0 then
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

--判断是否已经开通
local wkrm, err = ssdb:hget("workroom_region", region_id)
if not wkrm then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
if string.len(wkrm[1]) == 0 then
	say("{\"success\":false,\"info\":\"尚未开通！\"}")
	return
end

--更新
local region = cjson.decode(wkrm[1])
region.status = status

ssdb:hset("workroom_region", region_id, cjson.encode(region))

--找工作室
local t_wk, err = ssdb:hget("workroom_workrooms", region.workroom_id)
if not t_wk or string.len(t_wk[1]) == 0 then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
--找到了
local workroom = cjson.decode(t_wk[1])
--0关闭,1启用
if tostring(status) == "0" then
    --删工作室区市省最新
    ssdb:zdel("workroom_"..workroom.level.."_w_new", region.workroom_id)
    ssdb:zdel("workroom_0_w_new", region.workroom_id)
    --删最新、最热名师
    local res, err = ssdb:zrange("workroom_teachers_sorted_by_name_"..region.workroom_id, 0, 10000)
    if res and res[1] and res[1] ~= "ok" then
        local teacherids = {}
        for i=1,#res,2 do
            table.insert(teacherids, res[i])
        end
        for i=1,#teacherids do
            ssdb:zdel("workroom_"..workroom.level.."_t_new", teacherids[i])
            ssdb:zdel("workroom_0_t_new", teacherids[i])
            ssdb:zdel("workroom_0_t_hot", teacherids[i])
            ssdb:zdel("workroom_"..workroom.level.."_t_hot", teacherids[i])
        end
    end
end
if tostring(status) == "1" then
    --工作室区市省最新
    local ts = os.date("%Y%m%d%H%M%S")
    ssdb:zset("workroom_"..workroom.level.."_w_new", region.workroom_id, ts)
    ssdb:zset("workroom_0_w_new", region.workroom_id, ts)
    --启用时添加最新名师, 原来的名师都变成最新名师
    local res, err = ssdb:zrange("workroom_teachers_sorted_by_name_"..region.workroom_id, 0, 10000)
    if res and res[1] and res[1] ~= "ok" then
        local teacherids = {}
        for i=1,#res,2 do
            table.insert(teacherids, res[i])
        end
        for i=1,#teacherids do
            ssdb:zset("workroom_"..workroom.level.."_t_new", teacherids[i], ts)
            ssdb:zset("workroom_0_t_new", teacherids[i], ts)
        end
    end
end

--return
say("{\"success\":true,\"info\":\"保存成功！\"}")

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
