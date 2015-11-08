--[[
维护大学区下的带头人
@Author  chenxg
@Date    2015-03-02
--]]

local say = ngx.say
local quote = ngx.quote_sql_str

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
local org_id = args["org_id"]
	--操作：1单个选中,2单个取消
local operationtype = args["operationtype"]
local person_id = args["person_id"]

--判断参数是否为空
if not dxq_id or string.len(dxq_id) == 0  
  or not org_id or string.len(org_id) == 0  
  or not operationtype or string.len(operationtype) == 0 
  or not person_id or string.len(person_id) == 0 
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

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
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

--获取大学区下的全部带头人
local hallteaids = ssdb:hget("qyjh_dxq_dtrs",dxq_id)
local allteaids = hallteaids[1]

if not allteaids or string.len(allteaids) == 0 then
	allteaids =","
end
--获取大学区下的全部带头人结束
--获取大学区某个学校下的带头人列表开始
local horgteaids = ssdb:hget("qyjh_dxq_org_dtrs",dxq_id.."_"..org_id)
local orgteaids = horgteaids[1]

if not orgteaids or string.len(orgteaids) == 0 then
	orgteaids =","
end
--获取大学区某个学校下的带头人列表结束
local dxq = ssdb:hget("qyjh_dxq",dxq_id)
local temp = cjson.decode(dxq[1])
local qyjh_id = temp.qyjh_id

if operationtype == "1" then
	allteaids = ","..person_id.. allteaids
	orgteaids = ","..person_id.. orgteaids
	
	ngx.log(ngx.ERR, "&&&&&&&&&&&&&>"..qyjh_id.."<=sql=");
	ssdb:zset("qyjh_qyjh_tea_uploadcount_"..qyjh_id,person_id,0)
	ssdb:zset("qyjh_dxq_tea_uploadcount_"..dxq_id,person_id,0)
	
	ssdb:zset("qyjh_qyjh_dtrs_"..qyjh_id,person_id,os.date("%Y%m%d%H%M%S"))
	ssdb:hset("qyjh_dtr_dxq",person_id,dxq_id)
	ssdb:hincr("qyjh_dxq_tj",dxq_id.."_dtr_tj",1)
elseif operationtype == "2" then
	allteaids = string.gsub(allteaids, ","..person_id..",", ",")
	orgteaids = string.gsub(orgteaids, ","..person_id..",", ",")
	
	--陈续刚于2015.02.06添加，增加了修改教师的相关资源数量统计开始
	--教师在大学区的上传量
	local xtuc = ssdb:zget("qyjh_dxq_tea_uploadcount_"..dxq_id,person_id)
	if not xtuc[1] or string.len(xtuc[1])then
		xtuc[1] = 0
	end
	xtuc = tonumber(xtuc[1])
	--陈续刚于2015.02.06添加，增加了修改教师的相关资源数量统计开始
	--修改区域均衡资源数量
	ssdb:hincr("qyjh_qyjh_tj_"..qyjh_id,"zy_tj",-xtuc)
	--修改大学区资源数量
	ssdb:hincr("qyjh_dxq_tj",dxq_id.."_zy_tj",-xtuc)
	--修改学校在区域均衡的资源数量
	ssdb:zincr("qyjh_qyjh_org_uploadcount_"..qyjh_id,org_id,-xtuc)
	--修改学校在大学区的资源数量
	ssdb:zincr("qyjh_dxq_org_uploadcount_"..dxq_id,org_id,-xtuc)
	--删除用户在区域均衡的上传量
	ssdb:zdel("qyjh_qyjh_tea_uploadcount_"..qyjh_id,person_id)
	--删除用户在大学区的上传量
	ssdb:zdel("qyjh_dxq_tea_uploadcount_"..dxq_id,person_id) 
	--删除用户在大学区的上传量
	ssdb:zdel("qyjh_xzt_tea_uploadcount_"..dxq_id,person_id)
	--陈续刚于2015.02.06添加，增加了修改教师的相关资源数量统计结束
	
	--从t_base_publish表删除教师上传的数据
	--*****
	--ts
	local n = ngx.now();
	local ts = os.date("%Y%m%d%H%M%S").."00"..string.sub(n,12,14);
	ts = ts..string.rep("0",19-string.len(ts));
	local ids = "";
	local ssql = "SELECT id from t_base_publish "..
		"WHERE person_id = "..quote(person_id).." "..
		"AND pub_type = 3".." "..
		"AND pub_target = "..quote(dxq_id).." "..
		"AND b_delete = 0;"
		local result = mysql_db:query(ssql)
		if result and result[1] then
			--update
			local usql = "UPDATE t_base_publish SET b_delete = 1, update_ts = "..ts.." "..
			"WHERE person_id = "..quote(person_id).." "..
			"AND pub_type = 3".." "..
			"AND pub_target = "..quote(dxq_id).." "..
			"AND b_delete = 0;"
			local ok, err = mysql_db:query(usql)
			if ok then
				--删除缓冲
				for i = 1,#result,1 do
					cache:del("publish_"..result[i].id)
				end	
			end
		end
	--*****
	ssdb:zdel("qyjh_qyjh_dtrs_"..qyjh_id,person_id)
	ssdb:hdel("qyjh_dtr_dxq",person_id)
	ssdb:hincr("qyjh_dxq_tj",dxq_id.."_dtr_tj",-1)
end
ssdb:hset("qyjh_dxq_org_dtrs",dxq_id.."_"..org_id,orgteaids)
ssdb:hset("qyjh_dxq_dtrs",dxq_id,allteaids)



say("{\"success\":true,\"info\":\"操作成功！\"}")

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
mysql_db:set_keepalive(0,v_pool_size)
