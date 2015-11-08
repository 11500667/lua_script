local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

if tostring(args["resource_ids"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"resource_ids参数错误\"}")    
    return
end
local resource_ids = tostring(args["resource_ids"])
local resource_ids_list = Split(resource_ids,",");
local res_str = ""
for i=1,#resource_ids_list do
	res_str = res_str.."'"..resource_ids_list[i].."',"
end
if res_str ~= "" then
	res_str = string.sub(res_str,0,#res_str-1)
end

--连接数据库
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
local sql = "SELECT resource_id, update_logo,create_time FROM t_bag_resource_info WHERE resource_id in("..res_str..")"
local list = db:query(sql);
local list2 = list

local result = {}
result["success"] = true
result["list"] = list2

-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

local cjson = require "cjson"
cjson.encode_empty_table_as_object(false)
ngx.say(tostring(cjson.encode(result)))