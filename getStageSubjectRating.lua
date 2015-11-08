local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

local cjson = require "cjson"

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

local xd_subject_list = {}
local stage_res = mysql_db:query("SELECT stage_id,stage_name FROM t_dm_stage WHERE stage_id IN (4,5,6,7)")
for i=1,#stage_res do
	local xd_subject_tab = {}

	xd_subject_tab["xd_id"] = stage_res[i]["stage_id"]
	xd_subject_tab["xd_name"] = stage_res[i]["stage_name"]
	
	local subject_list = {}
	local subject_res = mysql_db:query("SELECT subject_id,subject_name FROM t_dm_subject WHERE stage_id = "..stage_res[i]["stage_id"])
	for j=1,#subject_res do
		local subject_tab = {}		
		subject_tab["subject_id"] = subject_res[j]["subject_id"]
		subject_tab["subject_name"] = subject_res[j]["subject_name"]
		subject_list[j] = subject_tab
	end	
	xd_subject_tab["subject_list"] = subject_list
	
	xd_subject_list[i] = xd_subject_tab
end

local result = {} 
result["success"] = true
result["xd_subject_list"] = xd_subject_list

--mysql放回连接池
mysql_db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false)
ngx.print(tostring(cjson.encode(result)))
