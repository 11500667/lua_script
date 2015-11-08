#ngx.header.content_type = "text/plain;charset=utf-8"
local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)

--判断是否有person_id的cookie信息
if cookie_person_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"person_id的cookie信息参数错误！\"}")
    return
end
--判断是否有identity_id的cookie信息
if cookie_identity_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"identity_id的cookie信息参数错误！\"}")
    return
end

local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--资源charid
local resource_id_char = tostring(args["resource_id_char"])
if resource_id_char == "nil" then
    ngx.say("{\"success\":false,\"info\":\"resource_id_char参数错误！\"}")
    return
end
--根据resource_id_char获得对应的info_id
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


local sql_info_id = "SELECT id FROM  t_resource_info WHERE resource_id_char = '"..resource_id_char.."' and release_status = 1";
 local res, err, errno, sqlstate = db:query(sql_info_id)
	 if not res then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	 return
    end
local info_id = res[1]["id"];
 ngx.log(ngx.ERR,"--------"..info_id);
--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache.connect(cache,v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

-- lzy 2015-7-9

local res = {};
local tab={};
tab.id = info_id;
table.insert(res,tab);
local resourceUtil = require "base.resource.model.ResourceUtil";
local resourceJson = resourceUtil:getResourceInfoByIds(res)
--[[
local res_info_null = cache:hget("resource_"..info_id)
if res_info_null == ngx.null then
    ngx.say("{\"success\":false,\"info\":\"无法找到该资源！\"}")
    return
end
]]
--根据工具id获得对应的资源信息
--local tool_res = cache:hmget("resource_"..info_id,"for_urlencoder_url","resource_id_char","preview_status","resource_size","height","resource_title","resource_page","resource_size_int","scheme_id_int","file_id","resource_type","resource_format","resource_type_name","for_iso_url","resource_id_int","person_name","bk_type_name","width","create_time","down_count","beike_type","release_status","thumb_id","structure_id")


local res_info = "{\"success\":\"true\",\"res_info\":{\"iid\":\""..info_id.."\",\"for_urlencoder_url\":\""..resourceJson[1]["for_urlencoder_url"].."\",\"resource_id_char\":\""..resourceJson[1]["resource_id_char"].."\",\"preview_status\":\""..resourceJson[1]["preview_status"].."\",\"resource_size\":\""..resourceJson[1]["resource_size"].."\",\"height\":\""..resourceJson[1]["height"].."\",\"resource_title\":\""..resourceJson[1]["resource_title"].."\",\"resource_page\":\""..resourceJson[1]["resource_page"].."\",\"resource_size_int\":\""..resourceJson[1]["resource_size_int"].."\",\"scheme_id_int\":\""..resourceJson[1]["scheme_id_int"].."\",\"file_id\":\""..resourceJson[1]["file_id"].."\",\"resource_type\":\""..resourceJson[1]["resource_type"].."\",\"resource_format\":\""..resourceJson[1]["resource_format"].."\",\"resource_type_name\":\""..resourceJson[1]["resource_type_name"].."\",\"for_iso_url\":\""..resourceJson[1]["for_iso_url"].."\",\"resource_id_int\":\""..resourceJson[1]["resource_id_int"].."\",\"person_name\":\""..resourceJson[1]["person_name"].."\",\"bk_type_name\":\""..resourceJson[1]["bk_type_name"].."\",\"width\":\""..resourceJson[1]["width"].."\",\"create_time\":\""..resourceJson[1]["create_time"].."\",\"down_count\":\""..resourceJson[1]["down_count"].."\",\"beike_type\":\""..resourceJson[1]["beike_type"].."\",\"release_status\":\""..resourceJson[1]["release_status"].."\",\"thumb_id\":\""..resourceJson[1]["thumb_id"].."\",\"structure_id\":\""..resourceJson[1]["structure_id"].."\"}}"


-- lzy 2015-7-9

--redis放回连接池
cache:set_keepalive(0,v_pool_size)
-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

ngx.say(res_info)
