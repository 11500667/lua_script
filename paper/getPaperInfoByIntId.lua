#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#陈丽月 2015-01-27
#描述：是根据试卷信息获取试卷基本信息
]]

local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--获取参数id，并判断参数是否正确
if args["id"] == nil or args["id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"id参数错误！\"}")
    return
end

local id = args["id"]
--获取参数paper_type，并判断参数是否正确
if args["paper_type"] == nil or args["paper_type"] == "" then
    ngx.say("{\"success\":false,\"info\":\"paper_type参数错误！\"}")
    return
end

local paper_type = args["paper_type"]
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);

-- 获取redis连接
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

local paper_name;
local resource_info_id;
local redis_info = {};

if paper_type=="1" then
    redis_info = cache:hmget("paper_"..id,"paper_id_char","paper_id_int","paper_name","paper_type","resource_info_id");
    paper_name = redis_info[3]
    resource_info_id= redis_info[5] 
else
	redis_info = cache:hmget("mypaper_"..id,"paper_id_char","paper_id_int","paper_name","paper_type","resource_info_id");
	paper_name = redis_info[3]
	resource_info_id= redis_info[5] 
	   
end
   local redis_info2;
   redis_info2= ssdb_db:multi_hget("resource_"..resource_info_id,"resource_format","resource_page","preview_status","for_urlencoder_url","for_iso_url","file_id");


local result = {};
result.iid                = id
result.paper_id           = redis_info[1]
result.paper_id_int       = redis_info[2]
result.paper_name         = paper_name
result.paper_source       = redis_info[4]
result.extenstion         = redis_info2[2]
result.page               = redis_info2[4]
result.preview_status     = redis_info2[6]
result.for_urlencoder_url = redis_info2[8]
result.for_iso_url        = redis_info2[10]
result.url_code           = ngx.escape_uri(paper_name);
result.file_id            = redis_info2[12]
result.success            = true;

--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size);
ngx.say(cjson.encode(result));