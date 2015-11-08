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

--单位ID
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
local group_str = "filter=group_id,1,"..area_id..";"

--拼stage_id条件
local stage_str = ""
if stage_id ~= "-1" then
	stage_str = "filter=stage_id,"..stage_id..";"
else
	stage_str = "filter=stage_id,4,5,6;"
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

local wkds = db:query("SELECT SQL_NO_CACHE id FROM t_wkds_info_sphinxse WHERE query=\'"..keyword..group_str..stage_str..subject_str..person_str.."filter=type,1;filter=isdraft,0;filter=check_status,0,1;filter=b_delete,0;sort=attr_desc:ts;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit..";"..mode.."\';SHOW ENGINE SPHINX  STATUS;")

--去第二个结果集中的Status中截取总个数
local wkds1 = db:read_result()
local _,s_str = string.find(wkds1[1]["Status"],"found: ")
local e_str = string.find(wkds1[1]["Status"],", time:")
local totalRow = string.sub(wkds1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

local wkds_info_tab = {}
for i=1,#wkds do

	local wkds_info_res = {} 
	
	 local wkds_info = cache:hmget("wkds_"..wkds[i]["id"],"wkds_id_int","wkds_name","create_time","play_count","wk_type_name","structure_id","person_id","subject_id","wk_type","person_id","download_count","scheme_id","content_json","teacher_name")
	 
	 wkds_info_res["iid"] = wkds[i]["id"]
	 wkds_info_res["wkds_id_int"] = wkds_info[1]
	 wkds_info_res["wkds_name"] = wkds_info[2]
	 wkds_info_res["create_time"] = wkds_info[3]
	 wkds_info_res["play_count"] = wkds_info[4]
	 wkds_info_res["wk_type_name"] = wkds_info[5]
	 wkds_info_res["down_count"] = wkds_info[11]
	 local subject_name = ssdb_db:hget("t_resource_scheme_"..wkds_info[12],"subject_name")[1]   
	 wkds_info_res["subject"] = subject_name 
	 wkds_info_res["upload_person"] = wkds_info[14]
	 
	 
	 local  thumb_id = ""
	 local content_json = wkds_info[13]		 
	 local aa = ngx.decode_base64(content_json)
	 local data = cjson.decode(aa)
	 if #data.sp_list~=0 then
		local resource_info_id = data.sp_list[1].id
		if resource_info_id ~= ngx.null then
			--local thumbid = cache:hmget("resource_"..resource_info_id,"thumb_id")
			local thumbid = ssdb_db:hget("resource_"..resource_info_id,"thumb_id")[1]
			if tostring(thumbid[1]) ~= "userdata: NULL" then
				thumb_id = thumbid[1]
			end
		end
	 else
		 thumb_id = "E6648460-4FFD-E626-1C14-6FBF9F94A23C"
	 end

	if not thumb_id or string.len(thumb_id) == 0 then
	  thumb_id = "E6648460-4FFD-E626-1C14-6FBF9F94A23C"
	end
	wkds_info_res["thumb_id"] = thumb_id
	 
	 local structure_id = wkds_info[6]
	 local curr_path = ""

	 local structures = cache:zrange("structure_code_"..structure_id,0,-1)
	 for i=1,#structures do
	   local structure_info = cache:hmget("t_resource_structure_"..structures[i],"structure_name")
	   curr_path = curr_path..structure_info[1].."->"
	 end
	 curr_path = string.sub(curr_path,0,#curr_path-2)
	 wkds_info_res["parent_structure_name"] = curr_path
	 
	 local person_id = wkds_info[7];
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
	wkds_info_res["org_name"] = org_name
	wkds_info_res["person_name"] = person_name
	wkds_info_res["stage_sujbect"] = ssdb_db:hget("subject_"..wkds_info[8],"stage_subject")[1]
	wkds_info_res["wk_type"] = wkds_info[9]
	wkds_info_res["person_id"] = wkds_info[10]
	 
	 wkds_info_tab[i] = wkds_info_res
end

local result = {} 
result["list"] = wkds_info_tab
result["totalRow"] = totalRow
result["totalPage"] = totalPage
result["pageNumber"] = pageNumber
result["pageSize"] = pageSize
result["success"] = true

db:set_keepalive(0,v_pool_size)
cache:set_keepalive(0,v_pool_size)
--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))
