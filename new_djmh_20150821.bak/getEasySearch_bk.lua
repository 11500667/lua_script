local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--关键字
local keyword = ""
local mode = ""
if args["keyword"] ~= nil and args["keyword"] ~= "" then
	keyword = ngx.decode_base64(args["keyword"])..";"  
	mode = "mode=phrase"
end

--地区
if args["area_id"] == nil or args["area_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"area_id参数错误！\"}")
    return
end
local area_id = args["area_id"]

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

--人员参数
local person_str = ""
if args["person_id"] ~= nil and args["person_id"] ~= "" then
	if args["person_id"] ~= "-1" then
		person_str = "filter=person_id,"..args["person_id"]..";"
	end
end

--拼group_id条件
local area_str = "filter=group_id,1,"..area_id..";"

--拼stage_id条件
local stage_str = ""
if stage_id ~= "-1" then
	stage_str = "filter=stage_id,"..stage_id..";"
end

--拼subject_id条件
local subject_str = ""
if subject_id ~= "-1" then
	subject_str = "filter=subject_id,"..subject_id..";"
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

local cjson = require "cjson"

function encodeURI(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end

local offset = pageSize*pageNumber-pageSize
local limit = pageSize
local str_maxmatches = "100000"

local res = db:query("SELECT SQL_NO_CACHE id FROM t_resource_info_sphinxse WHERE query=\'"..keyword..area_str..stage_str..subject_str..person_str.."filter=release_status,1,3;filter=res_type,2;sort=attr_desc:ts;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit..";"..mode.."\';SHOW ENGINE SPHINX  STATUS;")

--去第二个结果集中的Status中截取总个数
local res1 = db:read_result()
local _,s_str = string.find(res1[1]["Status"],"found: ")
local e_str = string.find(res1[1]["Status"],", time:")
local totalRow = string.sub(res1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

local resourceUtil = require "base.resource.model.ResourceUtil";
local resourceJson = resourceUtil:getResourceInfoByIds(res)
--[[
local res_tab = {}
for i=1,#res do
	local res_info_tab = {}
	local res_info_id = res[i]["id"]
	local res_info = cache:hmget("resource_"..res_info_id,"resource_id_int","resource_title","resource_type_name","resource_format","resource_page","resource_size","create_time","down_count","file_id","thumb_id","width","height","for_urlencoder_url","for_iso_url","parent_structure_name","preview_status","app_type_id","scheme_id_int","structure_id","subject_id","bk_type_name","person_id","beike_type","resource_size_int")
	res_info_tab["iid"] = res_info_id
	res_info_tab["resource_id_int"] = res_info[1]
	res_info_tab["resource_title"] = res_info[2]
	res_info_tab["resource_type_name"] = res_info[3]
	res_info_tab["resource_format"] = res_info[4]
	res_info_tab["resource_page"] = res_info[5]
	res_info_tab["resource_size"] = res_info[6]
	res_info_tab["create_time"] = res_info[7]
	res_info_tab["down_count"] = res_info[8]
	res_info_tab["file_id"] = res_info[9]
	res_info_tab["thumb_id"] = res_info[10]
	res_info_tab["width"] = res_info[11]
	res_info_tab["height"] = res_info[12]	
	res_info_tab["res_type"] = 1
	res_info_tab["bk_type"] = res_info[23]
	res_info_tab["resource_size_int"] = tonumber(res_info[24])
	res_info_tab["bk_type_name"] = res_info[21]	
	  local curr_path = ""
    local structures = cache:zrange("structure_code_"..res_info[19],0,-1)
    for i=1,#structures do
        local structure_info = cache:hmget("t_resource_structure_"..structures[i],"structure_name")
       curr_path = curr_path..structure_info[1].."->"
    end
    curr_path = string.sub(curr_path,0,#curr_path-2)
	
	res_info_tab["parent_structure_name"] = curr_path
	res_info_tab["preview_status"] = res_info[16]
	res_info_tab["url_code"] = encodeURI(res_info[2])
	local app_type_id = res_info[17];
	--调用获取应用类型名称接口
	local appname_body = ngx.location.capture("/dsideal_yy/apptype/get_apptypename?subject_id="..res_info[20].."&app_type_id="..res_info[17])
	res_info_tab["app_type_name"] = appname_body.body
	
	local person_id = res_info[22];
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
	res_info_tab["org_name"] = org_name
	res_info_tab["person_name"] = person_name
	res_info_tab["stage_sujbect"] = ssdb_db:hget("subject_"..res_info[20],"stage_subject")[1]
	
	res_tab[i] = res_info_tab
end

]]
local result = {}
result["success"] = true
result["totalRow"] = totalRow
result["totalPage"] = totalPage
result["pageNumber"] = pageNumber
result["pageSize"] = pageSize
result["list"] = resourceJson

--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0,v_pool_size)
--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false)
ngx.say(tostring(cjson.encode(result)))
