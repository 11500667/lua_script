#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-05-28
#描述：修改资源，试卷，备课的名称
]]
--1.获得参数方法
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

--传参数
if args["obj_id_int"] == nil or args["obj_id_int"] == "" then
    ngx.say("{\"success\":false,\"info\":\"obj_id_int参数错误！\"}")
    return
end
local obj_id_int  = tostring(args["obj_id_int"]);

if args["obj_name"] == nil or args["obj_name"] == "" then
    ngx.say("{\"success\":false,\"info\":\"obj_name参数错误！\"}")
    return
end
local obj_name  = tostring(args["obj_name"]);

-- type_id 1 资源备课 2 试卷
if args["type_id"] == nil or args["type_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"type_id参数错误！\"}")
    return
end
local type_id  = tostring(args["type_id"]);


local obj_id_char  = tostring(args["obj_id_char"]);


local myts = require "resty.TS";
local ts =  myts.getTs();

 --连接redis
local redis = require "resty.redis"
local cache = redis:new();
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
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
if type_id == "1" then
		local up_res = "UPDATE T_RESOURCE_BASE SET RESOURCE_TITLE = '"..obj_name.."',TS = "..ts.." WHERE RESOURCE_ID_INT = "..obj_id_int;
		--修改base表的数据
		local result_res, err, errno, sqlstate = db:query(up_res)
			if not result_res then
			 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
			  ngx.say("{\"success\":false,\"info\":\"修改资源的基本表失败！\"}")
			 return
			end
			
		--修改info表的数据
		local sel_info = "SELECT SQL_NO_CACHE id FROM t_resource_info_sphinxse WHERE query='filter=resource_id_int,"..obj_id_int.."'";
		local result_info = db:query(sel_info);
		for i=1,#result_info do
		   local up_info = "update t_resource_info set resource_title ='"..obj_name.."',update_ts = "..ts.." where id = ";
		   up_info = up_info..result_info[i]["id"];
		   local result_upinfo, err, errno, sqlstate = db:query(up_info)
			if not result_upinfo then
			  ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
			  ngx.say("{\"success\":false,\"info\":\"修改资源的info表失败！\"}")
			 return
			end
			--修改缓存
			-- lzy 2015-7-9
			local resourceInfo = {};
             resourceInfo.id = result_info[i]["id"];
             resourceInfo.resource_title = obj_name;
            local resourceUtil     = require "base.resource.model.ResourceUtil";
            local result = resourceUtil:setResourceInfo(resourceInfo)

	        if result==true then     
	        else
	            ngx.say("{\"success\":false,\"info\":\"修改失败\"}")
	         end

			--lzy 2015-7-9
		end

		--修改myinfo表的数据
		local sel_my_info = "SELECT SQL_NO_CACHE id FROM t_resource_my_info_sphinxse WHERE query='filter=resource_id_int,"..obj_id_int.."'";
		local result_my_info = db:query(sel_my_info);
		for i=1,#result_my_info do
		   local up_myinfo = "update t_resource_my_info set resource_title ='"..obj_name.."',update_ts = "..ts.." where id = ";
		   up_myinfo = up_myinfo..result_my_info[i]["id"];
		   local result_upmyinfo, err, errno, sqlstate = db:query(up_myinfo)
			if not result_upmyinfo then
			  ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
			  ngx.say("{\"success\":false,\"info\":\"修改资源的myinfo表失败！\"}")
			 return
			end
			--修改缓存
			--cache:hset("myresource_"..result_my_info[i]["id"],"resource_title",obj_name);

			-- lzy 2015-7-9
			local resourceInfo = {};
            resourceInfo.id = result_my_info[i]["id"];
            resourceInfo.resource_title = obj_name;
            local resourceUtil    = require "base.resource.model.ResourceUtil";
            local result = resourceUtil:setResourceMyInfo(resourceInfo)
	            if result==true then				
	            else
	               ngx.say("{\"success\":false,\"info\":\"修改失败\"}")
	            end

			--cache:hset("resource_"..result_info[i]["id"],"resource_title",obj_name);

			--lzy 2015-7-9

		end

