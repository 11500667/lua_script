local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--参数
local start_hour = tostring(args["start_hour"])
local start_min = tostring(args["start_min"])
local end_hour = tostring(args["end_hour"])
local end_min = tostring(args["end_min"])

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

local del_sql = "DELETE FROM T_BAG_YULETIME WHERE ID = 1"
db:query(del_sql);

local add_sql = "INSERT INTO T_BAG_YULETIME(ID,START_HOUR,START_MIN,END_HOUR,END_MIN) VALUES (1,'"..start_hour.."','"..start_min.."','"..end_hour.."','"..end_min.."')"
db:query(add_sql);
-- 
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

--ngx.say("<script>callback2()</script>");