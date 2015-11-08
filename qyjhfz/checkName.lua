--[[
校验大学区、协作体、活动重名
@Author  chenxg
@Date    2015-07-01
--]]

local say = ngx.say
local quote = ngx.quote_sql_str

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"
cjson.encode_empty_table_as_object(false);

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
local name = args["name"]
local qyjh_id = args["qyjh_id"]
local dxq_id = args["dxq_id"]
-- 1大学区2协作体3活动
local stype_id = args["stype_id"]


--判断参数是否为空
if not name or string.len(name) == 0 
 or not stype_id or string.len(stype_id) == 0
 or not qyjh_id or string.len(qyjh_id) == 0
   then
    say("{\"success\":false,\"info\":\"name or stype_id or qyjh_id 参数错误！\"}")
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
local sql = "";
if stype_id == "1" then
	sql = "select dxq_id from t_qyjh_dxq where qyjh_id="..quote(qyjh_id).." and dxq_name="..quote(name).." and b_delete=0";	
elseif stype_id == "2" then
	if not dxq_id or string.len(dxq_id) == 0
	   then
		say("{\"success\":false,\"info\":\"dxq_id 参数错误！\"}")
		return
	end
	sql = "select xzt_id from t_qyjh_xzt where qyjh_id="..quote(qyjh_id).." and dxq_id="..quote(dxq_id).." and xzt_name="..quote(name).." and b_delete=0";	
else
	if not dxq_id or string.len(dxq_id) == 0
	   then
		say("{\"success\":false,\"info\":\"dxq_id 参数错误！\"}")
		return
	end
	sql = "select hd_id from t_qyjh_hd where qyjh_id="..quote(qyjh_id).." and dxq_id="..quote(dxq_id).." and hd_name="..quote(name).." and b_delete=0";	
end
local res = mysql_db:query(sql)
local temp = {}
temp.success = true
if #res>0 then 
	temp.success = false
end
say(cjson.encode(temp))
--mysql放回连接池
mysql_db:set_keepalive(0,v_pool_size)
