#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-09-09
#描述：获得我上次的全部试题
]]
--1.获得参数方法
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

--连接redis服务器
local redis = require "resty.redis"
local cache = redis.new()
local ok,err = cache.connect(cache,v_redis_ip,v_redis_port)
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

local person_id = tostring(args["person_id"])
if person_id == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"person_id参数丢失！\"}")    
    return
end

local identity_id = tostring(args["identity_id"])
if identity_id == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"identity_id参数丢失！\"}")    
    return
end

local str_scheme_id = "";
local subject_id = tostring(args["subject_id"])
if subject_id == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"subject_id参数丢失！\"}")    
    return
end

local stage_id = tostring(args["stage_id"])
if stage_id == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"stage_id参数丢失！\"}")    
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

if stage_id ~= "0" and subject_id == "0" then
   local sql = "SELECT scheme_id FROM t_resource_product_scheme WHERE PRODUCT_ID IN (SELECT PRODUCT_ID FROM t_pro_product WHERE stage_id="..stage_id.." AND SYSTEM_ID = 2 AND PLATFORM_ID = 1 ) AND b_use = 1";
   local scheme_list = db:query(sql);
   str_scheme_id = "";
   for i=1,#scheme_list do
     str_scheme_id = str_scheme_id..","..scheme_list[i]["scheme_id"];
   end
   if #scheme_list>0 then
		str_scheme_id =  string.sub(str_scheme_id,0,#str_scheme_id-1)
   end
   str_scheme_id = "filter=scheme_id_int,"..str_scheme_id..";"
end

if stage_id ~= "0" and subject_id ~= "0" then
    local sql = "SELECT scheme_id FROM t_resource_product_scheme WHERE PRODUCT_ID IN (SELECT PRODUCT_ID FROM t_pro_product WHERE subject_id="..subject_id.." AND SYSTEM_ID = 2 AND PLATFORM_ID = 1 ) AND b_use = 1";
   local scheme_list = db:query(sql);
   str_scheme_id = "";
   for i=1,#scheme_list do
     str_scheme_id = str_scheme_id..","..scheme_list[i]["scheme_id"];
   end
   if #scheme_list>0 then
     str_scheme_id =  string.sub(str_scheme_id,0,#str_scheme_id-1)
   end
   str_scheme_id = "filter=scheme_id_int,"..str_scheme_id..";"
end

--搜索关键字
local keyword = tostring(args["keyword"])
--第几页
local pageNumber = tostring(args["pageNumber"])
if pageNumber == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"第几页参数丢失！\"}")    
    return
end
if pageNumber == "0" then
    pageNumber = "1"
end
--一页显示多少
local pageSize = tostring(args["pageSize"])
if pageSize == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"一页显示多少条参数丢失！\"}")    
    return
end
if keyword=="nil" then
    keyword = ""
else  --如果搜索关键字不为空就把传过来的base64进行编码转成真实的内容
    keyword = ngx.decode_base64(keyword)..";"
end

--UFT_CODE
local function urlencode(str)
    if (str) then
        str = string.gsub (str, "\n", "\r\n")
        str = string.gsub (str, "([^%w ])",
            function (c) return string.format ("%%%%%02X", string.byte(c)) end)
        str = string.gsub (str, " ", "+")
    end
    return str
end



local offset = pageSize*pageNumber-pageSize
local limit = pageSize
local str_maxmatches = pageNumber*100;

ngx.log(ngx.ERR,"============SELECT SQL_NO_CACHE id FROM t_tk_question_my_info_sphinxse WHERE query=\'"..keyword.."filter=b_delete,0;filter=type_id,6;filter=create_person,"..person_id..";"..str_scheme_id.."sort=attr_desc:TS;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;================");

local res = db:query("SELECT SQL_NO_CACHE id FROM t_tk_question_my_info_sphinxse WHERE query=\'"..keyword.."filter=b_delete,0;filter=type_id,6;filter=create_person,"..person_id..";"..str_scheme_id.."sort=attr_desc:TS;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")


--去第二个结果集中的Status中截取总个数
local res1 = db:read_result()
local _,s_str = string.find(res1[1]["Status"],"found: ")
local e_str = string.find(res1[1]["Status"],", time:")
local totalRow = string.sub(res1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

local cjson         = require "cjson";
local strucService  = require "base.structure.services.StructureService";
local question_info = ""
for i=1,#res do
    -- ngx.log(ngx.ERR, "====我的试卷===> 序号：", i, " ----> ", res[i]["id"], "<=== 错误的ID ===");
    local question_json = cache:hmget("myquestion_"..res[i]["id"],"id","type_id","table_pk","json_question","group_id","uploader_id")
    ngx.log(ngx.ERR,"---------------".."myquestion_"..res[i]["id"])
    local jsonQuesObj = cjson.decode(ngx.decode_base64(question_json[4]));
    local strucIdInt  = jsonQuesObj["structure_id"];
    --ngx.log(ngx.ERR, "[sj_log] -> [question_list] -> strucIdInt ->[", strucIdInt, "]");
    local strucPath   = strucService: getStrucPath(strucIdInt);
    jsonQuesObj["structure_path"] = strucPath;
    local jsonEncodeStr = cjson.encode(jsonQuesObj);

    local l_group_id = ""
    if question_json[5]~=ngx.null then
        l_group_id = question_json[5]
    end

    if question_json[1]~=ngx.null then
        --上传人，上传机构
        local person_id = question_json[6];
        local person_name="--";
        local org_name = "";
        if person_id=="32" or person_id=="34" or person_id=="-1" or person_id=="0" then
            org_name = "未知";
            person_name="未知";
        elseif person_id =="1" then
            org_name = "东师理想";
            person_name="东师理想";
        else
            person_name = cache:hget("person_"..person_id.."_5","person_name");
            --根据人员id获得对应的组织机构名称 
            local org_name_body = ngx.location.capture("/dsideal_yy/person/getOrgnameByPerson?person_id="..person_id.."&identity_id=5")
            org_name = org_name_body.body
        end
		
        question_info = question_info.."{\"id\":\""..question_json[1].."\",\"type_id\":\""..question_json[2].."\",\"table_pk\":\""..question_json[3].."\",\"group_id\":\""..l_group_id.."\",\"create_person\":\""..question_json[6].."\",\"person_name\":\""..person_name.."\",\"org_name\":\""..org_name.."\",\"json_question\":"..jsonEncodeStr.."},"
end
end
if #question_info~=0 then
    question_info = string.sub(question_info,0,#question_info-1)
end
--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0,v_pool_size)
--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size);
ngx.say("{\"success\":\"true\",\"totalRow\":\""..totalRow.."\",\"totalPage\":\""..totalPage.."\",\"pageNumber\":\""..pageNumber.."\",\"pageSize\":\""..pageSize.."\",\"list\":["..question_info.."]}")

