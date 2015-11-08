local cookie_identity_id = tostring(ngx.var.cookie_identity_id)

local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

if args["person_id"] == nil or args["person_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
    return
end
local cookie_person_id = args["person_id"]

--获取mediatype参数
local mediatype = tostring(args["mediatype"])
--判断mediatype参数是否为空
if mediatype == "nil" then
    ngx.say("{\"success\":false,\"info\":\"mediatype参数错误！\"}")
    return
end

--获取structureId参数
local structureId = tostring(args["structureId"])
--判断structureId参数是否为空
if structureId == "nil" then
    ngx.say("{\"success\":false,\"info\":\"structureId参数错误！\"}")
    return
end

--获取keyword参数     
local keyword = tostring(args["keyword"])

--获取pageSize参数     
local pageSize = tostring(args["pageSize"])
--判断pageSize参数是否为空   
if pageSize == "nil" then
    ngx.say("{\"success\":false,\"info\":\"pageSize参数错误！\"}")
    return
end

--获取pageNumber参数
local pageNumber = tostring(args["pageNumber"])
--判断pageNumber参数是否为空
if pageNumber == "nil" then
    ngx.say("{\"success\":false,\"info\":\"pageNumber参数错误！\"}")
    return
end

--获取sort_type参数
local sort_type = tostring(args["sort_type"])
--判断sort_type参数是否为空
if sort_type == "nil" then
    ngx.say("{\"success\":false,\"info\":\"sort_type参数错误！\"}")
    return
end

--获取sort_num参数
local sort_num = tostring(args["sort_num"])
--判断sort_num参数是否为空
if sort_num == "nil" then
    ngx.say("{\"success\":false,\"info\":\"sort_num参数错误！\"}")
    return
end

--获取upload_type参数
local upload_type = tostring(args["upload_type"])
--判断upload_type参数是否为空
if upload_type == "nil" then
    ngx.say("{\"success\":false,\"info\":\"upload_type参数错误！\"}")
    return
end

--获取is_cnode参数
local is_cnode = tostring(args["is_cnode"])
--判断is_cnode参数是否为空
if is_cnode == "nil" then
    ngx.say("{\"success\":false,\"info\":\"获取is_cnode参数参数错误！\"}")
    return
end

--获取view参数
local view = tostring(args["view"])
--判断view参数是否为空
if view == "nil" then
    ngx.say("{\"success\":false,\"info\":\"获取view参数参数错误！\"}")
    return
end

--获取stime参数
local stime = tostring(args["stime"])
--判断stime参数是否为空
if stime == "nil" then
    ngx.say("{\"success\":false,\"info\":\"获取stime参数参数错误！\"}")
    return
end

--获取etime参数
local etime = tostring(args["etime"])
--判断view参数是否为空
if etime == "nil" then
    ngx.say("{\"success\":false,\"info\":\"获取etime参数参数错误！\"}")
    return
end

--获取apply_type参数
local apply_type = tostring(args["apply_type"])
--判断apply_type参数是否为空
if apply_type == "nil" then
    ngx.say("{\"success\":false,\"info\":\"获取apply_type参数参数错误！\"}")
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

--拼接媒体类型条件
local mediatype_str = ""
if mediatype ~= "1" then
    mediatype_str = "filter=resource_type,"..mediatype..";"
end

--拼接身份ID条件
local identity_str= "filter=identity_id,"..cookie_identity_id..";"

--拼接b_use条件
local buse_str = "filter=b_use,1;"

--拼接apply_type_id条件
local apply_str = "filter=apply_type_id,"..apply_type..";"

--升序还是降序
local asc_desc = ""
if sort_num=="1" then
    asc_desc = "asc"    
else
    asc_desc = "desc"
end

--按哪个字段排序
local sort_filed = ""
if sort_type == "1" or sort_type == "5" then
    sort_filed = "ts"
elseif sort_type == "2" then
    sort_filed = "resource_size_int"
else
    sort_filed = "resource_type"
end

--拼接排序条件
local sort_str = ""
if upload_type == "1" then
    sort_str = "sort=extended:"..sort_filed.." "..asc_desc..";"
else
    sort_str = "sort=extended:res_type desc,"..sort_filed.." "..asc_desc..";"
end


--拼接结点条件
local structure_str = ""
--拼接人员ID
local person_str= ""
--拼接群组条件
local group_str = ""
if view == "0" then
    person_str= "filter=person_id,"..cookie_person_id..";"
    if is_cnode == "0" then
        structure_str = "filter=parent_structure_id,"..structureId..";"
    end
    group_str = "filter=group_id,"..view..";" 
elseif view == "2" then
    local qu = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"qu")
    group_str = "filter=group_id,"..qu..";"
elseif view == "3" then
    local xiao = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"xiao")
    group_str = "filter=group_id,"..xiao..";"
elseif view == "4" then
    local bm = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"bm")
    group_str = "filter=group_id,"..bm..";"
elseif view == "6" then
    local sheng = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"sheng")
    group_str = "filter=group_id,"..sheng..";"
elseif view == "7" then
    local shi = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"shi")
    group_str = "filter=group_id,"..shi..";"
else    
    group_str = "filter=group_id,"..view..";" 
end

--拼接开始、结束时间条件
local time_str = ""
if stime ~= "0" then
    time_str = "range=ts,"..stime..","..etime..";"
