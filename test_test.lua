#ngx.header.content_type = "text/plain;charset=utf-8"
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
local res = ""
local result = ""
local pageSize = 5
local pageNumber = 1
res = db:query("select EXTENSION_ID FROM T_RESOURCE_EXTENSION limit 0,5;")

local totalRow = #res

local offset = pageSize*pageNumber-pageSize

for i=1,#res do
  local str = res[i]["EXTENSION_ID"]

  result = result..str..","
end

ngx.say(result)