elseif type_id == "2" then
        local data_new;
		local up_res = "UPDATE t_sjk_paper_base SET paper_name = '"..obj_name.."',TS = "..ts.." WHERE paper_id_int = "..obj_id_int;
		--修改base表的数据
		local result_res, err, errno, sqlstate = db:query(up_res)
			if not result_res then
			 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
			  ngx.say("{\"success\":false,\"info\":\"修改基本表失败！\"}")
			 return
			end
			
		--修改info表的数据
		local sel_info = "SELECT SQL_NO_CACHE id FROM t_sjk_paper_info_sphinxse WHERE query='filter=paper_id_int,"..obj_id_int.."'";
		local result_info = db:query(sel_info);
			for i=1,#result_info do
			   local up_info = "update t_sjk_paper_info set paper_name ='"..obj_name.."',update_ts = "..ts.." where id = ";
			   up_info = up_info..result_info[i]["id"];
			   local result_upinfo, err, errno, sqlstate = db:query(up_info)
				if not result_upinfo then
				  ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
				  ngx.say("{\"success\":false,\"info\":\"修改info表失败！\"}")
				 return
				end
				--修改缓存
				cache:hset("paper_"..result_info[i]["id"],"paper_name",obj_name);
				
				--判断是否是非格式化试卷
				local paper_value = hmget("paper_"..result_info[i]["id"],"paper_type","json_content");
			   
				if paper_value[1] == "1" then
					local json_content = paper_value[2];
					local data = cjson.decode(ngx.decode_base64(json_content))
		            data.paper_name = obj_name;
			        data_new = cjson.encode(data)
			        data_new = ngx.encode_base64(data_new);
					cache:hset("paper_"..result_info[i]["id"],"json_content",data_new);
				end
			end

		--修改myinfo表的数据
		local sel_my_info = "SELECT SQL_NO_CACHE id FROM t_sjk_paper_my_info_sphinxse WHERE query='filter=paper_id_int,"..obj_id_int.."'";
		local result_my_info = db:query(sel_my_info);
		    local up_myinfo = "update t_sjk_paper_my_info set paper_name ='"..obj_name.."',update_ts = "..ts.." where id = ";
			for i=1,#result_my_info do
			   up_myinfo = up_myinfo..result_my_info[i]["id"];
			   local result_upmyinfo, err, errno, sqlstate = db:query(up_myinfo)
				if not result_upmyinfo then
				  ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
				  ngx.say("{\"success\":false,\"info\":\"修改myinfo表失败！\"}")
				 return
				end
				--修改缓存
				cache:hset("mypaper_"..result_my_info[i]["id"],"paper_name",obj_name);
				
				--判断是否是非格式化试卷
				local paper_value = hmget("mypaper_"..result_info[i]["id"],"paper_type","json_content");
			   
				if paper_value[1] == "1" then
					local json_content = paper_value[2];
					local data = cjson.decode(ngx.decode_base64(json_content))
		            data.paper_name = obj_name;
			        data_new = cjson.encode(data)
			        data_new = ngx.encode_base64(data_new);
					cache:hset("mypaper_"..result_info[i]["id"],"json_content",data_new);
				end
				
				
			end
		
		--修改paperinfo缓存
		cache:hset("paperinfo_"..obj_id_char,"paper_name",obj_name);
		cache:hset("paperinfo_"..obj_id_char,"json_content",data_new);
elseif type_id == "3" then

        local up_res = "UPDATE t_wkds_base SET wkds_name = '"..obj_name.."' WHERE wkds_id_int = "..obj_id_int;
		--修改base表的数据
		local result_res, err, errno, sqlstate = db:query(up_res)
			if not result_res then
			 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
			  ngx.say("{\"success\":false,\"info\":\"修改基本表失败！\"}")
			 return
			end
			
		--修改info表的数据
		local sel_info = "SELECT SQL_NO_CACHE id FROM t_wkds_info_sphinxse WHERE query='filter=wkds_id_int,"..obj_id_int.."'";
		local result_info = db:query(sel_info);
		local cjson = require "cjson";
	
			ngx.log(ngx.ERR,"======================="..#result_info)
			for i=1,#result_info do
			   local up_info = "update t_wkds_info set wkds_name ='"..obj_name.."',update_ts = "..ts.." where id = ";
			   local content_json = cache:hget("wkds_"..result_info[i]["id"],"content_json")
		       
		       local data = cjson.decode(ngx.decode_base64(content_json))
		       data.wkds_name = obj_name;
			   local data_new = cjson.encode(data)
			   data_new = ngx.encode_base64(data_new);
			   up_info = up_info..result_info[i]["id"];
			    ngx.log(ngx.ERR,"------------------------------"..up_info)
			   local result_upinfo, err, errno, sqlstate = db:query(up_info)
				if not result_upinfo then
				  ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
				  ngx.say("{\"success\":false,\"info\":\"修改info表失败！\"}")
				 return
				end
				--修改缓存
				cache:hset("wkds_"..result_info[i]["id"],"wkds_name",obj_name);
				cache:hset("wkds_"..result_info[i]["id"],"content_json",data_new);
			end
			
end


local cjson = require "cjson";
local resultJson={};
resultJson.success = true;
resultJson.info = "修改名称成功！";
local responseJson = cjson.encode(resultJson);

-- 将redis连接归还到连接池
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
    ngx.log(ngx.ERR, "====>将Redis连接归还连接池出错！");
end

-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

ngx.say(responseJson);
