local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

local cjson = require "cjson"

--bureau_id参数 单位ID
if args["bureau_id"] == nil or args["bureau_id"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"bureau_id参数错误！\"}")
	return
end
local bureau_id = args["bureau_id"]

--show_size参数 显示多少条
if args["show_size"] == nil or args["show_size"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"show_size参数错误！\"}")
	return
end
local show_size = args["show_size"]

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

local sql = mysql_db:query("select t1.person_id,t2.person_name,COUNT(1)+(SELECT COUNT(1) FROM t_sjk_paper_info WHERE PERSON_ID = t1.person_id AND GROUP_ID = "..bureau_id.."  and B_DELETE = 0) AS count from t_resource_info t1 INNER JOIN t_base_person t2 on t1.person_id = t2.person_id where t1.GROUP_ID = "..bureau_id.."  AND t1.res_type IN (1,2,4,5)  AND t1.ts>2015042218254400372 AND t1.RELEASE_STATUS IN (1,3) GROUP BY PERSON_ID ORDER BY COUNT(1) DESC LIMIT "..show_size..";")

local info_tab = {}
for i=1,#sql do
	local info_res = {}
	info_res["person_id"] = sql[i]["person_id"]
	info_res["person_name"] = sql[i]["person_name"]
	info_res["count"] = sql[i]["count"]
	info_tab[i] = info_res
end

local result = {} 
result["list"] = info_tab
result["success"] = true

--mysql放回连接池
mysql_db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false)
ngx.print(tostring(cjson.encode(result)))