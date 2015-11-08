local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

local cjson = require "cjson"

--学科ID
if args["subject_id"] == nil or args["subject_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"subject_id参数错误！\"}")
    return
end
local subject_id = args["subject_id"]

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


local res = mysql_db:query("SELECT structure_id,structure_id_char,scheme_id_int,scheme_id_char FROM t_resource_structure WHERE scheme_id_int = (SELECT scheme_id FROM t_resource_scheme WHERE subject_id = "..subject_id..") LIMIT 1")

local structure_id_int = res[1]["structure_id"]
local structure_id_char = res[1]["structure_id_char"]
local scheme_id_int = res[1]["scheme_id_int"]
local scheme_id_char = res[1]["scheme_id_char"]

local result = {} 
result["success"] = true
result["structure_id_int"] = structure_id_int
result["structure_id_char"] = structure_id_char
result["scheme_id_int"] = scheme_id_int
result["scheme_id_char"] = scheme_id_char

--mysql放回连接池
mysql_db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false)
ngx.print(tostring(cjson.encode(result)))

