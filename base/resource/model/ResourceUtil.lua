--[[
#吴缤 2015-07-07
#描述：资源工具类
]]


local _resourceUtil = {};

---------------------------------------------------------------------------

--[[
	功能：将中文进行URL加码
]]
local function encodeURI(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end


---------------------------------------------------------------------------
--[[
	函数描述： 根据应用类型的质数值获取应用类型名称
	参    数： appTypeId  	应用类型质数值
	返 回 值： 应用类型名称
]]
local function getAppTypeName(self, appTypeId, schemeId)
	
	local CacheUtil = require "common.CacheUtil";
	local cache = CacheUtil: getRedisConn();
	
	local myPrime           = require "resty.PRIME";
	local app_typeids       = myPrime.dec_prime(appTypeId);
	local app_type_name_tab = {};
	local app_type_name     = "";
    app_type_name_tab       = Split(app_typeids, ",");
    for i=1, #app_type_name_tab do
        local apptypename = cache:hmget("t_base_apptype_" .. schemeId .. "_" .. app_type_name_tab[i], "app_type_name")
          app_type_name = app_type_name .. "," .. tostring(apptypename[1]);
    end

    app_type_name = string.sub(app_type_name, 2, #app_type_name);
	
	-- 将Redis连接归还连接池
	CacheUtil:keepConnAlive(cache);
	return app_type_name;
end
_resourceUtil.getAppTypeName = getAppTypeName;

--[[
	局部函数： 	根据一个资源info_id的table返回资源信息
	作者：     	吴缤 2015-07-07
	参数：     	info_ids  
	返回值：  	资源的JSON串
	
]]
local function getResourceInfoByIds(self, ids)	
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
	
	local resource_tab = {}
	for i=1,#ids do
		local resource_info = {}		
		local resource_res = ssdb_db:multi_hget("resource_"..ids[i]["id"],"resource_id_int","resource_title","resource_type_name","resource_format","resource_page","resource_size","create_time","down_count","file_id","thumb_id","preview_status","structure_id","scheme_id_int","person_name","width","height","bk_type_name","beike_type","resource_size_int","resource_type","person_id","material_type","resource_id_char","for_urlencoder_url","for_iso_url","app_type_id","subject_id","release_status","is_secondary","res_type")
		
		if tostring(resource_res[1]) ~= "ok" then
		
			resource_info["iid"] = ids[i]["id"]
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
			resource_info["release_status"] = resource_res[56]
			resource_info["is_secondary"] = resource_res[58]
			
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
			local org_id = "1";
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
				person_info = cache:hmget("person_"..person_id.."_5","person_name","xiao");
				person_name = person_info[1];
				org_id = person_info[2];
				if person_name == ngx.null then
					person_name = "未知";
				end
			end
			
			resource_info["org_name"] = org_name
			resource_info["person_name"] = person_name
			resource_info["org_id"] = org_id
			
			resource_info["stage_sujbect"] = ssdb_db:hget("subject_"..resource_res[54],"stage_subject")[1]

			if resource_res[60] == "2" then
			    if resource_res[38] == "102" or resource_res[38] == "104" or resource_res[38] == "107" or resource_res[38] == "109" then
				    local teach_info = ssdb_db:multi_hget("teach_resource_"..resource_res[2],"update_logo","is_summary")
					resource_info["update_logo"] = teach_info[2];
					resource_info["is_summary"] = teach_info[4];	
			  end
			end
			
			resource_tab[i] = resource_info
	        
		
		end
	end
	
	--放回到SSDB连接池
	ssdb_db:set_keepalive(0,v_pool_size)
	cache:set_keepalive(0,v_pool_size)	
	return resource_tab
end
_resourceUtil.getResourceInfoByIds = getResourceInfoByIds;

--[[
	局部函数： 	根据一个资源info_id的table返回资源信息
	作者：     	李政言 2015-08-18
	参数：     	info_ids  
	返回值：  	资源的JSON串
	
]]
local function getResourceByIds(self, ids)	
   local ids_tab = {};
   ids_tab = Split(ids,",")
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
	
	local resource_tab = {}
	for i=1,#ids_tab do
		local resource_info = {}		
		local resource_res = ssdb_db:multi_hget("resource_"..ids_tab[i],"resource_id_int","resource_title","resource_type_name","resource_format","resource_page","resource_size","create_time","down_count","file_id","thumb_id","preview_status","structure_id","scheme_id_int","person_name","width","height","bk_type_name","beike_type","resource_size_int","resource_type","person_id","material_type","resource_id_char","for_urlencoder_url","for_iso_url","app_type_id","subject_id","release_status","is_secondary")
		
		if tostring(resource_res[1]) ~= "ok" then
		
			resource_info["iid"] = ids_tab["id"]
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
			resource_info["release_status"] = resource_res[56]
			resource_info["is_secondary"] = resource_res[58]
			
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
			
			resource_info["stage_sujbect"] = ssdb_db:hget("subject_"..resource_res[54],"stage_subject")[1]

			resource_tab[i] = resource_info
		
		end
	end
	
	--放回到SSDB连接池
	ssdb_db:set_keepalive(0,v_pool_size)
	cache:set_keepalive(0,v_pool_size)	
	return resource_tab
end
_resourceUtil.getResourceByIds = getResourceByIds;


---------------------------------------------------------------------------
local function getResourceInfoByIds_tuijian(self, ids,bureau_id,tuijian_key)	
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
	
	local resource_tab = {}
	for i=1,#ids do
		local resource_info = {}		
		local resource_res = ssdb_db:multi_hget("resource_"..ids[i]["id"],"resource_id_int","resource_title","resource_type_name","resource_format","resource_page","resource_size","create_time","down_count","file_id","thumb_id","preview_status","structure_id","scheme_id_int","person_name","width","height","bk_type_name","beike_type","resource_size_int","resource_type","person_id","material_type","resource_id_char","for_urlencoder_url","for_iso_url","app_type_id","subject_id","release_status","is_secondary")
		
		if tostring(resource_res[1]) ~= "ok" then
		
			resource_info["iid"] = ids[i]["id"]
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
			resource_info["release_status"] = resource_res[56]
			resource_info["is_secondary"] = resource_res[58]
			
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
			
			resource_info["stage_sujbect"] = ssdb_db:hget("subject_"..resource_res[54],"stage_subject")[1]
			
			local tuijian = ssdb_db:zexists("tuijian_"..tuijian_key.."_"..bureau_id,ids[i]["id"])
			resource_info["tuijian"] = tuijian[1]

			resource_tab[i] = resource_info
		
		end
	end
	
	--放回到SSDB连接池
	ssdb_db:set_keepalive(0,v_pool_size)
	cache:set_keepalive(0,v_pool_size)	
	return resource_tab
end
_resourceUtil.getResourceInfoByIds_tuijian = getResourceInfoByIds_tuijian;

---------------------------------------------------------------------------


--[[
	局部函数：设置资源的属性
	作者： 	李政言 2015-04-02
	参数： 	resourceTab  		需要修改的属性
	返回值：boolean      	true是设置成功，false设置失败
]]
local function setResourceInfo(self, resourceTab)
	local cjson = require "cjson"
	--连接ssdb
	local ssdb = require "resty.ssdb"
    local ssdb_db = ssdb:new()
    local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
      if not ok then
         ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
      return
    end
	--获得资源的id
	local resource_info_id = resourceTab.id;
	
	local ssdbParam =  {};
	for k,v in pairs(resourceTab) do
		table.insert(ssdbParam, k);
		table.insert(ssdbParam, v);
	end
	
	--设置ssdb中的属性
	local result = ssdb_db:multi_hset("resource_"..resource_info_id, unpack(ssdbParam));
	
	if result=="false" then
	  return false;
	else
	  return true;
	end 
	
end

_resourceUtil.setResourceInfo = setResourceInfo;

---------------------------------------------------------------------------

--[[
	局部函数：设置资源的属性
	作者： 	李政言 2015-04-02
	参数： 	resourceTab  		需要修改的属性
	返回值：boolean      	true是设置成功，false设置失败
]]
local function setResourceMyInfo(self, resourceTab)
	local cjson = require "cjson"
	--连接ssdb
	local ssdb = require "resty.ssdb"
    local ssdb_db = ssdb:new()
    local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
      if not ok then
         ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
      return
    end
	--获得资源的id
	local resource_info_id = resourceTab.id;
	
	local ssdbParam =  {};
	for k,v in pairs(resourceTab) do
		table.insert(ssdbParam, k);
		table.insert(ssdbParam, v);
	end
	
	--设置ssdb中的属性
	local result = ssdb_db:multi_hset("myresource_"..resource_info_id, unpack(ssdbParam));
	
	if result=="false" then
	  return false;
	else
	  return true;
	end 
	
end

_resourceUtil.setResourceMyInfo = setResourceMyInfo;

---------------------------------------------------------------------------

return _resourceUtil;

