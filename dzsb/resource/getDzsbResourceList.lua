#ngx.header.content_type = "text/plain;charset=utf-8"

local cjson = require "cjson"

local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end
--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local pageSize = tostring(args["pageSize"])
if pageSize == "nil" then
    ngx.say("{\"success\":false,\"info\":\"pageSize参数错误！\"}")
    return
end

local identity_id = tostring(args["identity_id"])
if identity_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"identity_id丢失！\"}")
    return
end

local pageNumber = tostring(args["pageNumber"])
if pageNumber == "nil" then
    ngx.say("{\"success\":false,\"info\":\"pageNumber丢失！\"}")
    return
end

local person_id = tostring(args["person_id"])
if person_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"person_id丢失！\"}")
    return
end

local subject_id = tostring(args["subject_id"])
if subject_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"subject_id丢失！\"}")
    return
end

local keyword = tostring(args["keyword"])
if keyword == "nil" then
    ngx.say("{\"success\":false,\"info\":\"keyword丢失！\"}")
    return
end

local type_id = tostring(args["type"])
if type_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"type丢失！\"}")
    return
end

local sort = tostring(args["sort"])
if sort == "nil" then
    ngx.say("{\"success\":false,\"info\":\"sort丢失！\"}")
    return
end

--拼接查询条件
local subject_str ="";
local type_str = "";
local sort_str = "";
--local keyword_str = "";

if subject_id ~= "-1" then
	subject_str = "filter=subject_id,"..subject_id..";";
end

if type_id ~= "-1" then
	type_str = "filter=bk_type,"..type_id..";";
else 
    type_str = "filter=bk_type,102,104,107,109;";
end

if #keyword ~= "0" then
        keyword = ngx.decode_base64(keyword)..";"
end

 local str_group = "IF(person_id="..person_id..",1,0) "
    local group_list = cache:smembers("group_"..person_id.."_"..identity_id)
    for i=1,#group_list do
        str_group = str_group.." OR IF(group_id="..group_list[i]..",1,0)"
    end
	
--拼接排序
if sort == "1" then
   sort_str="sort=attr_desc:ts;";
elseif sort == "2" then
   sort_str="sort=attr_asc:ts;";
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

local str_maxmatches = "100000"
local res = ""
ngx.log(ngx.ERR,"SELECT SQL_NO_CACHE id FROM t_resource_info_sphinxse  WHERE query=\'"..keyword..type_str..subject_str.."filter=res_type,2;select=("..str_group..") as match_qq;filter= match_qq, 1;filter=release_status,1,3;"..sort_str.."maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")
    res = db:query("SELECT SQL_NO_CACHE id FROM t_resource_info_sphinxse  WHERE query=\'"..keyword..type_str..subject_str.."filter=res_type,2;select=("..str_group..") as match_qq;filter= match_qq, 1;filter=release_status,1,3;"..sort_str.."maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")
local resourceUtil = require "base.resource.model.ResourceUtil";
local resourceJson = resourceUtil:getResourceInfoByIds(res)
--去第二个结果集中的Status中截取总个数
local res1 = db:read_result()
local _,s_str = string.find(res1[1]["Status"],"found: ")
local e_str = string.find(res1[1]["Status"],", time:")
local totalRow = string.sub(res1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)


--mysql放回连接池
db:set_keepalive(0,v_pool_size)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)
local result = {} 
result["list"] = resourceJson
result["totalRow"] = totalRow
result["totalPage"] = totalPage
result["pageNumber"] = pageNumber
result["pageSize"] = pageSize
result["success"] = true

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))
