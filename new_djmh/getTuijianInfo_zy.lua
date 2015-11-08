local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

local cjson = require "cjson"

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

--单位ID
if args["bureau_id"] == nil or args["bureau_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"bureau_id参数错误！\"}")
    return
end
local bureau_id = args["bureau_id"]

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
local redis_db = redis:new()
local ok,err = redis_db:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--url加码
function encodeURI(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end

--判断学科是不是全部，然后统一给SSDB KEY
local tuijian_key = ""
if stage_id == "-1" then
	tuijian_key = "tuijian_zy_"..bureau_id
else
	if subject_id == "-1" then
		tuijian_key = "tuijian_zy_"..bureau_id.."_"..stage_id
	else
		tuijian_key = "tuijian_zy_"..bureau_id.."_"..stage_id.."_"..subject_id
	end
end

local tuijian_zy_ts = redis_db:get("tuijian_zy_ts_"..bureau_id)
--local tuijian_zy_generate_ts = redis_db:get(tuijian_key.."_ts")
local tuijian_zy_generate_ts = redis_db:get(tuijian_key.."_"..pageSize.."_"..pageNumber.."_ts")
if tuijian_zy_ts == ngx.null then
	local uuid =  require "resty.uuid";
	tuijian_zy_ts = uuid.new();	
	redis_db:set("tuijian_zy_ts_"..bureau_id,tuijian_zy_ts)		
end

if tuijian_zy_generate_ts ~= tuijian_zy_ts or tuijian_zy_generate_ts == ngx.null then

	--redis_db:set(tuijian_key.."_ts",tuijian_zy_ts)
	redis_db:set(tuijian_key.."_"..pageSize.."_"..pageNumber.."_ts",tuijian_zy_ts)

	local offset = math.floor((pageNumber-1)*pageSize)
	local totalRow = ssdb_db:zsize(tuijian_key)[1]
	local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

	local i_count = 1
	local resource_info_tab = {}

	local tuijian_info = ssdb_db:zrrange(tuijian_key,offset,pageSize)

	if #tuijian_info>1 then
		for i=1,#tuijian_info,2 do
			local resource_info_id = tuijian_info[i]
			local resource_info_res = {}
			--local resource_info = redis_db:hmget("resource_"..resource_info_id,"resource_id_int","resource_title","file_id","thumb_id","preview_status","resource_id_char","resource_format","width","height","resource_page","for_urlencoder_url","for_iso_url","scheme_id_int")
			local resource_info = ssdb_db:multi_hget("resource_"..resource_info_id,"resource_id_int","resource_title","file_id","thumb_id","preview_status","resource_id_char","resource_format","width","height","resource_page","for_urlencoder_url","for_iso_url","scheme_id_int")
			
			resource_info_res["iid"] = resource_info_id
			resource_info_res["resource_id_int"] = resource_info[2]
			resource_info_res["resource_title"] = resource_info[4]
			resource_info_res["file_id"] = resource_info[6]
			resource_info_res["thumb_id"] = resource_info[8]
			resource_info_res["preview_status"] = resource_info[10]
			resource_info_res["resource_id_char"] = resource_info[12]
			resource_info_res["resource_format"] = resource_info[14]
			resource_info_res["width"] = resource_info[16]
			resource_info_res["height"] = resource_info[18]
			resource_info_res["resource_page"] = resource_info[20]	
			resource_info_res["url_code"] = encodeURI(resource_info[4])
			
			resource_info_res["for_urlencoder_url"] = resource_info[22]
			resource_info_res["for_iso_url"] = resource_info[24]
			
			local subject_name = ssdb_db:hget("t_resource_scheme_"..resource_info[26],"subject_name")[1]
			resource_info_res["subject"] = subject_name
			
			resource_info_tab[i_count] = resource_info_res
			
			i_count = i_count+1
		end	
	end

	local result = {} 
	result["list"] = resource_info_tab
	result["totalRow"] = totalRow
	result["totalPage"] = totalPage
	result["pageNumber"] = pageNumber
	result["pageSize"] = pageSize
	result["success"] = true
	
	cjson.encode_empty_table_as_object(false);
	
	--redis_db:set(tuijian_key.."_info",cjson.encode(result))
	redis_db:set(tuijian_key.."_"..pageSize.."_"..pageNumber.."_info",cjson.encode(result))
	
end

--local result_info = redis_db:get(tuijian_key.."_info")
local result_info = redis_db:get(tuijian_key.."_"..pageSize.."_"..pageNumber.."_info")

--redis放回连接池
redis_db:set_keepalive(0,v_pool_size)
--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)

ngx.print(result_info)






















