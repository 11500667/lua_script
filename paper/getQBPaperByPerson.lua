#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-09-09
#描述：获得我上次的全部试卷
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


local subject_id = tostring(args["subject_id"])
if subject_id == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"subject_id参数丢失！\"}")    
    return
end

local str_subject_id = "";
if subject_id ~= "0" then
   str_subject_id = "filter=subject_id,"..subject_id..";";
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
local str_maxmatches = pageNumber*100;

ngx.log(ngx.ERR,"============SELECT SQL_NO_CACHE id FROM t_sjk_paper_my_info_sphinxse WHERE query=\'"..keyword.."filter=b_delete,0;filter=type_id,6;filter=person_id,"..person_id..";"..str_subject_id.." maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;================");

local res = db:query("SELECT SQL_NO_CACHE id FROM t_sjk_paper_my_info_sphinxse WHERE query=\'"..keyword.."filter=b_delete,0;filter=type_id,6;filter=person_id,"..person_id..";"..str_subject_id.." maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")

--去第二个结果集中的Status中截取总个数
local res1 = db:read_result()
local _,s_str = string.find(res1[1]["Status"],"found: ")
local e_str = string.find(res1[1]["Status"],", time:")
local totalRow = string.sub(res1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)
local myPrime = require "resty.PRIME";

local paper_info = ""
for i=1,#res do
    local str = "{\"iid\":\""..res[i]["id"].."\",\"paper_id\":\"##\",\"paper_name\":\"##\",\"ti_num\":\"##\",\"create_time\":\"##\",\"paper_source\":\"##\",\"preview_status\":\"##\",\"extenstion\":\"##\",\"file_id\":\"##\",\"page\":\"##\",\"parent_structure_name\":\"##\",\"paper_id_char\":\"##\",\"paper_id_int\":\"##\",\"table_pk\":\"##\",\"group_id\":\"##\",\"person_id\":\"##\",\"identity_id\":\"##\",\"owner_id\":\"##\",\"type_id\":\"##\",\"for_urlencoder_url\":\"##\",\"for_iso_url\":\"##\",\"structure_id_int\":\"##\",\"scheme_id_int\":\"##\",\"paper_app_type\":\"##\",\"paper_app_type_name\":\"##\",\"url_code\":\"##\",\"person_name\":\"##\",\"org_name\":\"##\",\"subject_id\":\"##\",\"stage_subject\":\"##\"}"
	
    local paper_value = cache:hmget("mypaper_"..res[i]["id"],"paper_id_char","paper_name","question_count","create_time","paper_type","preview_status","extension","file_id","paper_page","structure_id","paper_id_char","paper_id_int","table_pk","group_id","person_id","identity_id","owner_id","type_id","for_urlencoder_url","for_iso_url","identity_id","identity_id","paper_app_type","paper_app_type_name","subject_id")


    if paper_value[5]=="2" then
        local resource_info_id = cache:hmget("mypaper_"..res[i]["id"],"resource_info_id")[1]
		local resource_info = ssdb_db:multi_hget("resource_"..resource_info_id,"preview_status","for_iso_url","for_urlencoder_url","file_id","resource_page","structure_id","scheme_id_int")
        paper_value[6] = resource_info[2]
        paper_value[19] = resource_info[6]
        paper_value[20] = resource_info[4]
        paper_value[8] = resource_info[8]
        paper_value[9] = resource_info[10]
        paper_value[21] = resource_info[12]
        paper_value[22] = resource_info[14]
    end

    local structure_id = paper_value[10]
    local curr_path = ""

    local structures = cache:zrange("structure_code_"..structure_id,0,-1)
    for i=1,#structures do
        local structure_info = cache:hmget("t_resource_structure_"..structures[i],"structure_name")
        curr_path = curr_path..structure_info[1].."->"
    end
    curr_path = string.sub(curr_path,0,#curr_path-2)
    paper_value[10] = curr_path


    if paper_value[1]~=ngx.null then
        for j=1,#paper_value do
            str = string.gsub(str,"##",paper_value[j],1)
        end

        local url_code = urlencode(paper_value[2]);
        str = string.gsub(str,"##",url_code,1)

        local person_id = paper_value[17];
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
        str = string.gsub(str,"##",person_name,1)
        str = string.gsub(str,"##",org_name,1)
		local subject_id = paper_value[25];
		--获得学段科目
		local subject_info = ssdb_db:multi_hget("subject_"..subject_id,"stage_subject");
		str = string.gsub(str,"##",subject_id,1)
		str = string.gsub(str,"##",subject_info[2],1)	

        paper_info = paper_info..str..","
    end
end

--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0,v_pool_size)
--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size);

paper_info = string.sub(paper_info,0,#paper_info-1)
ngx.say("{\"success\":\"true\",\"totalRow\":\""..totalRow.."\",\"totalPage\":\""..totalPage.."\",\"pageNumber\":\""..pageNumber.."\",\"pageSize\":\""..pageSize.."\",\"list\":["..paper_info.."]}")


