local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--关键字
if args["keyword"] == nil or args["keyword"] == "" then
    ngx.say("{\"success\":false,\"info\":\"keyword参数错误！\"}")
    return
end
local keyword = args["keyword"]

--学段
if args["stage_id"] == nil or args["stage_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"stage_id参数错误！\"}")
    return
end
local stage_id = args["stage_id"]

--学科
if args["subject_id"] == nil or args["subject_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"subject_id参数错误！\"}")
    return
end
local subject_id = args["subject_id"]

--应用类型
if args["apptype_id"] == nil or args["apptype_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"apptype_id参数错误！\"}")
    return
end
local apptype_id = args["apptype_id"]

--媒体类型
if args["mtype_id"] == nil or args["mtype_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"mtype_id参数错误！\"}")
    return
end
local mtype_id = args["mtype_id"]

--地区
if args["area_id"] == nil or args["area_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"area_id参数错误！\"}")
    return
end
local area_id = args["area_id"]

--开始日期
if args["s_date"] == nil or args["s_date"] == "" then
    ngx.say("{\"success\":false,\"info\":\"s_date参数错误！\"}")
    return
end
local s_date = args["s_date"]

--结束日期
if args["e_date"] == nil or args["e_date"] == "" then
    ngx.say("{\"success\":false,\"info\":\"e_date参数错误！\"}")
    return
end
local e_date = args["e_date"]

--第几页
if args["pageNumber"] == nil or args["pageNumber"] == "" then
    ngx.say("{\"success\":false,\"info\":\"pageNumber参数错误！\"}")
    return
end
local pageNumber = args["pageNumber"]

--一页显示多少
if args["pageSize"] == nil or args["pageSize"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"pageSize参数错误！\"}")
    return
end
local pageSize = args["pageSize"]

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

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local myPrime = require "resty.PRIME";

--拼关键字条件
local keyword_str = ""
if keyword ~= "-1" then
	keyword_str = ngx.decode_base64(keyword)..";"
end

