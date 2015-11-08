local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--学段ID
if args["stage_id"] == nil or args["stage_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"stage_id参数错误！\"}")
    return
end
local stage_id = args["stage_id"]

--科目ID
if args["subject_id"] == nil or args["subject_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"subject_id参数错误！\"}")
    return
end
local subject_id = args["subject_id"]

--一页显示多少个
if args["pageNumber"] == nil or args["pageNumber"] == "" then
    ngx.say("{\"success\":false,\"info\":\"pageNumber参数错误！\"}")
    return
end
local pageNumber = args["pageNumber"]

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

--是内部调用还是外部调用
if args["InOut"] == nil or args["InOut"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"InOut参数错误！\"}")
    return
end
local InOut = args["InOut"]

local offset = pageSize*pageNumber-pageSize
local limit = pageSize

local cjson = require "cjson"

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
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local res = ""

if subject_id == "-1" then
	res = ssdb_db:zrrange("resource_sort_"..stage_id,offset,limit)
else
	res = ssdb_db:zrrange("resource_sort_"..stage_id.."_"..subject_id,offset,limit)
end
	

local result = {}
local i_count = 1
if tostring(res[1]) ~= "ok" then
	for i=1,#res,2 do	
		local resource_info = {}
		local resource_id_int = res[i]	
		local resource_info_id = ""
		if subject_id ~= "-1" then		
			resource_info_id = ssdb_db:hget("resource_sort_infoid_idint_"..stage_id.."_"..subject_id,resource_id_int)[1]		
		else
			resource_info_id = ssdb_db:hget("resource_sort_infoid_idint_"..stage_id,resource_id_int)[1]
		end
		
		--local resource_info_str = cache:hmget("resource_"..resource_info_id,"resource_title","width","height","for_iso_url","for_urlencoder_url","file_id","thumb_id","resource_format","preview_status","resource_page")
		local resource_info_str = ssdb_db:multi_hget("resource_"..resource_info_id,"resource_title","width","height","for_iso_url","for_urlencoder_url","file_id","thumb_id","resource_format","preview_status","resource_page")
		resource_info["resource_title"] = resource_info_str[2]
		resource_info["width"] = resource_info_str[4]
		resource_info["height"] = resource_info_str[6]
		resource_info["for_iso_url"] = resource_info_str[8]
		resource_info["for_urlencoder_url"] = resource_info_str[10]
		resource_info["file_id"] = resource_info_str[12]
		resource_info["thumb_id"] = resource_info_str[14]
		resource_info["resource_format"] = resource_info_str[16]
		resource_info["preview_status"] = resource_info_str[18]
		resource_info["resource_page"] = resource_info_str[20]
		result[i_count] = resource_info
		i_count = i_count+1
	end
end
--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)

if InOut == "1" then
	ngx.say(cjson.encode(result))
else
	local in_result = {}
	in_result["success"] = true
	in_result["data_list"] = result
	cjson.encode_empty_table_as_object(false)
	ngx.say(cjson.encode(in_result))
end




