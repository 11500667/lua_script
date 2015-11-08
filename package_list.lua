--[[
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
]]
local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--bag_id为资源包对应的resource_id_int的值
if args["bag_id"] == nil or args["bag_id"]=="" then
	ngx.say("{\"success\":\"false\",\"info\":\"参数bag_id不能为空！\"}");
	return;
end

local resourceIdInt = tostring(args["bag_id"])

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
 local host_ip = tostring(ngx.var.host);
 local server_port = tostring(ngx.var.server_port);

local res_list_json = ""
local res_list = cache:hgetall("pack_list_".. resourceIdInt)
for i=1, #res_list, 2 do
    local type_id = res_list[i+1]
    --资源
    if tostring(type_id)=="1" then


		local res_info = ssdb_db:multi_hget("resource_"..res_list[i],"file_id","resource_title","resource_format","resource_page","preview_status","for_urlencoder_url","for_iso_url","height","width","thumb_id")
         local down_path = ngx.encode_base64("http://"..host_ip..":"..server_port.."/dsideal_yy/html/down/Material/"..string.sub(res_info[2],0,2).."/"..res_info[2].."."..res_info[6].."?flag=download&n="..urlencode(res_info[4]).."."..res_info[6]);
		res_list_json = res_list_json.."{\"res_id_char\":\""..res_list[i].."\",\"file_id\":\""..res_info[2].."\",\"title\":\""..res_info[4].."\",\"res_format\":\""..res_info[6].."\",\"type_id\":\"1\",\"type_name\":\"资源\",\"page\":\""..res_info[8].."\",\"preview_status\":\""..res_info[10].."\",\"for_urlencoder_url\":\""..res_info[12].."\",\"for_iso_url\":\""..res_info[14].."\",\"url_code\":\""..urlencode(res_info[4]).."\",\"height\":\""..res_info[16].."\",\"width\":\""..res_info[18].."\",\"thumb_id\":\""..res_info[20].."\",\"down_path\":\""..down_path.."\"},"
    end

    --试题
    if tostring(type_id)=="2" then
		local res_info = cache:hmget("pack_question_"..res_list[i],"file_id")
		
		 local down_path = ngx.encode_base64("http://"..host_ip..":"..server_port.."/dsideal_yy/html/down/PaperParsed/"..string.sub(res_info[1],0,2).."/"..res_info[1].."_ALL.doc");
		 
		res_list_json = res_list_json.."{\"res_id_char\":\""..res_list[i].."\",\"file_id\":\""..res_info[1].."\",\"title\":\"\",\"res_format\":\"png\",\"type_id\":\"2\",\"type_name\":\"试题\",\"page\":\"0\",\"preview_status\":\"1\",\"for_urlencoder_url\":\"\",\"for_iso_url\":\"\",\"url_code\":\"\",\"thumb_id\":\"".."".."\",\"down_path\":\""..down_path.."\"},"
    end

    --试卷
    if tostring(type_id)=="3" then
		local res_info = cache:hmget("paperinfo_"..res_list[i],"paper_name","paper_type","for_urlencoder_url","for_iso_url", "resource_info_id", "file_id")
		local resInfoId   = res_info[5];
        local paperFileId = "";
        local paperName   = res_info[1];
        local paperFormat = "doc";
        local paperFileId = res_info[6];
        if res_info[2] == "2" then
            paperResInfo = ssdb_db:multi_hget("resource_" .. resInfoId, "file_id", "resource_format");
            paperName = urlencode(paperName);
            paperFileId = paperResInfo[2];
            paperFormat = paperResInfo[4];
        end
		local down_path = ngx.encode_base64("http://"..host_ip..":"..server_port.."/dsideal_yy/html/down/Material/"..string.sub(paperFileId,0,2).."/"..paperFileId.."."..paperFormat.."?flag=download&n="..urlencode(res_info[1]).."."..paperFormat);
		 
		res_list_json = res_list_json.."{\"res_id_char\":\""..res_list[i].."\",\"file_id\":\""..paperFileId.."\",\"paper_type\":\""..res_info[2].."\",\"title\":\""..res_info[1].."\",\"res_format\":\"" .. paperFormat .. "\",\"type_id\":\"3\",\"type_name\":\"试卷\",\"page\":\"0\",\"preview_status\":\"0\",\"for_urlencoder_url\":\""..res_info[3].."\",\"for_iso_url\":\""..res_info[4].."\",\"url_code\":\"".. paperName .. "\",\"thumb_id\":\"".."".."\",\"down_path\":\""..down_path.."\"},"
    end

    --我的资源
    if tostring(type_id)=="4" then
		local res_info = ssdb_db:multi_hget("myresource_"..res_list[i],"file_id","resource_title","resource_format","resource_page","preview_status","for_urlencoder_url","for_iso_url","height","width","thumb_id")
         local down_path = ngx.encode_base64("http://"..host_ip..":"..server_port.."/dsideal_yy/html/down/Material/"..string.sub(res_info[2],0,2).."/"..res_info[2].."."..res_info[6].."?flag=download&n="..urlencode(res_info[4]).."."..res_info[6]);
		 
		res_list_json = res_list_json.."{\"res_id_char\":\""..res_list[i].."\",\"file_id\":\""..res_info[2].."\",\"title\":\""..res_info[4].."\",\"res_format\":\""..res_info[6].."\",\"type_id\":\"1\",\"type_name\":\"资源\",\"page\":\""..res_info[8].."\",\"preview_status\":\""..res_info[10].."\",\"for_urlencoder_url\":\""..res_info[12].."\",\"for_iso_url\":\""..res_info[14].."\",\"url_code\":\""..urlencode(res_info[4]).."\",\"height\":\""..res_info[16].."\",\"width\":\""..res_info[18].."\",\"thumb_id\":\""..res_info[20].."\",\"down_path\":\""..down_path.."\"},"
    end
end

--redis放回连接池
cache:set_keepalive(0,v_pool_size)

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size);


if #res_list_json~="0" then
    res_list_json = string.sub(res_list_json,0,#res_list_json-1)
end

ngx.say("{\"success\":true,\"res_list\":["..res_list_json.."]}")





