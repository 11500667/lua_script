#ngx.header.content_type = "text/plain;charset=utf-8"
local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)

local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--资源charid
local resource_md5 = tostring(args["resource_md5"])
if resource_md5 == "nil" then
    ngx.say("{\"success\":false,\"info\":\"resource_md5参数错误！\"}")
    return
end
--根据resource_id_char获得对应的info_id
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

local sql_base = "SELECT FILE_ID FROM t_resource_base WHERE FILE_MD5 = '"..resource_md5.."'";
 local res, err, errno, sqlstate = db:query(sql_base)
	 if not res then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	 return
    end

-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end
	
	if #res==0 then
	  ngx.say("{\"success\":true,\"file_id\":\"-1\"}")
	else 
	  ngx.say("{\"success\":true,\"file_id\":\""..res[1]["FILE_ID"].."\"}")
	end




