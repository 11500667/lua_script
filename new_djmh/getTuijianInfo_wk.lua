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

--判断学科是不是全部，然后统一给SSDB KEY
local tuijian_key = ""
if stage_id == "-1" then
	tuijian_key = "tuijian_wk_"..bureau_id
else
	if subject_id == "-1" then
		tuijian_key = "tuijian_wk_"..bureau_id.."_"..stage_id
	else
		tuijian_key = "tuijian_wk_"..bureau_id.."_"..stage_id.."_"..subject_id
	end
end

local tuijian_wk_ts = redis_db:get("tuijian_wk_ts_"..bureau_id)
--local tuijian_wk_generate_ts = redis_db:get(tuijian_key.."_ts")
local tuijian_wk_generate_ts = redis_db:get(tuijian_key.."_"..pageSize.."_"..pageNumber.."_ts")

if tuijian_wk_ts == ngx.null then
	local uuid =  require "resty.uuid";
	tuijian_wk_ts = uuid.new();	
	redis_db:set("tuijian_wk_ts_"..bureau_id,tuijian_wk_ts)		
end

if tuijian_wk_generate_ts ~= tuijian_wk_ts or tuijian_wk_generate_ts == ngx.null then

	--redis_db:set(tuijian_key.."_ts",tuijian_wk_ts)
	redis_db:set(tuijian_key.."_"..pageSize.."_"..pageNumber.."_ts",tuijian_wk_ts)

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
					local thumbid = ssdb_db:hget("resource_"..resource_info_id,"thumb_id")
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
			resource_info_res["thumb_id"] = thumb_id
			
			resource_info_tab[i_count] = resource_info_res
			
			i_count = i_count+1
		end	
	end

	local result = {} 
	result["wk_list"] = resource_info_tab
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




