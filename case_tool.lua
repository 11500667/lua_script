#ngx.header.content_type = "text/plain;charset=utf-8"
local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)

--判断是否有person_id的cookie信息
if cookie_person_id == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"参数错误！\"}")
    return
end
--判断是否有identity_id的cookie信息
if cookie_identity_id == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"参数错误！\"}")
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

--获得案例id
local case_info_id = tostring(args["case_id"])
if case_info_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"case_id参数错误！\"}")
    return
end

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--根据案例id获得对应的工具id
local tool_info_id = cache:get("case_"..case_info_id)


if tool_info_id == ngx.null then
        ngx.say("{\"success\":false,\"info\":\"无法找到该案例对应的工具\"}")
   return
end

--[[
--根据工具id获得对应的资源信息
local tool_res = cache:hmget("resource_"..tool_info_id,"for_urlencoder_url","resource_id_char","preview_status","resource_size","height","resource_title","resource_page","resource_size_int","scheme_id_int","file_id","resource_type","resource_format","resource_type_name","for_iso_url","resource_id_int","parent_structure_name","person_name","bk_type_name","width","create_time","down_count","beike_type","release_status","thumb_id","structure_id")


local tool_res_info = "{\"success\":\"true\",\"res_info\":{\"iid\":\""..tool_info_id.."\",\"for_urlencoder_url\":\""..tool_res[1].."\",\"resource_id_char\":\""..tool_res[2].."\",\"preview_status\":\""..tool_res[3].."\",\"resource_size\":\""..tool_res[4].."\",\"height\":\""..tool_res[5].."\",\"resource_title\":\""..tool_res[6].."\",\"resource_page\":\""..tool_res[7].."\",\"resource_size_int\":\""..tool_res[8].."\",\"scheme_id_int\":\""..tool_res[9].."\",\"file_id\":\""..tool_res[10].."\",\"resource_type\":\""..tool_res[11].."\",\"resource_format\":\""..tool_res[12].."\",\"resource_type_name\":\""..tool_res[13].."\",\"for_iso_url\":\""..tool_res[14].."\",\"resource_id_int\":\""..tool_res[15].."\",\"parent_structure_name\":\""..tool_res[16].."\",\"person_name\":\""..tool_res[17].."\",\"bk_type_name\":\""..tool_res[18].."\",\"width\":\""..tool_res[19].."\",\"create_time\":\""..tool_res[20].."\",\"down_count\":\""..tool_res[21].."\",\"beike_type\":\""..tool_res[22].."\",\"release_status\":\""..tool_res[23].."\",\"thumb_id\":\""..tool_res[24].."\",\"structure_id\":\""..tool_res[25].."\"}}"

]]

-- lzy 2015-7-9

local res = {};
local tab={};
tab.id = tool_info_id;
table.insert(res,tab);
local resourceUtil = require "base.resource.model.ResourceUtil";
local resourceJson = resourceUtil:getResourceInfoByIds(res)

local tool_res_info = "{\"success\":\"true\",\"res_info\":{\"iid\":\""..tool_info_id.."\",\"for_urlencoder_url\":\""..resourceJson[1]["for_urlencoder_url"].."\",\"resource_id_char\":\""..resourceJson[1]["resource_id_char"].."\",\"preview_status\":\""..resourceJson[1]["preview_status"].."\",\"resource_size\":\""..resourceJson[1]["resource_size"].."\",\"height\":\""..resourceJson[1]["height"].."\",\"resource_title\":\""..resourceJson[1]["resource_title"].."\",\"resource_page\":\""..resourceJson[1]["resource_page"].."\",\"resource_size_int\":\""..resourceJson[1]["resource_size_int"].."\",\"scheme_id_int\":\""..resourceJson[1]["scheme_id_int"].."\",\"file_id\":\""..resourceJson[1]["file_id"].."\",\"resource_type\":\""..resourceJson[1]["resource_type"].."\",\"resource_format\":\""..resourceJson[1]["resource_format"].."\",\"resource_type_name\":\""..resourceJson[1]["resource_type_name"].."\",\"for_iso_url\":\""..resourceJson[1]["for_iso_url"].."\",\"resource_id_int\":\""..resourceJson[1]["resource_id_int"].."\",\"parent_structure_name\":\""..resourceJson[1]["parent_structure_name"].."\",\"person_name\":\""..resourceJson[1]["person_name"].."\",\"bk_type_name\":\""..resourceJson[1]["bk_type_name"].."\",\"width\":\""..resourceJson[1]["width"].."\",\"create_time\":\""..resourceJson[1]["create_time"].."\",\"down_count\":\""..resourceJson[1]["down_count"].."\",\"beike_type\":\""..resourceJson[1]["beike_type"].."\",\"release_status\":\""..resourceJson[1]["release_status"].."\",\"thumb_id\":\""..resourceJson[1]["thumb_id"].."\",\"structure_id\":\""..resourceJson[1]["structure_id"].."\"}}"


-- lzy 2015-7-9

--redis放回连接池
cache:set_keepalive(0,v_pool_size)

ngx.say(tool_res_info)
