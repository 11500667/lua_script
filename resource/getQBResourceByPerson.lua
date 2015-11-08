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

local res_type = tostring(args["res_type"])
if res_type == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"res_type参数丢失！\"}")    
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

ngx.log(ngx.ERR,"============SELECT SQL_NO_CACHE id FROM t_resource_my_info_sphinxse WHERE query=\'"..keyword.."filter=b_delete,0;filter=res_type,"..res_type..";filter=type_id,6;filter=person_id,"..person_id..";filter=identity_id,"..identity_id..";"..str_subject_id.." maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;================");

local res = db:query("SELECT SQL_NO_CACHE id FROM t_resource_my_info_sphinxse WHERE query=\'"..keyword.."filter=b_delete,0;filter=res_type,"..res_type..";filter=type_id,6;filter=person_id,"..person_id..";filter=identity_id,"..identity_id..";"..str_subject_id.." maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")

--去第二个结果集中的Status中截取总个数
local res1 = db:read_result()
local _,s_str = string.find(res1[1]["Status"],"found: ")
local e_str = string.find(res1[1]["Status"],", time:")
local totalRow = string.sub(res1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)
local myPrime = require "resty.PRIME";

local resource_info = ""
for i=1,#res do
    local cbanba = res[i]["id"]
    local str = "{\"iid\":\""..res[i]["id"].."\",\"resource_id_int\":\"##\",\"resource_id_char\":\"##\",\"resource_title\":\"##\",\"resource_type_name\":\"##\",\"resource_type\":\"##\",\"resource_format\":\"##\",\"resource_page\":\"##\",\"resource_size\":\"##\",\"create_time\":\"##\",\"down_count\":\"##\",\"file_id\":\"##\",\"thumb_id\":\"##\",\"preview_status\":\"##\",\"structure_id\":\"##\",\"scheme_id_int\":\"##\",\"type_id\":\"##\",\"width\":\"##\",\"height\":\"##\",\"group_id\":\"##\",\"table_pk\":\"##\",\"bk_type_name\":\"##\",\"beike_type\":\"##\",\"resource_size_int\":\"##\",\"for_urlencoder_url\":\"##\",\"for_iso_url\":\"##\",\"url_code\":\"##\",\"parent_structure_name\":\"##\",\"app_type_name\":\"##\",\"app_type_id\":\"##\",\"person_id\":\"##\",\"person_name\":\"##\",\"org_name\":\"##\",\"subject_id\":\"##\",\"stage_id\":\"##\",\"stage_subject\":\"##\"}"
    local resource_value_null = ssdb_db:multi_hget("myresource_"..res[i]["id"],"resource_id_int","resource_id_char")
    if tostring(resource_value_null[2]) ~= "userdata: NULL" then
	    ngx.log(ngx.ERR,"+++++++++++++++".."myresource_"..res[i]["id"])
        local resource_value = ssdb_db:multi_hget("myresource_"..res[i]["id"],"resource_id_int","resource_id_char","resource_title","resource_type_name","resource_type","resource_format","resource_page","resource_size","create_time","down_count","file_id","thumb_id","preview_status","structure_id","scheme_id_int","type_id","width","height","group_id","table_pk","bk_type_name","beike_type","resource_size_int","for_urlencoder_url","for_iso_url","app_type_id","subject_id","stage_id")

		for m=1,#resource_value do
		--  ngx.log(ngx.ERR,"######"..m.."########"..resource_value[m])
		end
		
        local subject_id = resource_value[54];  
		local stage_id = resource_value[56];  
        local scheme_id = resource_value[30];

        for j=1,#resource_value do
            if tostring(resource_value[j*2])=="userdata: NULL" then
                str = string.gsub(str,"##"," ",1)	
            else
                if j<=25 then
				     ngx.log(ngx.ERR,"**********"..j.."*********"..resource_value[j*2])
                    str = string.gsub(str,"##",resource_value[j*2],1) 
                end   	       
            end
        end

        local structure_id = resource_value[28]
        local curr_path = ""

        local structures = cache:zrange("structure_code_"..structure_id,0,-1)
        for i=1,#structures do
            local structure_info = cache:hmget("t_resource_structure_"..structures[i],"structure_name")
            curr_path = curr_path..structure_info[1].."->"
        end
        curr_path = string.sub(curr_path,0,#curr_path-2)
        local url_str = urlencode(resource_value[6])
        str = string.gsub(str,"##",url_str,1)
        str = string.gsub(str,"##",curr_path,1)
        local  app_type_id = resource_value[52]
        local app_type_name = "";

        if app_type_id ~= "-1" and app_type_id ~= "1" then
            local  app_typeids =myPrime.dec_prime(app_type_id);
            local app_type_name_tab = {};
            app_type_name_tab = Split(app_typeids,",");

            for i=1,#app_type_name_tab do

                local apptypename="";
                if subject_id == "-1" then 
                    apptypename = '素材';
                else 
                    apptypename = cache:hget("t_base_apptype_"..scheme_id.."_"..app_type_name_tab[i],"app_type_name")
                end
                app_type_name = app_type_name..","..apptypename;
            end

            app_type_name = string.sub(app_type_name,2,#app_type_name);
        end 
        str = string.gsub(str,"##",app_type_name,1)
        str = string.gsub(str,"##",app_type_id,1)
        --上传人，上传机构
      --  local person_id = resource_value[54];
	
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
        --结束
        str = string.gsub(str,"##",person_id,1)
        str = string.gsub(str,"##",person_name,1)
        str = string.gsub(str,"##",org_name,1)	
		str = string.gsub(str,"##",subject_id,1)	
		str = string.gsub(str,"##",stage_id,1)	
		--获得学段科目
		if subject_id ~= "-1" then
	--	ngx.log(ngx.ERR,"****************".."subject_"..subject_id)
		local subject_info = ssdb_db:multi_hget("subject_"..subject_id,"stage_subject");
		str = string.gsub(str,"##",subject_info[2],1)	
		end
		
        resource_info = resource_info..str..",";
    end
end

resource_info = string.sub(resource_info,0,#resource_info-1)

--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0,v_pool_size)
--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size);

ngx.say("{\"success\":\"true\",\"totalRow\":\""..totalRow.."\",\"totalPage\":\""..totalPage.."\",\"pageNumber\":\""..pageNumber.."\",\"pageSize\":\""..pageSize.."\",\"list\":["..resource_info.."]}")


