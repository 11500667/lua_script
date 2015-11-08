--[[
删除大学区
@Author  chenxg
@Date    2015-03-01
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
local dxq_id = args["dxq_id"]
local qyjh_id = args["qyjh_id"]

--判断参数是否为空
if not dxq_id or string.len(dxq_id) == 0  
  or not qyjh_id or string.len(qyjh_id) == 0 
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

--连接mysql数据库
local mysql = require "resty.mysql"
local mysql_db = mysql:new()
mysql_db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024*1024
}

--根据分隔符分割字符串
function Split(str, delim, maxNb)   
	-- Eliminate bad cases...   
	if string.find(str, delim) == nil then  
		return { str }  
	end  
	if maxNb == nil or maxNb < 1 then  
		maxNb = 0    -- No limit   
	end  
	local result = {}  
	local pat = "(.-)" .. delim .. "()"   
	local nb = 0  
	local lastPos   
	for part, pos in string.gfind(str, pat) do  
		nb = nb + 1  
		result[nb] = part   
		lastPos = pos   
		if nb == maxNb then break end  
	end  
	-- Handle the last field   
	if nb ~= maxNb then  
		result[nb + 1] = string.sub(str, lastPos)   
	end  
	return result   
end

--大学区详细信息
local hdxq = ssdb:hget("qyjh_dxq",dxq_id)
local dxq = cjson.decode(hdxq[1])
dxq.b_delete = 1

local ok, err = ssdb:hset("qyjh_dxq", dxq_id, cjson.encode(dxq))

if not ok then
   say("{\"success\":false,\"info\":\""..err.."\"}")
   return
end
--删除大学区跟区域均衡的对应关系
ssdb:zdel("qyjh_qyjh_dxqs_"..qyjh_id,dxq_id)

--删除大学区-管理员对应关系
ssdb:hdel("qyjh_dxq_manager",dxq_id)
--ssdb:hdel("qyjh_manager_dxqs",dxq.person_id)
local old_qyjh_manager_dxqs = ssdb:hget("qyjh_manager_dxqs",dxq.person_id)
if not old_qyjh_manager_dxqs[1] or string.len(old_qyjh_manager_dxqs[1]) == 0  then
	old_qyjh_manager_dxqs[1] = ","
end
old_qyjh_manager_dxqs[1] = string.gsub(old_qyjh_manager_dxqs[1], ","..dxq_id..",", ",")
local ok, err = ssdb:hset("qyjh_manager_dxqs", dxq.person_id, old_qyjh_manager_dxqs[1])
ssdb:zdel("qyjh_manager_dxqs_"..dxq.person_id,dxq_id)
--删除大学区点击量
ssdb:zdel("qyjh_dxq_djl_"..qyjh_id, dxq_id)

--删除大学区下的协作体
local xzts = ssdb:hget("qyjh_dxq_xzts",dxq_id)
local res = Split(xzts[1],",")
local tids = {}
for i=2,#res-1,1 do
	local res_xzt = ngx.location.capture("/dsideal_yy/qyjhfz/deleteXzt?xzt_id="..res[i])
	if res_xzt.status ~= 200 then
		say("{\"success\":false,\"info\":\"删除大学区下的协作体失败！\"}")
		return
	end
end

--存储区域均衡下大学区数量
ssdb:hincr("qyjh_qyjh_tj_"..qyjh_id,"dxq_tj", -1)

--删除大学区统计信息
ssdb:hdel("qyjh_dxq_tj",dxq_id.."_".."xzt_tj")
ssdb:hdel("qyjh_dxq_tj",dxq_id.."_".."xx_tj")
ssdb:hdel("qyjh_dxq_tj",dxq_id.."_".."js_tj")
ssdb:hdel("qyjh_dxq_tj",dxq_id.."_".."zy_tj")
ssdb:hdel("qyjh_dxq_tj",dxq_id.."_".."hd_tj")

local n = ngx.now();
local ts2 = os.date("%Y%m%d%H%M%S").."00"..string.sub(n,12,14);
ts2 = ts2..string.rep("0",19-string.len(ts2));
--标记删除协作体
local updateSql = "update t_qyjh_dxq set b_delete =1,ts="..ts2.." where dxq_id="..dxq_id;	
mysql_db:query(updateSql)

--删除大学区跟学校的对应关系20150503要完成
	--[[ssdb:hget("qyjh_org_dxq", org_id)
	ssdb:hgetall("qyjh_dxq_orgs_"..dxq_id)]]

say("{\"success\":true,\"info\":\"大学区删除成功！\"}")

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
--mysql放回连接池
mysql_db:set_keepalive(0,v_pool_size)
