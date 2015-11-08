local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)

--1.获得参数方法
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

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


local subject_id  = tostring(args["subject_id"]);

if args["subject_id"] == nil or args["subject_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"subject_id参数错误！\"}")
    return
end


ngx.log(ngx.ERR,"============="..subject_id)
--[[
--判断是否有结点subject_id参数
if subject_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"subject_id参数错误！\"}")
    return
end
]]
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

--UFT_CODE
local function urlencode(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end

local baginfo = cache:hmget("packinfo_current_"..cookie_person_id.."_"..cookie_identity_id.."_"..subject_id,"bag_id","create_or_update","bag_name","bag_node","bag_status","structure_id","structure_code","scheme_id","subject_name","parent_id_str","is_root")
if baginfo[1]==ngx.null then
    ngx.say("{\"success\":true,\"content\":{}}")
    return
end
local bag_id = baginfo[1]
local baginfo_json = "\"bag_id\":\""..bag_id.."\",\"create_or_update\":\""..baginfo[2].."\",\"bag_name\":\""..baginfo[3].."\",\"bag_node\":\""..baginfo[4].."\",\"bag_status\":"..baginfo[5]..",\"structure_id\":\""..baginfo[6].."\",\"structure_code\":\""..baginfo[7].."\",\"scheme_id\":\""..baginfo[8].."\",\"subject_name\":\""..baginfo[9].."\",\"parent_id_str\":\""..baginfo[10].."\",\"is_root\":\""..baginfo[11].."\""

local res_list_json = ""
local res_list = cache:hgetall("pack_list_current_"..bag_id)
local cjson22 = require "cjson";
ngx.log(ngx.ERR, "[sj_log]_[prepare_Course]-> hgetall pack_list_current_" .. bag_id .. " -> [", cjson22.encode(res_list), "]");
for i=1,#res_list,2 do
    local type_id = res_list[i+1]
    --资源
    if tostring(type_id)=="1" then
          --[[
	local res_info = cache:hmget("resource_"..res_list[i],"file_id","resource_title","resource_format","resource_page","preview_status","for_urlencoder_url","for_iso_url","height","width")
        res_list_json = res_list_json.."{\"res_id_char\":\""..res_list[i].."\",\"file_id\":\""..res_info[1].."\",\"title\":\""..res_info[2].."\",\"res_format\":\""..res_info[3].."\",\"type_id\":\"1\",\"type_name\":\"资源\",\"page\":\""..res_info[4].."\",\"preview_status\":\""..res_info[5].."\",\"for_urlencoder_url\":\""..res_info[6].."\",\"for_iso_url\":\""..res_info[7].."\",\"url_code\":\""..urlencode(res_info[2]).."\",\"height\":\""..res_info[8].."\",\"width\":\""..res_info[9].."\"},"

        ]]

        local res = {};
        local tab={};
        tab.id = res_list[i];
        table.insert(res,tab);
        local resourceUtil = require "base.resource.model.ResourceUtil";
        local resourceJson = resourceUtil:getResourceInfoByIds(res)

        res_list_json = res_list_json.."{\"res_id_char\":\""..res_list[i].."\",\"file_id\":\""..resourceJson[1]["file_id"].."\",\"title\":\""..resourceJson[1]["resource_title"].."\",\"res_format\":\""..resourceJson[1]["resource_format"].."\",\"type_id\":\"1\",\"type_name\":\"资源\",\"page\":\""..resourceJson[1]["resource_page"].."\",\"preview_status\":\""..resourceJson[1]["preview_status"].."\",\"for_urlencoder_url\":\""..resourceJson[1]["for_urlencoder_url"].."\",\"for_iso_url\":\""..resourceJson[1]["for_iso_url"].."\",\"url_code\":\""..urlencode(resourceJson[1]["resource_title"]).."\",\"height\":\""..resourceJson[1]["height"].."\",\"width\":\""..resourceJson[1]["width"].."\"},"

    end

    --试题
    if tostring(type_id)=="2" then
	local res_info = cache:hmget("pack_current_question_"..res_list[i],"file_id")
	res_list_json = res_list_json.."{\"res_id_char\":\""..res_list[i].."\",\"file_id\":\""..res_info[1].."\",\"title\":\"\",\"res_format\":\"png\",\"type_id\":\"2\",\"type_name\":\"试题\",\"page\":\"0\",\"preview_status\":\"1\",\"for_urlencoder_url\":\"\",\"for_iso_url\":\"\",\"url_code\":\"\"},"
    end

    --试卷
    if tostring(type_id)=="3" then
	local res_info = cache:hmget("paperinfo_"..res_list[i],"paper_name","paper_type","for_urlencoder_url","for_iso_url", "resource_info_id")
    local resInfoId   = res_info[5];
    local paperFileId = "";
    local paperName   = res_info[1];
    local paperFormat = "";
    local paperFileId = "";
    if res_info[2] == "2" then


        paperResInfo = ssdb_db: multi_hget("resource_" .. resInfoId, "file_id", "resource_format");

        paperName = urlencode(paperName);
        paperFileId = paperResInfo[2];
        paperFormat = paperResInfo[4];
    end
	res_list_json = res_list_json.."{\"res_id_char\":\""..res_list[i].."\",\"file_id\":\""..paperFileId.."\",\"paper_type\":\""..res_info[2].."\",\"title\":\""..res_info[1].."\",\"res_format\":\"" .. paperFormat .. "\",\"type_id\":\"3\",\"type_name\":\"试卷\",\"page\":\"0\",\"preview_status\":\"0\",\"for_urlencoder_url\":\""..res_info[3].."\",\"for_iso_url\":\""..res_info[4].."\",\"url_code\":\""..paperName.."\"},"
    end

    --我的资源
    if tostring(type_id)=="4" then
	local res_info = ssdb_db:multi_hget("myresource_"..res_list[i],"file_id","resource_title","resource_format","resource_page","preview_status","for_urlencoder_url","for_iso_url","height","width")
        res_list_json = res_list_json.."{\"res_id_char\":\""..res_list[i].."\",\"file_id\":\""..res_info[2].."\",\"title\":\""..res_info[4].."\",\"res_format\":\""..res_info[6].."\",\"type_id\":\"4\",\"type_name\":\"资源\",\"page\":\""..res_info[8].."\",\"preview_status\":\""..res_info[10].."\",\"for_urlencoder_url\":\""..res_info[12].."\",\"for_iso_url\":\""..res_info[14].."\",\"url_code\":\""..urlencode(res_info[4]).."\",\"height\":\""..res_info[16].."\",\"width\":\""..res_info[18].."\"},"
    end
end

--redis放回连接池
cache:set_keepalive(0,v_pool_size)


--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size);


if #res_list_json~="0" then
    res_list_json = string.sub(res_list_json,0,#res_list_json-1)
end

ngx.say("{\"success\":true,\"content\":{"..baginfo_json..",\"res_list\":["..res_list_json.."]}}")