end

--关键字
if keyword =="nil" then
    keyword = ""
else  --如果搜索关键字不为空就把传过来的base64进行编码转成真实的内容
    if #keyword ~= "0" then
        keyword = ngx.decode_base64(keyword)..";"
    else
        keyword = ""
    end
end

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

--获取当前位置
local curr_path = ""
--local structures = cache:smembers("structure_code_"..structureId)
local structures = cache:zrange("structure_code_"..structureId,0,-1)
if structures ~= ngx.null then
    for i=1,#structures do
		
        local structure_info = cache:hmget("t_resource_structure_"..structures[i],"structure_id","structure_name")
        curr_path = curr_path.."{\"structId\":\""..structure_info[1].."\",\"structName\":\""..structure_info[2].."\"},"
    end
    curr_path = string.sub(curr_path,0,#curr_path-1)
end 

--分页数据
local offset = pageSize*pageNumber-pageSize
local limit = pageSize
local str_maxmatches = pageNumber*100

local res = db:query("SELECT SQL_NO_CACHE id FROM t_cloud_resource_info_sphinxse where query=\'"..keyword..apply_str..buse_str..person_str..identity_str..mediatype_str..structure_str..group_str..time_str..sort_str.."maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")


--去第二个结果集中的Status中截取总个数
local res1 = db:read_result()
local _,s_str = string.find(res1[1]["Status"],"found: ")
local e_str = string.find(res1[1]["Status"],", time:")
local totalRow = string.sub(res1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

local resource_info = ""
for i=1,#res do    
    local iid = res[i]["id"]    
    local str = "{\"iid\":\""..iid.."\",\"is_file\":\"##\",\"resource_id_int\":\"##\",\"resource_id_char\":\"##\",\"resource_info_id\":\"##\",\"resource_title\":\"##\",\"resource_type\":\"##\",\"resource_type_name\":\"##\",\"resource_size\":\"##\",\"create_time\":\"##\",\"share_time\":\"##\",\"share_person_id\":\"##\",\"share_person_name\":\"##\",\"self_structure_id\":\"##\",\"scheme_id_int\":\"##\",\"width\":\"##\",\"height\":\"##\",\"resource_format\":\"##\",\"resource_page\":\"##\",\"file_id\":\"##\",\"thumb_id\":\"##\",\"preview_status\":\"##\",\"for_urlencoder_url\":\"##\",\"for_iso_url\":\"##\",\"down_count\":\"##\",\"url_code\":\"##\"}"
    local cloud_values = cache:hmget("cloud_resource_"..iid,"res_type","resource_id_int","resource_id_char","resource_info_id","resource_title","resource_type","resource_type_name","resource_size","create_time","create_time","share_person","share_person_name","self_structure_id","scheme_id_int")    
    --local cloud_values = ssdb_db:multi_hget("cloud_resource_"..iid,"res_type","resource_id_int","resource_id_char","resource_info_id","resource_title","resource_type","resource_type_name","resource_size","create_time","create_time","share_person","share_person_name","self_structure_id","scheme_id_int")    
    for j=1,#cloud_values do        
        str = string.gsub(str,"##",cloud_values[j],1)
        --str = string.gsub(str,"##",cloud_values[j*2],1)
		--ngx.log(ngx.ERR,"cxg_log ----------"..#cloud_values .."**".. cloud_values[j*2]);
    end
	--ngx.log(ngx.ERR,"cxg_log +++++++++++++".. str);
    if cloud_values[1] == "1" then
        local resource_info_id = tostring(cloud_values[4])
		ngx.log(ngx.ERR,"cxg_log ----------"..resource_info_id);
        local  resource_values = ssdb_db:multi_hget("resource_"..resource_info_id,"width","height","resource_format","resource_page","file_id","thumb_id","preview_status","for_urlencoder_url","for_iso_url","down_count")   
        for j=1,#resource_values/2 do
            --if j > 7 then            
                --str = string.gsub(str,"##",ngx.encode_base64(resource_values[j]),1)
            --else
                str = string.gsub(str,"##",tostring(resource_values[j*2]),1)
                --str = string.gsub(str,"##",tostring(resource_values[j*2]),1)
            --end
        end
    else
        for j=1,8 do            
            str = string.gsub(str,"##","-1",1)           
        end
    end
	local function urlencode(str)
    if (str) then
        str = string.gsub (str, "\n", "\r\n")
        str = string.gsub (str, "([^%w ])",
        function (c) return string.format ("%%%%%02X", string.byte(c)) end)
        --str = string.gsub (str, " ", " ")
    end
    return str
end

	 local url_code = urlencode(cloud_values[5]);
	 --local url_code = urlencode(cloud_values[5*2]);
	-- ngx.log(ngx.ERR,"+++++++++++++"..url_code);
	 str = string.gsub(str,"##",url_code,1)  
    resource_info = resource_info..str..","
end

--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0,v_pool_size)

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size);

resource_info = string.sub(resource_info,0,#resource_info-1)
ngx.say("{\"success\":\"true\",\"totalRow\":\""..totalRow.."\",\"totalPage\":\""..totalPage.."\",\"pageNumber\":\""..pageNumber.."\",\"pageSize\":\""..pageSize.."\",\"structure_ids\":["..curr_path.."],\"list\":["..resource_info.."]}")
