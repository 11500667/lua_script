#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-05-07
#描述：weboffice中修改非格式化试卷
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
if args["paper_id_int"] == nil or args["paper_id_int"] == "" then
    ngx.say("{\"success\":false,\"info\":\"paper_id_int参数错误！\"}")
    return
end
local paper_id_int  = tostring(args["paper_id_int"]);

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

if args["paper_id_char"] == nil or args["paper_id_char"] == "" then
    ngx.say("{\"success\":false,\"info\":\"paper_id_char参数错误！\"}")
    return
end
local paper_id_char  = tostring(args["paper_id_char"]);

if args["paper_name"] == nil or args["paper_name"] == "" then
    ngx.say("{\"success\":false,\"info\":\"paper_name参数错误！\"}")
    return
end
local paper_name  = tostring(args["paper_name"]);


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

local extension_info = cache:hmget("t_resource_extension_"..extension,"thumb_status","preview_status","thumb_id");
local create_time = ngx.localtime();
 local myts = require "resty.TS";
local ts =  myts.getTs();
local thumbid = extension_info[3];
local preview_status = extension_info[2];
local thumb_status = extension_info[1];


--查询云试卷的info表id
local sel_paper_info = "SELECT SQL_NO_CACHE ID from t_sjk_paper_info_sphinxse WHERE query='filter=paper_id_int,"..paper_id_int.."'";
local paper_info_list = db:query(sel_paper_info);
local resource_map= {};
local paper_map = {};
paper_map.create_time = create_time;
paper_map.paper_name = paper_name;
paper_map.extension = extension;


resource_map.file_id = file_id;
resource_map.for_iso_url = -1;
resource_map.for_urlencoder_url = -1;
resource_map.preview_status = preview_status;
resource_map.thumb_id = thumbid;
resource_map.resource_page = 0;
resource_map.resource_size = -1;
resource_map.resource_size_int = -1;
resource_map.create_time = create_time;
resource_map.resource_title = resource_title;
resource_map.resource_format = extension;
--拼接sql语句
local up_base = "update t_resource_base set resource_title = '"..paper_name.."' ,create_time = '"..create_time.."',resource_size_int = -1,file_id = '"..file_id.."',FILE_MD5=-1,FILE_SHA1=-1,FOR_URLEncoder_Url=-1,FOR_ISO_Url=-1,PREVIEW_STATUS="..preview_status..",extension = '"..extension.."',THUMB_STATUS="..thumb_status..",THUMB_ID='"..thumbid.."',TS="..ts.." where resource_id_int = ";


local up_info = "update t_resource_info set resource_title = '"..paper_name.."',create_time = '"..create_time.."',resource_size_int = -1,file_id = '"..file_id.."',FOR_URLEncoder_Url=-1,FOR_ISO_Url=-1,PREVIEW_STATUS="..preview_status..",THUMB_STATUS="..thumb_status..",resource_format = '"..extension.."'THUMB_ID='"..thumbid.."',TS="..ts..",update_ts="..ts.." where id = ";

ngx.log(ngx.ERR,"=========="..up_info);
local up_paper_base = "UPDATE t_sjk_paper_base SET paper_name = '"..paper_name.."',extension = '"..extension.."',CREATE_TIME = '"..create_time.."',TS = "..ts..",UPDATE_TS = "..ts.." WHERE paper_id_int = ";

local up_paper_info = "UPDATE t_sjk_paper_info SET paper_name = '"..paper_name.."',extension = '"..extension.."',CREATE_TIME = '"..create_time.."',TS = "..ts..",UPDATE_TS = "..ts.." WHERE ID = ";

local sel_res_info_id = "SELECT resource_info_id FROM t_sjk_paper_info WHERE ID = ";
for i=1,#paper_info_list do
 sel_res_info_id = sel_res_info_id..paper_info_list[1]["ID"];
 --根据id获得对应的resource_info_id
 ngx.log(ngx.ERR,"==========="..sel_res_info_id)
 local resource_info_id_tab = db:query(sel_res_info_id);
 local resource_info_id = resource_info_id_tab[1]["resource_info_id"];
 --根据resource_info_id获得对应的resource_id_int,取缓存
 local resource_id_int = ssdb_db:multi_hget("resource_"..resource_info_id,"resource_id_int");
 --修改资源base表
 local update_base_result = db:query(up_base..resource_id_int[2]);

 --修改资源info表
 local update_resinfo_result = db:query(up_info..resource_info_id);
    --修改缓存
    resource_map.id = resource_info_id;
    local resourceUtil  = require "base.resource.model.ResourceUtil";
    local result = resourceUtil:setResourceInfo(resource_map)
    if result~=true then
            ngx.say("{\"success\":false,\"info\":\"type_id参数错误！\"}")
    end
--修改paper_base
db:query(up_paper_base..paper_id_int);    

 --修改paper的info表
 local update_paperinfo_result = db:query(up_paper_info..paper_info_list[1]["ID"]);
    --修改缓存
cache:hmset("paper_"..paper_info_list[1]["ID"],paper_map);

end



--查询我的试卷的info表id
local sel_paper_my_info = "SELECT SQL_NO_CACHE ID from t_sjk_paper_my_info_sphinxse WHERE query='filter=paper_id_int,"..paper_id_int.."'";
local up_paper_my_info = "UPDATE t_sjk_paper_my_info SET paper_name = '"..paper_name.."',extension = '"..extension.."',CREATE_TIME = '"..create_time.."',TS = "..ts..",UPDATE_TS = "..ts.." WHERE ID = ";
local paper_my_info_list = db:query(sel_paper_my_info);

for j=1,#paper_my_info_list do
   local update_papermyinfo_result = db:query(up_paper_my_info..paper_my_info_list[1]["ID"]);
     --修改缓存
	 cache:hmset("mypaper_"..paper_my_info_list[1]["ID"],paper_map);
end
  
--修改paperinfo的缓存
cache:hmset("paperinfo_"..paper_id_char,paper_map);
  
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

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size);

 ngx.say("{\"success\":true,\"info\":\"修改试卷成功\"}")











