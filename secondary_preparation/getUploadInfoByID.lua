#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-09-08
#描述：获得上传资源，备课，试卷的信息
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

--传参数
if args["type"] == nil or args["type"] == "" then
    ngx.say("{\"success\":false,\"info\":\"type参数错误！\"}")
    return
end
local type_id  = tostring(args["type"]);

if args["obj_id_int"] == nil or args["obj_id_int"] == "" then
    ngx.say("{\"success\":false,\"info\":\"obj_id_int参数错误！\"}")
    return
end
local obj_id_int  = tostring(args["obj_id_int"]);
local obj_info = {};
if type_id == "1" then
	--试卷
	--获得试卷信息
	local sql = "SELECT SQL_NO_CACHE ID FROM t_sjk_paper_info_sphinxse WHERE query = 'filter=paper_id_int,"..obj_id_int..";'";
	local paper_ids = db:query(sql);
	local paper_info_id = paper_ids[1]["ID"];
	local paper_info = cache:hmget("paper_"..paper_info_id,"subject_id","scheme_id","structure_id","paper_app_type","paper_app_type_name")
	
	local structure_ids =paper_info[3];
	local scheme_id = paper_info[2];
	local subject_id = paper_info[1];
	local paper_app_type = paper_info[4];
	local paper_app_type_name = paper_info[5];
	local share_type = 0;
	local share_ids = "";
	local group_id =2;
	local paper_type = 2;
	obj_info.structure_ids = structure_ids;
	obj_info.scheme_id = scheme_id;
	obj_info.subject_id = subject_id;
	obj_info.paper_app_type = paper_app_type;
	obj_info.paper_app_type_name = paper_app_type_name;
	obj_info.share_type = share_type;
	obj_info.share_ids = share_ids;
	obj_info.group_id = group_id;
	obj_info.paper_type = paper_type;
	
	 
elseif type_id =="2" then
    --备课
	local sql = "SELECT SQL_NO_CACHE ID FROM t_resource_info_sphinxse WHERE query = 'filter=resource_id_int,"..obj_id_int..";'";
	local resource_ids = db:query(sql);
	local resource_info_id = resource_ids[1]["ID"];
	local beike_info = ssdb_db:multi_hget("resource_"..resource_info_id,"subject_id","scheme_id_int","structure_id","beike_type","bk_type_name")
	
    local media_type =-1;
	local structure_ids = beike_info[6]
	local scheme_id =beike_info[4]
	local subject_id =  beike_info[2]
	local share_type = 0;
	local share_ids = "";
	local checkboxids = "";
	local res_type =2;
	local bk_type=beike_info[8];
	local bk_type_name = beike_info[10];
	local group_id=2;
	
	obj_info.media_type =media_type;
	obj_info.structure_ids =structure_ids;
	obj_info.scheme_id =scheme_id;
	obj_info.subject_id =subject_id;
	obj_info.share_type =share_type;
	obj_info.share_ids =share_ids;
	obj_info.checkboxids =checkboxids;
	obj_info.res_type =res_type;
	obj_info.bk_type =bk_type;
	obj_info.bk_type_name =bk_type_name;
	obj_info.group_id =group_id;

elseif type_id == "3" then

    local sql = "SELECT SQL_NO_CACHE ID FROM t_resource_info_sphinxse WHERE query = 'filter=resource_id_int,"..obj_id_int..";'";
	local resource_ids = db:query(sql);
	local resource_info_id = resource_ids[1]["ID"];
	ngx.log(ngx.ERR,"**************************"..resource_info_id)
	local resource_info = ssdb_db:multi_hget("resource_"..resource_info_id,"subject_id","scheme_id_int","structure_id","app_type_id")
	
    local media_type = resource_info[8];
	local structure_ids = resource_info[6];
	local scheme_id= resource_info[4];
	local subject_id = resource_info[2];
	local share_type = 0;
	local share_ids = "";
	local checkboxids = "";
	local res_type =1;
	local bk_type = 0;
	local bk_type_name = "-1";
	local group_id =2;
	local obj_type=1;
	local pub_target = "";
	
	obj_info.media_type =media_type;
	obj_info.structure_ids =structure_ids;
	obj_info.scheme_id =scheme_id;
	obj_info.subject_id =subject_id;
	obj_info.share_type =share_type;
	obj_info.share_ids =share_ids;
	obj_info.checkboxids =checkboxids;
	obj_info.res_type =res_type;
	obj_info.bk_type =bk_type;
	obj_info.bk_type_name =bk_type_name;
	obj_info.group_id =group_id;
	obj_info.obj_type =obj_type;
	obj_info.pub_target =pub_target;

end
-- 将redis连接归还到连接池
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
    ngx.log(ngx.ERR, "====>将redis数据库连接归还连接池出错");
end

-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size);
obj_info.success = true;
-- 将table对象转换成json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(obj_info);
ngx.say(responseJson)
