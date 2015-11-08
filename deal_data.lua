local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

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
local sql = "SELECT t4.STAGE_NAME,t3.SUBJECT_NAME,T3.SUBJECT_ID,t1.RESOURCE_TITLE,t1.EXTENSION,t1.STRUCTURE_ID FROM t_resource_base t1 INNER JOIN t_resource_scheme t2 ON t1.SCHEME_ID = t2.SCHEME_ID INNER JOIN t_dm_subject t3 ON t2.SUBJECT_ID = t3.SUBJECT_ID INNER JOIN t_dm_stage T4 ON t3.STAGE_ID = T4.STAGE_ID ORDER BY t2.SUBJECT_ID LIMIT 0,10"
local list = db:query(sql);
local list2 = list

--连接redis服务器
local redis = require "resty.redis"
local cache = redis.new()
local ok,err = cache.connect(cache,v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local result = {}

for i=1,#list2 do
	 local structure_id = list2[i]["STRUCTURE_ID"]
     local curr_path = ""

     local structures = cache:zrange("structure_code_"..structure_id,0,-1)
     for j=1,#structures do
        local structure_info = cache:hmget("t_resource_structure_"..structures[j],"structure_name")
        curr_path = curr_path..structure_info[1].."->"
     end
    curr_path = string.sub(curr_path,0,#curr_path-2)
	local result2 = {}
	result2.XDKM = list2[i]["STAGE_NAME"]..list2[i]["SUBJECT_NAME"]
	result2.RESOURCE_TITLE = list2[i]["RESOURCE_TITLE"]
	result2.EXTENSION = list2[i]["EXTENSION"]
	result2.STRUCTURE_NAME = curr_path
	result[i] = result2
end


-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

local cjson = require "cjson"
cjson.encode_empty_table_as_object(false)
ngx.say(tostring(cjson.encode(result)))