local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--ngx.log(ngx.ERR, "start_min===========>"..start_min);
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

local select_sql = "SELECT START_HOUR,START_MIN,END_HOUR,END_MIN FROM T_BAG_YULETIME WHERE ID = 1"

local time_list = db:query(select_sql);
local returnjson = {}

returnjson["success"] = true
returnjson["startTime"] = time_list[1]["START_HOUR"]..":"..time_list[1]["START_MIN"]
returnjson["endTime"] = time_list[1]["END_HOUR"]..":"..time_list[1]["END_MIN"]
-- 
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end
local cjson = require "cjson"
cjson.encode_empty_table_as_object(false)
ngx.say(tostring(cjson.encode(returnjson)))