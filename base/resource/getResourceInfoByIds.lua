local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["ids"] == nil or args["ids"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"ids参数错误！\"}")
	return
end
local ids = args["ids"]

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

local cjson = require "cjson"
local myPrime = require "resty.PRIME";

function encodeURI(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end

local id = Split(ids,",")

local resource_tab = {}
for i=1,#id do
	local resource_info = {}
	ngx.log(ngx.ERR,"@@@"..id[i].."@@@")
	local resource_res = ssdb_db:multi_hget("resource_"..id[i],"resource_id_int","resource_title","resource_type_name","resource_format","resource_page","resource_size","create_time","down_count","file_id","thumb_id","preview_status","structure_id","scheme_id_int","person_name","width","height","bk_type_name","beike_type","resource_size_int","resource_type","person_id","material_type","resource_id_char","for_urlencoder_url","for_iso_url","app_type_id","subject_id")
	
	if tostring(resource_res[1]) ~= "ok" then
	
		resource_info["iid"] = iid
		resource_info["resource_id_int"] = resource_res[2]
		resource_info["resource_title"] = resource_res[4]
		resource_info["resource_type_name"] = resource_res[6]
		resource_info["resource_format"] = resource_res[8]
		resource_info["resource_page"] = resource_res[10]
		resource_info["resource_size"] = resource_res[12]
		resource_info["create_time"] = resource_res[14]

		resource_info["down_count"] = resource_res[16]
		resource_info["file_id"] = resource_res[18]
		resource_info["thumb_id"] = resource_res[20]
		resource_info["preview_status"] = resource_res[22]
		resource_info["structure_id"] = resource_res[24]
		resource_info["scheme_id_int"] = resource_res[26]
		resource_info["person_name_old"] = resource_res[28]
		resource_info["width"] = resource_res[30]
		resource_info["height"] = resource_res[32]
		resource_info["bk_type_name"] = resource_res[34]
		resource_info["beike_type"] = resource_res[36]
		resource_info["resource_size_int"] = resource_res[38]
		resource_info["resource_type"] = resource_res[40]
		resource_info["person_id"] = resource_res[42]

		resource_info["material_type"] = resource_res[44]
		resource_info["resource_id_char"] = resource_res[46]
		resource_info["for_urlencoder_url"] = resource_res[48]
		resource_info["for_iso_url"] = resource_res[50]
		resource_info["url_code"] = encodeURI(resource_res[4])
		
		local structure_id = resource_res[24]
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

		resource_info["parent_structure_name"] = curr_path

		local  app_type_id = resource_res[52];
		local scheme_id = resource_res[26];
		local app_type_name = "";
		if app_type_id ~= "-1" then
			local  app_typeids =myPrime.dec_prime(app_type_id);
			local app_type_name_tab = {};
					   -- local app_type_name = "";
			app_type_name_tab = Split(app_typeids,",");
			for i=1,#app_type_name_tab do
					  local apptypename = cache:hmget("t_base_apptype_"..scheme_id.."_"..app_type_name_tab[i],"app_type_name")
					  app_type_name = app_type_name..","..tostring(apptypename[1]);
			end
			app_type_name = string.sub(app_type_name,2,#app_type_name);
		end

		resource_info["app_type_name"] = app_type_name
		resource_info["app_type_id"] = app_type_id

		local person_id = resource_res[42]
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
			local org_name_body = ngx.location.capture("/dsideal_yy/person/getOrgnameByPerson?person_id="..      person_id.."&identity_id=5")
			org_name = org_name_body.body
			person_name = cache:hget("person_"..person_id.."_5","person_name");
			if person_name == ngx.null then
				person_name = "未知";
			end
		end
		
		resource_info["org_name"] = org_name
		resource_info["person_name"] = person_name

		resource_tab[i] = resource_info
	
	end
end

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)

local result = {}
result["success"] = true

cjson.encode_empty_table_as_object(false)
ngx.print(tostring(cjson.encode(resource_tab)))