--拼版本条件
local  scheme_str= ""
if subject_id ~= "-1" then
	local scheme_list = db:query("SELECT SCHEME_ID FROM t_resource_product_scheme WHERE PRODUCT_ID=(SELECT PRODUCT_ID FROM t_pro_product WHERE STAGE_ID="..stage_id.." AND SUBJECT_ID="..subject_id.." AND SYSTEM_ID=1 AND PLATFORM_ID=1 AND VERSION_ID=1) AND B_USE=1;")
	local scheme_ids = ""
	for i=1,#scheme_list do
		scheme_ids = scheme_ids..scheme_list[i]["SCHEME_ID"]..","
	end
	scheme_ids = string.sub(scheme_ids,1,#scheme_ids-1);
	scheme_str = "filter=scheme_id_int,"..scheme_ids..";"
else
	if stage_id ~= "-1" then
		local scheme_list = db:query("SELECT SCHEME_ID FROM t_resource_product_scheme WHERE PRODUCT_ID=(SELECT PRODUCT_ID FROM t_pro_product WHERE STAGE_ID="..stage_id.." AND SYSTEM_ID=1 AND PLATFORM_ID=1 AND VERSION_ID=1) AND B_USE=1;")
		local scheme_ids = ""
		for i=1,#scheme_list do
			scheme_ids = scheme_ids..scheme_list[i]..","
		end
		scheme_ids = string.sub(scheme_ids,1,#scheme_ids-1);
		scheme_str = "filter=scheme_id_int,"..scheme_ids..";"
	end
end

local cjson = require "cjson"

--拼应用类型
local apptype_str = ""
if apptype_id ~= "-1" then	
	local apptype_tab = {2,3,5,7,11,13}	
	local apptype_ids = myPrime.getCombineValuesNew(apptype_tab,tonumber(apptype_id));	
	apptype_str = "filter=app_type_id,"..apptype_ids..";"
end

--拼媒体类型条件
local mtype_str = ""
if mtype_id ~= "-1" then
	mtype_str = "filter=resource_type,"..mtype_id..";"
end

--拼区域条件
local area_str = ""
if area_id ~= "-1" then
	area_str = "filter=group_id,"..area_id..";"
end

local ts_str = ""
if s_date ~= "-1" and e_date ~= "-1" then
	ts_str = "range=ts,"..s_date..","..e_date..";"
end

function encodeURI(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end

local offset = pageSize*pageNumber-pageSize
local limit = pageSize
local str_maxmatches = "10000"

local res = db:query("SELECT SQL_NO_CACHE id FROM t_resource_info_sphinxse WHERE query=\'"..keyword_str..scheme_str..apptype_str..mtype_str..area_str.."filter=release_status,1,3;filter=res_type,1;sort=attr_desc:ts;"..ts_str.."maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")

--去第二个结果集中的Status中截取总个数
local res1 = db:read_result()
local _,s_str = string.find(res1[1]["Status"],"found: ")
local e_str = string.find(res1[1]["Status"],", time:")
local totalRow = string.sub(res1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

local res_tab = {}
for i=1,#res do
	local res_info_tab = {}
	local res_info_id = res[i]["id"]
	local res_info = ssdb_db:multi_hget("resource_"..res_info_id,"resource_id_int","resource_title","resource_type_name","resource_format","resource_page","resource_size","create_time","down_count","file_id","thumb_id","width","height","for_urlencoder_url","for_iso_url","parent_structure_name","preview_status","app_type_id","scheme_id_int","resource_type")
	res_info_tab["iid"] = res_info_id
	res_info_tab["resource_id_int"] = res_info[2]
	res_info_tab["resource_title"] = res_info[4]
	res_info_tab["resource_type_name"] = res_info[6]
	res_info_tab["resource_format"] = res_info[8]
	res_info_tab["resource_page"] = res_info[10]
	res_info_tab["resource_size"] = res_info[12]
	res_info_tab["create_time"] = res_info[14]
	res_info_tab["down_count"] = res_info[16]
	res_info_tab["file_id"] = res_info[18]
	res_info_tab["thumb_id"] = res_info[20]
	res_info_tab["width"] = res_info[22]
	res_info_tab["height"] = res_info[24]
	res_info_tab["for_urlencoder_url"] = res_info[26]
	res_info_tab["for_iso_url"] = res_info[28]
	res_info_tab["parent_structure_name"] = res_info[30]
	res_info_tab["preview_status"] = res_info[32]
	res_info_tab["resource_type"] = res_info[36]
	res_info_tab["url_code"] = encodeURI(res_info[4])
	
	
	local structure_id = res_info[40]
    local curr_path = ""
    local structures = cache:zrange("structure_code_"..structure_id,0,-1)
    for i=1,#structures do
        local structure_info = cache:hmget("t_resource_structure_"..structures[i],"structure_name")
        if structure_info[1] == ngx.null then
            curr_path = curr_path.."->"
         else
       curr_path = curr_path..structure_info[1].."->"
        end
    end
    curr_path = string.sub(curr_path,0,#curr_path-2)
	if curr_path == "" then
		res_info_tab["parent_structure_name"] = curr_path
	else
		res_info_tab["parent_structure_name"] = "暂无"
	end
	
	
	
	
	--调用获取应用类型名称接口	
	local appname_body = ngx.location.capture("/dsideal_yy/apptype/get_apptypename?scheme_id="..res_info[36].."&app_type_id="..res_info[34])
	res_info_tab["app_type_name"] = appname_body.body
	
	res_tab[i] = res_info_tab	

	
end

local result = {}
result["success"] = true
result["totalRow"] = totalRow
result["totalPage"] = totalPage
result["pageNumber"] = pageNumber
result["pageSize"] = pageSize
result["list"] = res_tab

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size);
--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false)
ngx.say(tostring(cjson.encode(result)))
