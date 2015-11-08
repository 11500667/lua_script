local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

local cjson = require "cjson"

--评比ID
if args["login_name"] == nil or args["login_name"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"login_name参数错误！\"}")
    return
end
local login_name = args["login_name"]

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

ngx.log(ngx.ERR, "**********东师理想微课大赛*****验证注册登录名是否存在开始**********");
local countsql = "select count(*) as count from (select login_name  from t_dswk_login where login_name='"..login_name.."' union all select login_name from t_sys_loginperson where login_name ='"..login_name.."') a "
ngx.log(ngx.ERR,countsql)
local countsql_res = db:query(countsql)
if not countsql_res then
  ngx.say("{\"success\":\"false\",\"info\":\"查询过程出错！\"}");
  ngx.log(ngx.ERR, "err: ".. err);
end
local returnResult = {}
if tonumber(countsql_res[1]["count"]) == 0 then
	returnResult.success = true
	returnResult.info = "可以注册"
else
	returnResult.success = false
	returnResult.info = "登录名重复，不允许注册"
end

db:set_keepalive(0,v_pool_size)
cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(returnResult))
ngx.log(ngx.ERR, "**********东师理想微课大赛*****验证注册登录名是否存在结束**********");		
