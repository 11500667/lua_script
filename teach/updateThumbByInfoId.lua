local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--资源的info_id
if args["info_id"] == nil or args["info_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"info_id参数错误！\"}")
    return
end
local info_id = args["info_id"]

--资源的thumb_id
if args["thumb_id"] == nil or args["thumb_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"thumb_id参数错误！\"}")
    return
end
local thumb_id = args["thumb_id"]

--MD5
if args["thumb_md5"] == nil or args["thumb_md5"] == "" then
    ngx.say("{\"success\":false,\"info\":\"thumb_md5参数错误！\"}")
    return
end
local thumb_md5 = args["thumb_md5"]

--SHA1
if args["thumb_sha1"] == nil or args["thumb_sha1"] == "" then
    ngx.say("{\"success\":false,\"info\":\"thumb_sha1参数错误！\"}")
    return
end
local thumb_sha1 = args["thumb_sha1"]

local cjson = require "cjson"

local myts = require "resty.TS";
local ts =  myts.getTs();

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
local redis_db = redis:new()
local ok,err = redis_db:connect(v_redis_ip,v_redis_port)
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

local result = {}

local resource_id_int_res = mysql_db:query("SELECT resource_id_int FROM t_resource_info WHERE id = "..info_id..";")
if #resource_id_int_res>0 then
        local resource_id_int = tostring(resource_id_int_res[1]["resource_id_int"])

        local update_base = mysql_db:query("UPDATE t_resource_base set thumb_id='"..thumb_id.."',thumb_md5='"..thumb_md5.."',thumb_sha1='"..thumb_sha1.."' WHERE resource_id_int="..resource_id_int..";")

        local update_info = mysql_db:query("UPDATE t_resource_info set thumb_id='"..thumb_id.."',update_ts="..ts.." WHERE resource_id_int="..resource_id_int..";")

		local sel_info = mysql_db:query("SELECT id FROM t_resource_info WHERE RESOURCE_ID_INT = "..resource_id_int);
		for i=1,#sel_info do
		    --redis_db:hset("resource_"..sel_info[i]["id"],"thumb_id",thumb_id)
		    ssdb_db:hset("resource_"..sel_info[i]["id"],"thumb_id",thumb_id)
		end

        result["success"] = true
else
        result["success"] = false
        result["info"] = "参数info_id未在找到！"
end

--放回到mysql连接池
mysql_db:set_keepalive(0,v_pool_size)
redis_db:set_keepalive(0,v_pool_size)
ssdb_db:set_keepalive(0,v_pool_size)
ngx.say(cjson.encode(result))
