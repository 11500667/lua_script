local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--工作室ID
if args["workroom_id"] == nil or args["workroom_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"workroom_id参数错误！\"}")
    return
end
local workroom_id = args["workroom_id"]

--6教育科研，7教学研究
if args["type_id"] == nil or args["type_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"type_id参数错误！\"}")
    return
end
local type_id = args["type_id"]

--获取人员ID
if args["person_id"] == nil or args["person_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
    return
end
local person_id = args["person_id"]

--获取pageSize参数
if args["pageSize"] == nil or args["pageSize"] == "" then
    ngx.say("{\"success\":false,\"info\":\"pageSize参数错误！\"}")
    return
end
local pageSize = args["pageSize"]

--获取pageNumber参数
if args["pageNumber"] == nil or args["pageNumber"] == "" then
    ngx.say("{\"success\":false,\"info\":\"pageNumber参数错误！\"}")
    return
end
local pageNumber = args["pageNumber"]

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
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

local offset = pageSize*pageNumber-pageSize
local limit = pageSize
local str_maxmatches = 3000

ngx.log(ngx.ERR,"@@@@@@@@@".."SELECT SQL_NO_CACHE id FROM t_base_publish_kyyj_sphinxse WHERE query='filter=b_delete=0;filter=pub_type,1;filter=person_id,"..person_id..";filter=pub_target,"..workroom_id..";filter=obj_type,"..type_id..";sort=attr_desc:ts;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;".."@@@@@@@@@")

local res = db:query("SELECT SQL_NO_CACHE id FROM t_base_publish_kyyj_sphinxse WHERE query='filter=b_delete=0;filter=pub_type,1;filter=person_id,"..person_id..";filter=pub_target,"..workroom_id..";filter=obj_type,"..type_id..";sort=attr_desc:ts;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")

--去第二个结果集中的Status中截取总个数
local res1 = db:read_result()
local _,s_str = string.find(res1[1]["Status"],"found: ")
local e_str = string.find(res1[1]["Status"],", time:")
local totalRow = string.sub(res1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

local resource_info = ""
for i=1,#res do    
    local iid = cache:hget("publish_"..res[i]["id"],"obj_info_id")
    ngx.log(ngx.ERR,"@@@@@@@@@"..iid.."@@@@@@@@@")
    local str = "{\"iid\":\""..iid.."\",\"is_file\":\"##\",\"resource_id_int\":\"##\",\"resource_id_char\":\"##\",\"resource_info_id\":\"##\",\"resource_title\":\"##\",\"resource_type\":\"##\",\"resource_type_name\":\"##\",\"resource_size\":\"##\",\"create_time\":\"##\",\"share_time\":\"##\",\"share_person_id\":\"##\",\"share_person_name\":\"##\",\"self_structure_id\":\"##\",\"scheme_id_int\":\"##\",\"width\":\"##\",\"height\":\"##\",\"resource_format\":\"##\",\"resource_page\":\"##\",\"file_id\":\"##\",\"thumb_id\":\"##\",\"preview_status\":\"##\",\"for_urlencoder_url\":\"##\",\"for_iso_url\":\"##\",\"down_count\":\"##\"}"
    local cloud_values = cache:hmget("cloud_resource_"..iid,"res_type","resource_id_int","resource_id_char","resource_info_id","resource_title","resource_type","resource_type_name","resource_size","create_time","create_time","share_person","share_person_name","self_structure_id","scheme_id_int")    
    for j=1,#cloud_values do        
        str = string.gsub(str,"##",tostring(cloud_values[j]),1)
    end
    if cloud_values[1] == "1" then
        local resource_info_id = tostring(cloud_values[4])
        --local  resource_values = cache:hmget("resource_"..resource_info_id,"width","height","resource_format","resource_page","file_id","thumb_id","preview_status","for_urlencoder_url","for_iso_url","down_count")   
		local  resource_values = ssdb_db:multi_hget("resource_"..resource_info_id,"width","height","resource_format","resource_page","file_id","thumb_id","preview_status","for_urlencoder_url","for_iso_url","down_count")   
        for j=1,#resource_values,2 do            
            str = string.gsub(str,"##",tostring(resource_values[j+1]),1)            
        end
    else
        for j=1,8 do            
            str = string.gsub(str,"##","-1",1)           
        end
    end
    resource_info = resource_info..str..","
end

--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0,v_pool_size)

resource_info = string.sub(resource_info,0,#resource_info-1)
ngx.say("{\"success\":\"true\",\"totalRow\":\""..totalRow.."\",\"totalPage\":\""..totalPage.."\",\"pageNumber\":\""..pageNumber.."\",\"pageSize\":\""..pageSize.."\",\"list\":["..resource_info.."]}")








