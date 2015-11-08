local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

if tostring(args["type"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"type参数错误\"}")    
    return
end

if tostring(args["yunormy"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"yunormy参数错误\"}")    
    return
end

if tostring(args["target_id"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"target_id参数错误\"}")    
    return
end


local res_type = tostring(args["type"])
local yunormy = tostring(args["yunormy"])
local target_id = tostring(args["target_id"])

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--连接redis
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end
if res_type == "1" then 
	--资源库
	if yunormy == "1" then
		local preview_status,err = ssdb_db:multi_hget("resource_"..target_id,"preview_status")
		if not preview_status then
			ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
			return
		end
		if tostring(preview_status[2])=="userdata: NULL" then
			ngx.say("{\"success\":false,\"info\":\"读缓存数据为空\"}")
			return
		end
		if preview_status[2] == "1" then
			local file_id =  cache:hget("resource_"..target_id,"file_id")
			local resource_title =  cache:hget("resource_"..target_id,"resource_title")
			local resource_page = cache:hget("resource_"..target_id,"resource_page")			
			local result = {}
			result["success"] = true
			result["preview_status"] = preview_status[2]
			result["file_id"] = file_id
			result["title"] = resource_title
			result["page"] = resource_page			
			local cjson = require "cjson"
			cjson.encode_empty_table_as_object(false)
			ngx.say(tostring(cjson.encode(result)))			
			return	
		else
			ngx.say("{\"success\":true,\"preview_status\":\""..preview_status[2].."\"}")   
			return	
		end
	else
		local preview_status[2],err = ssdb_db:multi_hget("myresource_"..target_id,"preview_status")
		if not preview_status[2] then
			ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
			return
		end
		if tostring(preview_status[2])=="userdata: NULL" then
			ngx.say("{\"success\":false,\"info\":\"读缓存数据为空\"}")
			return
		end
		
		if preview_status[2] == "1" then
			local file_id =  ssdb_db:multi_hget("myresource_"..target_id,"file_id")
			local resource_title =  ssdb_db:multi_hget("myresource_"..target_id,"resource_title")
			local resource_page = ssdb_db:multi_hget("myresource_"..target_id,"resource_page")
			local result = {}
			result["success"] = true
			result["preview_status"] = preview_status[2]
			result["file_id"] = file_id
			result["title"] = resource_title[2]
			result["page"] = resource_page[2]			
			local cjson = require "cjson"
			cjson.encode_empty_table_as_object(false)
			ngx.say(tostring(cjson.encode(result)))		
			return	
		else
			ngx.say("{\"success\":true,\"preview_status\":\""..preview_status[2].."\"}")   
			return	
		end
	end	
elseif res_type == "2" then
	--试卷库
	if yunormy == "0" then
		--不区分云试卷还是我的试卷
		local resource_info_id,err = cache:hget("paperinfo_"..target_id,"resource_info_id")
		if not resource_info_id then
			ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
			return
		end
		if tostring(resource_info_id)=="userdata: NULL" then
			ngx.say("{\"success\":false,\"info\":\"读缓存数据为空\"}")
			return
		end
		local preview_status[2] = ssdb_db:multi_hget("resource_"..resource_info_id,"preview_status")
		if preview_status[2] == "1" then
			local res_info =  ssdb_db:multi_hget("resource_"..resource_info_id,"file_id","resource_title","resource_page")
			local result = {}
			result["success"] = true
			result["preview_status"] = preview_status[2]
			result["file_id"] = res_info[2]
			result["title"] = res_info[4]
			result["page"] = res_info[6]	
			local cjson = require "cjson"
			cjson.encode_empty_table_as_object(false)
			ngx.say(tostring(cjson.encode(result)))		
			return	
		else
			ngx.say("{\"success\":true,\"preview_status\":\""..preview_status[2].."\"}")   
			return	
		end	
	end
end
--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size);