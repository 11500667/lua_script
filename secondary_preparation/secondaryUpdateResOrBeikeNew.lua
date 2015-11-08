#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-05-07
#描述：weboffice中修改资源和备课
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
if args["resource_id_int"] == nil or args["resource_id_int"] == "" then
    ngx.say("{\"success\":false,\"info\":\"resource_id_int参数错误！\"}")
    return
end
local resource_id_int  = tostring(args["resource_id_int"]);

if args["file_id"] == nil or args["file_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"file_id参数错误！\"}")
    return
end
local file_id  = tostring(args["file_id"]);

if args["extension"] == nil or args["extension"] == "" then
    ngx.say("{\"success\":false,\"info\":\"extension参数错误！\"}")
    return
end
local extension  = tostring(args["extension"]);

if args["new_obj_id_int"] == nil or args["new_obj_id_int"] == "" then
    ngx.say("{\"success\":false,\"info\":\"new_obj_id_int参数错误！\"}")
    return
end
local new_obj_id_int  = tostring(args["new_obj_id_int"]);

local old_obj_id_int = resource_id_int;

if args["new_person_id"] == nil or args["new_person_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"new_person_id参数错误！\"}")
    return
end
local new_person_id  = tostring(args["new_person_id"]);

if args["old_person_id"] == nil or args["old_person_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"old_person_id参数错误！\"}")
    return
end
local old_person_id  = tostring(args["old_person_id"]);

if args["yuan_obj_info_id"] == nil or args["yuan_obj_info_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"yuan_obj_info_id参数错误！\"}")
    return
end
local yuan_obj_info_id  = tostring(args["yuan_obj_info_id"]);

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
--获得人员所在学校的id
--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local extension_info = cache:hmget("t_resource_extension_"..extension,"thumb_status","preview_status","thumb_id","mediatype_id","mediatype_name");
local create_time = ngx.localtime();
 local myts = require "resty.TS";
local ts =  myts.getTs();
local update_ts = ts;
local thumbid = extension_info[3];
local preview_status = extension_info[2];
local thumb_status = extension_info[1];
local resource_type = extension_info[4];
local resource_type_name = extension_info[5];

--拼接sql语句
local up_base = "update t_resource_base set resource_type="..resource_type..",resource_type_name='"..resource_type_name.."',extension = '"..extension.."',create_time = '"..create_time.."',resource_size_int = -1,file_id = '"..file_id.."',FILE_MD5=-1,FILE_SHA1=-1,FOR_URLEncoder_Url=-1,FOR_ISO_Url=-1,PREVIEW_STATUS="..preview_status..",THUMB_STATUS="..thumb_status..",THUMB_ID='"..thumbid.."',TS="..ts.." where resource_id_int = "..resource_id_int;  	

local sel_info = "SELECT SQL_NO_CACHE ID FROM t_resource_info_sphinxse WHERE query='filter=RESOURCE_ID_INT,"..resource_id_int.."'";
local sel_my_info = "SELECT SQL_NO_CACHE ID FROM t_resource_my_info_sphinxse WHERE query='filter=RESOURCE_ID_INT,"..resource_id_int.."'";

local resource_map= {};
resource_map.file_id = -1;
resource_map.for_iso_url = -1;
resource_map.for_urlencoder_url = -1;
resource_map.preview_status = preview_status;
resource_map.thumb_id = thumbid;
resource_map.resource_page = 0;
resource_map.resource_size = -1;
resource_map.resource_size_int = -1;
resource_map.create_time = create_time;
resource_map.resource_type = resource_type;
resource_map.resource_type_name = resource_type_name;
resource_map.resource_format = extension;

local up_info = "update t_resource_info set resource_type="..resource_type..",resource_type_name='"..resource_type_name.."',resource_format='"..extension.."',create_time = '"..create_time.."',resource_size_int = -1,file_id = '"..file_id.."',FOR_URLEncoder_Url=-1,FOR_ISO_Url=-1,PREVIEW_STATUS="..preview_status..",THUMB_STATUS="..thumb_status..",THUMB_ID='"..thumbid.."',TS="..ts..",update_ts="..update_ts.." where id = ";


local info_list, err, errno, sqlstate = db:query(sel_info)
	if not info_list then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	 return
    end

	
for i=1,#info_list do
  up_info = up_info..info_list[i]["ID"];   
    --修改数据库  
    local result_info, err, errno, sqlstate = db:query(up_info)
	 if not result_info then
	  ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	  return
	  else
	 --修改缓存
	 cache:hmset("resource_"..info_list[i]["ID"],resource_map);
    end 

end
 
local my_info_list, err, errno, sqlstate = db:query(sel_my_info)
	if not my_info_list then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	 return
    end

local up_my_info = "update t_resource_my_info set resource_type="..resource_type..",resource_type_name='"..resource_type_name.."',resource_format='"..extension.."',create_time = '"..create_time.."',resource_size_int = -1,file_id = '"..file_id.."',FOR_URLEncoder_Url=-1,FOR_ISO_Url=-1,PREVIEW_STATUS="..preview_status..",THUMB_STATUS="..thumb_status..",THUMB_ID='"..thumbid.."',TS="..ts..",update_ts="..update_ts.." where id = ";
	
for i=1,#my_info_list do
   up_my_info = up_my_info..my_info_list[i]["ID"];   
    --修改数据库  
    local result_my_info, err, errno, sqlstate = db:query(up_my_info)
	 if not result_my_info then
	  ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	  return
	  else
	 --修改缓存
	 cache:hmset("myresource_"..my_info_list[i]["ID"],resource_map);
    end 

end

local result, err, errno, sqlstate = db:query(up_base)
	if not result then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	 return
    end

local appname_body = ngx.location.capture("/dsideal_yy/ypt/secondary/saveUpdateRecord?scheme_id="..res_info[18].."&app_type_id="..res_info[17])
	
-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end
-- 将redis连接归还到连接池
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
    ngx.log(ngx.ERR, "====>将redis数据库连接归还连接池出错");
end
 ngx.say("{\"success\":true,\"info\":\"修改成功\"}")


