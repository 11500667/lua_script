#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-01-21
#描述：电子书包上传素材
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
 local myts = require "resty.TS";

--接收参数
--获得人员id
if args["create_person"] == nil or args["create_person"] == "" then
    ngx.say("{\"success\":false,\"info\":\"create_person参数错误！\"}")
    return
end
local create_person = args["create_person"];

--获得人员名
if args["person_name"] == nil or args["person_name"] == "" then
    ngx.say("{\"success\":false,\"info\":\"person_name参数错误！\"}")
    return
end
local person_name = args["person_name"];

--获得身份id
if args["identity_id"] == nil or args["identity_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"identity_id参数错误！\"}")
    return
end
local identity_id = args["identity_id"];

--获得文件名
if args["file_name"] == nil or args["file_name"] == "" then
    ngx.say("{\"success\":false,\"info\":\"file_name参数错误！\"}")
    return
end
local file_name = args["file_name"];


--获得thumb_id
if args["thumb_id"] == nil or args["thumb_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"thumb_id参数错误！\"}")
    return
end
local thumb_id = args["thumb_id"];

--获得file_id
if args["file_id"] == nil or args["file_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"file_id参数错误！\"}")
    return
end
local file_id = args["file_id"];


--获得resource_category
if args["resource_category"] == nil or args["resource_category"] == "" then
    ngx.say("{\"success\":false,\"info\":\"resource_category参数错误！\"}")
    return
end
local resource_category = args["resource_category"];

--获得resource_size_int
if args["resource_size_int"] == nil or args["resource_size_int"] == "" then
    ngx.say("{\"success\":false,\"info\":\"resource_size_int参数错误！\"}")
    return
end
local resource_size_int = args["resource_size_int"];

--获得scheme_id_int
if args["scheme_id_int"] == nil or args["scheme_id_int"] == "" then
    ngx.say("{\"success\":false,\"info\":\"scheme_id_int参数错误！\"}")
    return
end
local scheme_id_int = args["scheme_id_int"];


--获得structure_id_int
if args["structure_id_int"] == nil or args["structure_id_int"] == "" then
    ngx.say("{\"success\":false,\"info\":\"structure_id_int参数错误！\"}")
    return
end
local structure_id_int = args["structure_id_int"];

--获得is_shared
if args["is_shared"] == nil or args["is_shared"] == "" then
    ngx.say("{\"success\":false,\"info\":\"is_shared参数错误！\"}")
    return
end
local is_shared = args["is_shared"];

--获得group_id
if args["group_id"] == nil or args["group_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"group_id参数错误！\"}")
    return
end
local group_id = args["group_id"];

--获得class_info
if args["class_info"] == nil or args["class_info"] == "" then
    ngx.say("{\"success\":false,\"info\":\"class_info参数错误！\"}")
    return
end
local class_info = args["class_info"];

--获得subject_id
if args["subject_id"] == nil or args["subject_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"subject_id参数错误！\"}")
    return
end
local subject_id = args["subject_id"];

--获得thumb_id
-- if args["thumb_id"] == nil or args["thumb_id"] == "" then
    -- ngx.say("{\"success\":false,\"info\":\"thumb_id参数错误！\"}")
    -- return
-- end
-- local thumb_id = args["thumb_id"];

--获得共享id
if args["share_ids"] == nil or args["share_ids"] == "" then
    ngx.say("{\"success\":false,\"info\":\"share_ids参数错误！\"}")
    return
end
local share_ids = args["share_ids"];
--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local id_ssdb = ssdb_db:incr("t_bag_resource_info_pk");
local cjson = require "cjson";
local id = id_ssdb[1]

ngx.log(ngx.ERR,"id="..id);
local TS = require "resty.TS";
local ts = TS.getTs();

local Size = require "resty.getSize";
local resource_size = Size.byteTo(resource_size_int);

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

local in_bag = "INSERT INTO t_bag_resource_info(ID,RESOURCE_TITLE,RESOURCE_CATEGORY,RESOURCE_SIZE_INT,CREATE_PERSON,IDENTITY_ID,TS,SCHEME_ID_INT,STRUCTURE_ID_INT,B_DELETE,UPDATE_TS,GROUP_ID,DOWN_COUNT,SUBJECT_ID) VALUES ("..id..",'"..file_name.."',"..resource_category..","..resource_size_int..","..create_person..","..identity_id..","..ts..","..scheme_id_int..","..structure_id_int..",0,"..ts..","..group_id..",0,"..subject_id..");";
ngx.log(ngx.ERR,"in_bag"..in_bag)
--写入数据库
local res_bag, err, errno, sqlstate = db:query(in_bag)
   if not res_bag then
	 ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	 return
    end
--写入ssdb
local create_time = os.date("%Y-%m-%d %H:%M:%S")
ssdb_db:multi_hset(
	"bag_res_"..id, 
	"resource_title", file_name, 
	"resource_category", resource_category,
	"resource_size_int", resource_size_int,
	"resource_size", resource_size,
	"create_person", create_person,
	"person_name", person_name,
	"identity_id", identity_id,
	"ts", ts,
	"scheme_id_int", scheme_id_int,
	"structure_id_int", structure_id_int,
	"b_delete", "0",
	"group_id", group_id,
	"down_count", "0",
	"subject_id", subject_id,
	"thumb_id", thumb_id,
	"file_id",file_id,
	"create_time",create_time
);

if is_shared == "1" then
local share_ids_tab = Split(share_ids,",")
ngx.log(ngx.ERR,"ddsdsdsd"..share_ids)
   --写入数据库
   for i=1,#share_ids_tab do
      local id_ssdb_share = ssdb_db:incr("t_bag_resource_info_pk");
      local cjson = require "cjson";
      local id_share = id_ssdb_share[1]
      local share_group_id = share_ids_tab[i];
	  ngx.log(ngx.ERR,"======================="..share_group_id)
      local in_bag_share = "INSERT INTO t_bag_resource_info(ID,RESOURCE_TITLE,RESOURCE_CATEGORY,RESOURCE_SIZE_INT,CREATE_PERSON,IDENTITY_ID,TS,SCHEME_ID_INT,STRUCTURE_ID_INT,B_DELETE,UPDATE_TS,GROUP_ID,DOWN_COUNT,SUBJECT_ID) VALUES ("..id_share..",'"..file_name.."',"..resource_category..","..resource_size_int..","..create_person..","..identity_id..","..ts..","..scheme_id_int..","..structure_id_int..",0,"..ts..","..share_group_id..",0,"..subject_id..");";
      local res_bag_share, err, errno, sqlstate = db:query(in_bag_share)
      if not res_bag then
	     ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	  return
      end
   end
  
end

--处理班级
if class_info ~= "-1" then
	local data = cjson.decode(ngx.decode_base64(class_info))
	for i=1,#data do 
		local class_id = data[i].class_id
		local is_open = -1
		if resource_category == "6" then
			is_open = data[i].is_open
		end
		local class_sql = "INSERT INTO t_bag_resource_class(RESOURCE_ID,CLASS_ID,IS_OPEN,TYPE_ID) VALUES ("..id..","..class_id..","..is_open..","..resource_category..");";
		local res_class, err, errno, sqlstate = db:query(class_sql)
		if not res_bag then
			ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
		return
		end
	end
end


--ssdb_db:multi_hset("bag_res_"..id,bag_res_tab);

-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)
ngx.say("{\"success\":true}");
--ngx.say("{\"success\":true,\"resource_info_id\":\""..resource_info_id.."\",\"resource_myinfo_id\":\""..resource_my_info_id.."\",\"resource_id_int\":\""..resource_id_int.."\"}")











