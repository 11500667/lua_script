--[[
保存编辑后的区域均衡信息[mysql版]
@Author  chenxg
@Date    2015-06-01
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local quote = ngx.quote_sql_str

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
local region_id = args["region_id"]
local name = args["name"]
local description = args["description"]
local logo_url = args["logo_url"]

--判断参数是否为空
if not region_id or string.len(region_id) == 0 
  or not name or string.len(name) == 0 
  or not description or string.len(description) == 0 
  or not logo_url or string.len(logo_url) == 0 
  then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
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
--存储详细信息
local updateSql = "update t_qyjh_qyjhs set name="..quote(name)..",description="..quote(description)..",logo_url="..quote(logo_url).." where qyjh_id= "..region_id;
local results, err, errno, sqlstate = db:query(updateSql);
if not results then
	ngx.say("{\"success\":\"false\",\"info\":\"修改区域均衡失败！\"}");
    return;
end

--return
say("{\"success\":true,\"qyjh_id\":\""..region_id.."\",\"name\":\""..name.."\",\"b_use\":1,\"info\":\"编辑成功！\"}")

--mysql放回连接池
db:set_keepalive(0,v_pool_size)
