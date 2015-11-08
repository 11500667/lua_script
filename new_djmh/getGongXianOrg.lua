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

local sql = mysql_db:query("SELECT t1.bureau_id,t3.org_name,COUNT(1)+(SELECT COUNT(1) FROM t_sjk_paper_info WHERE PERSON_ID IN (SELECT PERSON_ID FROM t_base_person WHERE BUREAU_ID = t1.bureau_id AND B_USE=1) AND GROUP_ID = "..bureau_id.."  and B_DELETE = 0) AS count FROM t_base_person t1 INNER JOIN t_resource_info t2 on t1.PERSON_ID=t2.PERSON_ID INNER JOIN t_base_organization t3 on t1.BUREAU_ID=t3.ORG_ID WHERE  t1.DISTRICT_ID = "..bureau_id.." AND t2.GROUP_ID = "..bureau_id.." AND t2.res_type IN (1,2,4,5) AND t2.ts>2015042018254400372  AND RELEASE_STATUS IN (1,3) GROUP BY BUREAU_ID ORDER BY COUNT(1) DESC LIMIT "..show_size..";")

local info_tab = {}
for i=1,#sql do
	local info_res = {}
	info_res["org_id"] = sql[i]["bureau_id"]
	info_res["org_name"] = sql[i]["org_name"]
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

