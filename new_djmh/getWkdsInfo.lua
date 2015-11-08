local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

local cjson = require "cjson"

--bureau_id参数 单位ID
if args["bureau_id"] == nil or args["bureau_id"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"bureau_id参数错误！\"}")
	return
end
local bureau_id = args["bureau_id"]

--学段ID
if args["stage_id"] == nil or args["stage_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"stage_id参数错误123！\"}")
    return
end
local stage_id = args["stage_id"]

--科目ID
if args["subject_id"] == nil or args["subject_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"subject_id参数错误！\"}")
    return
end
local subject_id = args["subject_id"]

--一页显示多少
if args["pageSize"] == nil or args["pageSize"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"pageSize参数错误！\"}")
    return
end
local pageSize = args["pageSize"]

--第几页
if args["pageNumber"] == nil or args["pageNumber"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"pageNumber参数错误！\"}")
    return
end
local pageNumber = args["pageNumber"]

--连接redis服务器
local redis = require "resty.redis"
local redis_db = redis:new()
local ok,err = redis_db:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--连接mysql数据库
local mysql = require "resty.mysql"
local mysql_db = mysql:new()
mysql_db:connect{
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

local offset = pageSize*pageNumber-pageSize
local limit = pageSize
local str_maxmatches = "5000"

--拼学段条件
local stage_str = ""
if stage_id ~= "-1" then
	stage_str = "filter=stage_id,"..stage_id..";"
end 

--拼学期条件
local subject_str = ""
if subject_id ~= "-1" then
	subject_str = "filter=subject_id,"..subject_id..";"
end 

local info_sql = mysql_db:query("SELECT SQL_NO_CACHE id FROM t_wkds_info_sphinxse WHERE query='filter=b_delete,0;filter=isdraft,0;filter=group_id,1,"..bureau_id..";"..stage_str..subject_str.."sort=attr_desc:ts;groupby=attr:wkds_id_int;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."\';SHOW ENGINE SPHINX  STATUS;")

local res1 = mysql_db:read_result()
local _,s_str = string.find(res1[1]["Status"],"found: ")
local e_str = string.find(res1[1]["Status"],", time:")
local totalRow = string.sub(res1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

local resource_info_tab = {}

for i=1,#info_sql do
	local resource_info_res = {}
	local resource_info_id = info_sql[i]["id"]
	local resource_info = redis_db:hmget("wkds_"..resource_info_id,"wkds_name","thumb_id","content_json","play_count","wkds_id_int","download_count","scheme_id","teacher_name")
	
	resource_info_res["iid"] = resource_info_id
	resource_info_res["wkds_name"] = resource_info[1]
	resource_info_res["play_count"] = resource_info[4]
	resource_info_res["wkds_id_int"] = resource_info[5]
	resource_info_res["down_count"] = resource_info[6]
	local subject_name = ssdb_db:hget("t_resource_scheme_"..resource_info[7],"subject_name")[1]   
	resource_info_res["subject"] = subject_name
	resource_info_res["upload_person"] = resource_info[8]
	
		
	local  thumb_id = ""
	 local content_json = resource_info[3]		 
	 local aa = ngx.decode_base64(content_json)
	 local data = cjson.decode(aa)
	 if #data.sp_list~=0 then
		local resource_info_id = data.sp_list[1].id
		if resource_info_id ~= ngx.null then
			--local thumbid = redis_db:hmget("resource_"..resource_info_id,"thumb_id")
			local thumbid = ssdb_db:hget("resource_"..resource_info_id,"thumb_id")[1]
			if tostring(thumbid) ~= "userdata: NULL" then
				thumb_id = thumbid
			end
		end
	 else
		 thumb_id = "E6648460-4FFD-E626-1C14-6FBF9F94A23C"
	 end

	if not thumb_id or string.len(thumb_id) == 0 then
	  thumb_id = "E6648460-4FFD-E626-1C14-6FBF9F94A23C"
	end
	resource_info_res["thumb_id"] = thumb_id
	
	resource_info_tab[i] = resource_info_res
end

local result = {} 
result["wk_list"] = resource_info_tab
result["totalRow"] = totalRow
result["totalPage"] = totalPage
result["pageNumber"] = pageNumber
result["pageSize"] = pageSize
result["success"] = true

--redis放回连接池
redis_db:set_keepalive(0,v_pool_size)
--mysql放回连接池
mysql_db:set_keepalive(0,v_pool_size)
--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))





