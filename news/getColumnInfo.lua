local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

--regist_id参数
if args["regist_id"] == nil or args["regist_id"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"regist_id参数错误！\"}")
	return
end
local regist_id = args["regist_id"]

--local regist_person = tostring(ngx.var.cookie_background_person_id)

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

--local column_sql = mysql_db:query("SELECT column_id,column_name,parent_id FROM t_news_column WHERE create_person="..regist_person.." AND regist_id="..regist_id.." AND b_delete=0")
local column_sql = mysql_db:query("SELECT column_id,column_name,parent_id FROM t_news_column WHERE regist_id="..regist_id.." AND b_delete=0")

local column_tab = {}
for i=1,#column_sql do
	local column_info = {}
	column_info["column_id"] = column_sql[i]["column_id"]
	column_info["column_name"] = column_sql[i]["column_name"]
	column_info["parent_id"] = column_sql[i]["parent_id"]
	column_tab[i] = column_info
end

local result = {}
result["success"] = true
result["list"] = column_tab

-- 将mysql连接归还到连接池
mysql_db:set_keepalive(0, v_pool_size);

cjson.encode_empty_table_as_object(false)
ngx.print(cjson.encode(result))

