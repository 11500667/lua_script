--[[
维护大学区下的带头人[mysql版]
@Author  chenxg
@Date    2015-06-01
--]]

local say = ngx.say
local quote = ngx.quote_sql_str

--引用模块
local cjson = require "cjson"

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
local db = mysql:new()
db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024*1024
}

local dxqSql = "select qyjh_id from t_qyjh_dxq where dxq_id="..dxq_id
local result, err, errno, sqlstate = db:query(dxqSql);
if not result then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	return
end
local qyjh_id = result[1]["qyjh_id"]
--[[
local res_count = "select count(distinct obj_info_id) from t_base_publish "..
		"WHERE person_id = "..quote(person_id).." AND pub_type = 3".."AND pub_target = "..quote(dxq_id).." AND b_delete = 0;"
local res_result = db:query(res_count)
]]	
if operationtype == "1" then
	local insertSql = "insert into t_qyjh_dxq_dtr(qyjh_id,dxq_id,org_id,person_id,start_time) values("..quote(qyjh_id)..","..quote(dxq_id)..","..quote(org_id)..","..quote(person_id)..","..quote(os.date("%Y-%m-%d %H:%M:%S"))..")"
	local result, err, errno, sqlstate = db:query(insertSql);
	if not result then
		ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
		return
	end
	
	local updateSql = "update t_qyjh_dxq set dtr_tj = dtr_tj+1 where dxq_id="..dxq_id
	db:query(updateSql);
	
elseif operationtype == "2" then
	
	--修改大学区下的带头人数量
	local updateSql2 = "update t_qyjh_dxq set dtr_tj = dtr_tj-1  where dxq_id="..dxq_id
	db:query(updateSql2);
	
	--删除带头人跟大学区的对应关系
	local updateSql = "update t_qyjh_dxq_dtr set end_time = "..quote(os.date("%Y-%m-%d %H:%M:%S"))..",b_use=0 where b_use=1 and dxq_id="..dxq_id .." and person_id="..person_id
	db:query(updateSql);
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
		local result = db:query(ssql)
		if result and result[1] then
			--update
			local usql = "UPDATE t_base_publish SET b_delete = 1, update_ts = "..ts.." "..
			"WHERE person_id = "..quote(person_id).." "..
			"AND pub_type = 3".." "..
			"AND pub_target = "..quote(dxq_id).." "..
			"AND b_delete = 0;"
			local ok, err = db:query(usql)
			if ok then
				--删除缓冲
				for i = 1,#result,1 do
					cache:del("publish_"..result[i].id)
				end	
			end
		end
	--*****
end

say("{\"success\":true,\"info\":\"操作成功！\"}")

--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0,v_pool_size)
