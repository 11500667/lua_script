local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--bureau_id参数 单位ID
if args["bureau_id"] == nil or args["bureau_id"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"bureau_id参数错误！\"}")
	return
end
local bureau_id = args["bureau_id"]

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

--单位类型  1：省    2：市    3：区
local bureau_type = string.sub(bureau_id,0,1)
if bureau_type ~= "1" and bureau_type ~= "2" and bureau_type ~= "3" then
	ngx.print("{\"success\":false,\"info\":\"只能获取省市区下的单位！\"}")
	return
end

local res = ""

if bureau_type == "1" then
	res = mysql_db:query("SELECT id,cityname AS name FROM t_gov_city WHERE provinceid="..bureau_id)
elseif bureau_type == "2" then
	res = mysql_db:query("SELECT id,districtname AS name FROM t_gov_district WHERE cityid="..bureau_id)
else
	res = mysql_db:query("SELECT org_id AS id,org_name AS name FROM t_base_organization WHERE org_type=2 AND district_id="..bureau_id)
end

local bureau_tab = {}
for i=1,#res do
	local bureau_info = {}
	bureau_info["id"] = res[i]["id"]
	bureau_info["name"] = res[i]["name"]
	bureau_tab[i] = bureau_info
end

local result = {}
result["success"] = true
result["bureau_type"] = bureau_type
result["list"] = bureau_tab

--mysql放回连接池
mysql_db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false)
ngx.print(tostring(cjson.encode(result)))