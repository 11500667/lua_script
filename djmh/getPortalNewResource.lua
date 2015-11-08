local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

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

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--url加码
function encodeURI(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end

--拼group_id条件
local group_str = "filter=group_id,1,"..bureau_id..";"


--获取资源的最新资源
local res_new_tab = {}
local res_sql = mysql_db:query("SELECT SQL_NO_CACHE id FROM t_resource_info_sphinxse WHERE query='"..group_str.."filter=res_type,1;filter=release_status,1,3;groupby=attr:resource_id_int;groupsort=ts desc;limit="..show_size.."';")
for i=1,#res_sql do
    local res_info = ssdb_db:multi_hget("resource_"..res_sql[i]["id"],"resource_title","resource_format","resource_page","file_id","thumb_id","preview_status","width","height","for_urlencoder_url","for_iso_url","down_count","scheme_id_int","resource_id_int")
    --根据版本ID获取该版本属于哪个学科    
    local subject_name = ssdb_db:hget("t_resource_scheme_"..res_info[24],"subject_name")[1]    
    local res_info_tab = {}
    res_info_tab["resource_title"] = res_info[2]	
    res_info_tab["resource_format"] = res_info[4]
    res_info_tab["resource_page"] = res_info[6]
    res_info_tab["file_id"] = res_info[8]
    res_info_tab["thumb_id"] = res_info[16]
    res_info_tab["preview_status"] = res_info[12]
    res_info_tab["width"] = res_info[14]
    res_info_tab["height"] = res_info[16]
    res_info_tab["for_urlencoder_url"] = res_info[18]
    res_info_tab["for_iso_url"] = res_info[20]
    res_info_tab["browse_count"] = res_info[22]
    res_info_tab["resource_id_int"] = res_info[26]
    res_info_tab["subject"] = subject_name
	res_info_tab["url_code"] = encodeURI(res_info[2])
    res_new_tab[i] = res_info_tab    
end

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
mysql_db:set_keepalive(0,v_pool_size)

local result = {}
result["success"] = true
result["list"] = res_new_tab

cjson.encode_empty_table_as_object(false)
ngx.print(tostring(cjson.encode(result)))
