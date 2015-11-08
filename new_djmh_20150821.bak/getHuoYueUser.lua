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

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--连接redis服务器
local redis = require "resty.redis"
local redis_db = redis:new()
local ok,err = redis_db:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local i_count = 1
local info_tab = {}

local is_sq = ""
if tonumber(bureau_id)>200000 and tonumber(bureau_id)<300000 then
	is_sq = "CITY_ID"
else
	is_sq = "DISTRICT_ID"
end

local person_id_old = mysql_db:query("SELECT person_id FROM t_base_person WHERE "..is_sq.."="..bureau_id.." AND B_USE =0")
for i=1,#person_id_old do
	ssdb_db:zdel("huoyue_user_"..bureau_id,person_id_old[i])
end

local info = ssdb_db:zrrange("huoyue_user_"..bureau_id,0,show_size)

if #info>1 then
	for i=1,#info,2 do		
		local info_res = {}
		info_res["person_id"] = info[i]
		info_res["person_name"] = redis_db:hget("person_"..info[i].."_5","person_name")		
		info_res["count"] = info[i+1]
		info_tab[i_count] = info_res
		i_count = i_count +1
	end
end

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)
--redis放回连接池
redis_db:set_keepalive(0,v_pool_size)

local result = {} 
result["list"] = info_tab
result["success"] = true

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))








