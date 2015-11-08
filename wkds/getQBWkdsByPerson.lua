#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-09-09
#描述：获得我上次的全部资源
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
local cjson     = require "cjson"
local offset = pageSize*pageNumber-pageSize
local limit = pageSize
local str_maxmatches = pageNumber*100;

ngx.log(ngx.ERR,"============SELECT SQL_NO_CACHE id FROM t_wkds_info_sphinxse WHERE query=\'"..keyword.."filter=b_delete,0;filter=type_id,6;filter=person_id,"..person_id..";"..str_subject_id.." maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;================");

local wkds = db:query("SELECT SQL_NO_CACHE id FROM t_wkds_info_sphinxse WHERE query=\'"..keyword.."filter=b_delete,0;filter=type_id,6;filter=person_id,"..person_id..";"..str_subject_id.." maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")

--去第二个结果集中的Status中截取总个数
local wkds1 = db:read_result()
local _,s_str = string.find(wkds1[1]["Status"],"found: ")
local e_str = string.find(wkds1[1]["Status"],", time:")
local totalRow = string.sub(wkds1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

local wkds_info = ""
for i=1,#wkds do

    local str = "{\"id\":\""..wkds[i]["id"].."\",\"wkds_id_int\":\"##\",\"wkds_id_char\":\"##\",\"scheme_id_int\":\"##\",\"structure_id\":\"##\",\"wkds_name\":\"##\",\"study_instr\":\"##\",\"teacher_name\":\"##\",\"play_count\":\"##\",\"score_average\":\"##\",\"create_time\":\"##\",\"download_count\":\"##\",\"thumb_id\":\"##\",\"downloadable\":\"##\",\"person_id\":\"##\",\"table_pk\":\"##\",\"group_id\":\"##\",\"content_json\":\"##\",\"wk_type\":\"##\",\"wk_type_name\":\"##\",\"type_id\":\"##\",\"uploader_id\":\"##\",\"w_type\":\"##\",\"subject_id\":\"##\",\"parent_structure_name\":\"##\",\"person_name\":\"##\",\"org_name\":\"##\",\"stage_subject\":\"##\"}"

    local wkds_value_null = cache:hmget("wkds_"..wkds[i]["id"],"wkds_id_int")
    if wkds_value_null[1] ~=ngx.null then

        local wkds_value = cache:hmget("wkds_"..wkds[i]["id"],"wkds_id_int","wkds_id_char","scheme_id","structure_id","wkds_name","study_instr","teacher_name","play_count","score_average","create_time","download_count","thumb_id","downloadable","person_id","table_pk","group_id","content_json","wk_type","wk_type_name","type_id","uploader_id","w_type","subject_id")
		local subject_id = wkds_value[23];
        local  thumb_id = ""
        for j=1,#wkds_value do

            if j==12 then 
                --解析json数据获得第一个视频的缩略图，如果没有显示默认的缩略图
                local content_json = wkds_value[17]
                local aa = ngx.decode_base64(content_json)
                local data = cjson.decode(aa)
                if #data.sp_list~=0 then

                    local resource_info_id = data.sp_list[1].id;
                    if resource_info_id ~= ngx.null then
                        local thumbid = ssdb_db:multi_hget("resource_"..resource_info_id,"thumb_id")
                        if tostring(thumbid[2]) ~= "userdata: NULL" then
                            thumb_id = thumbid[2]
                        end
                    end                              
                else
                    thumb_id = "E6648460-4FFD-E626-1C14-6FBF9F94A23C"
                end

                if not thumb_id or string.len(thumb_id) == 0 then
                    thumb_id = "E6648460-4FFD-E626-1C14-6FBF9F94A23C"
                end
                str = string.gsub(str,"##",thumb_id,1)
            else
                str = string.gsub(str,"##",wkds_value[j],1)
            end    
        end     
        local structure_id = wkds_value[4]
        local curr_path = ""

        local structures = cache:zrange("structure_code_"..structure_id,0,-1)
        for i=1,#structures do
            local structure_info = cache:hmget("t_resource_structure_"..structures[i],"structure_name")
            curr_path = curr_path..structure_info[1].."->"
        end
        curr_path = string.sub(curr_path,0,#curr_path-2)
        str = string.gsub(str,"##",curr_path,1)

        --上传人 上传机构
        local person_id = wkds_value[21];
        local person_name = "";
        local org_name = "";
        if person_id=="32" or person_id=="34" or person_id=="-1" or person_id=="0" then
            org_name = "未知";
            person_name = "未知"
        elseif person_id =="1" then
            org_name = "东师理想";
            person_name = "东师理想";
        else
            --根据人员id获得对应的组织机构名称 
            local org_name_body = ngx.location.capture("/dsideal_yy/person/getOrgnameByPerson?person_id="..person_id.."&identity_id=5")
            org_name = org_name_body.body
            person_name = cache:hget("person_"..person_id.."_5","person_name");
        end
		
        str = string.gsub(str,"##",person_name,1)
        str = string.gsub(str,"##",org_name,1)
		 --获得学段科目
		local subject_info = ssdb_db:multi_hget("subject_"..subject_id,"stage_subject");
		str = string.gsub(str,"##",subject_info[2],1)
        wkds_info = wkds_info..str..","

    end
end
--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0,v_pool_size)
--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size);

wkds_info = string.sub(wkds_info,0,#wkds_info-1)
local json_list = "{\"success\":\"true\",\"totalRow\":\""..totalRow.."\",\"totalPage\":\""..totalPage.."\",\"pageNumber\":\""..pageNumber.."\",\"pageSize\":\""..pageSize.."\",\"list\":["..wkds_info.."]}";
ngx.say(json_list)


