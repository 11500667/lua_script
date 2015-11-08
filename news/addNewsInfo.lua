local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

local cjson = require "cjson"

--title参数
if args["title"] == nil or args["title"] == "" then
	ngx.print("{\"success\":false,\"info\":\"title参数错误！\"}")
	return
end
local title = args["title"]

--regist_id参数
if args["regist_id"] == nil or args["regist_id"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"regist_id参数错误！\"}")
	return
end
local regist_id = args["regist_id"]

--column_id参数
if args["column_id"] == nil or args["column_id"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"column_id参数错误！\"}")
	return
end
local column_id = args["column_id"]

--content参数
if args["content"] == nil or args["content"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"content参数错误！\"}")
	return
end
local content = args["content"]

--images参数
if args["image"] == nil or args["image"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"image参数错误！\"}")
	return
end
local images = args["image"]

local regist_person = ""
local regist_person_name = ""
local person_id = args["person_id"]
local person_name = args["person_name"]
if person_id and string.len(person_id) > 0 then
    regist_person = person_id
else
    regist_person = tostring(ngx.var.cookie_background_person_id)
end
if person_name and string.len(person_name) > 0 then
    regist_person_name = person_name
else
    regist_person_name = tostring(ngx.var.cookie_background_person_name)
end


--url解码
function decodeURI(s)
    s = string.gsub(s, '%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
    return s
end

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.print("{\"success\":false,\"info\":\""..err.."\"}")
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

local TS = require "resty.TS"
local create_ts = TS.getTs()
--插入MySQL查询条件

local isql = "INSERT INTO t_news_info (create_person, title, ts, update_ts, b_delete, column_id, regist_id) VALUES ("..regist_person.." ,"..ngx.quote_sql_str(title).." ,"..create_ts.." ,"..create_ts.." , 0 ,"..column_id..", "..regist_id..");"
--ngx.log(ngx.ERR,"============qqq"..isql)
local ins,err = mysql_db:query(isql)
--ngx.log(ngx.ERR,"============"..err)
--获取插入ID
local id = ins.insert_id;

local column_name = "无"
if column_id ~= "-1" then 
	local column_tab = mysql_db:query("select column_name from t_news_column where column_id = "..column_id..";")
	column_name = column_tab[1]["column_name"]
end

local ssdb_info = {}
ssdb_info["title"] = title
ssdb_info["content"] = content
ssdb_info["create_time"] = ngx.localtime()
ssdb_info["create_person"] = regist_person
ssdb_info["create_person_name"] = decodeURI(regist_person_name)
ssdb_info["column_id"] = column_id
ssdb_info["column_name"] = column_name
ssdb_info["regist_id"] = regist_id
ssdb_info["b_delete"] = "0"
ssdb_info["ts"] = create_ts
ssdb_info["image"] = image

ssdb_db:multi_hset("news_info_"..tostring(id),ssdb_info);

local bureau_id = mysql_db:query("select bureau_id from t_djmh_news where regist_id="..regist_id.." LIMIT 1")

if #bureau_id ~= 0 then
	redis_db:set("djmh_news_ts_"..bureau_id[1]["bureau_id"],"0")
end

-- 将mysql连接归还到连接池
mysql_db: set_keepalive(0, v_pool_size);
--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)

ngx.print("{\"success\":true}")



