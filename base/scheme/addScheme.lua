#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-05-22
#描述：添加版本
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
if args["subject_id"] == nil or args["subject_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"subject_id参数错误！\"}")
    return
end
local subject_id  = tostring(args["subject_id"]);

if args["stage_id"] == nil or args["stage_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"stage_id参数错误！\"}")
    return
end
local stage_id  = tostring(args["stage_id"]);

if args["scheme_name"] == nil or args["scheme_name"] == "" then
    ngx.say("{\"success\":false,\"info\":\"scheme_name参数错误！\"}")
    return
end
local scheme_name  = tostring(args["scheme_name"]);


if args["type_id"] == nil or args["type_id"] == ""  then
    ngx.say("{\"success\":false,\"info\":\"type_id参数错误！\"}")
    return
end
local type_id  = tostring(args["type_id"]);

local uuid =  require "resty.uuid";
local scheme_id_char = uuid.new();
local myts = require "resty.TS";
local ts =  myts.getTs();
local create_time = ngx.localtime();

local in_scheme = "INSERT INTO t_resource_scheme(SCHEME_ID_CHAR,SCHEME_NAME,STAGE_ID,SUBJECT_ID,B_USE,TS,CLIENT_ID,TYPE_ID,SCHEME_TYPE,SYSTEM_ID) values ('"..scheme_id_char.."','"..scheme_name.."',"..stage_id..","..subject_id..",1,"..ts..",1,"..type_id..",1,1)";
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);

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
--向版本表中插入数据
local result_scheme, err, errno, sqlstate = db:query(in_scheme)
	if not result_scheme then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	  ngx.say("{\"success\":false,\"info\":\"新增版本失败！\"}")
	 return
    end
	
local new_scheme_id = result_scheme.insert_id;
local new_structure_id = cache:incr("t_resource_structure_pk");
local structure_id_char = uuid.new();
--向结构表中插入数据
local in_structure = "INSERT INTO t_resource_structure(structure_id,structure_id_char,structure_code,scheme_id_char,scheme_id_int,level,structure_name,sort_id,b_use,is_root,create_time,ts,parent_id,show_type,type_id,is_leaf,is_delete) values ("..new_structure_id..",'"..structure_id_char.."',"..new_structure_id..",'"..scheme_id_char.."',"..new_scheme_id..",1,'"..scheme_name.."',1,1,1,'"..create_time.."',"..ts..",-1,1,"..type_id..",0,0)";

--向结构表中插入数据
local result_structure, err, errno, sqlstate = db:query(in_structure)
	if not result_structure then
	 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	  ngx.say("{\"success\":false,\"info\":\"新增版本失败！\"}")
	 return
    end

--添加缓存scheme_structure_
local scheme_json="[{\"id\":\""..new_structure_id.."\"," ..
					" \"pId\":\"-1\"," ..
					" \"name\":\""..scheme_name.."\"," ..
					"\"structure_code\":\""..new_structure_id.."\",\"isParent\":\"false\"}]";
					
cache:set("scheme_structure_"..new_scheme_id,scheme_json);
cache:set("node_"..new_structure_id,new_structure_id);
local structure_tab = {};
structure_tab.id = new_structure_id;
structure_tab.pId = -1;
structure_tab.name = scheme_name;
structure_tab.structure_code = new_structure_id;
structure_tab.open = true;
local structure_json = cjson.encode(structure_tab);
cache:set("structure_"..new_scheme_id,structure_json);

local structure_map = {};
structure_map.structure_id = new_structure_id;
structure_map.structure_id_char = structure_id_char;
structure_map.structure_code = new_structure_id;
structure_map.scheme_id_char = scheme_id_char;
structure_map.scheme_id_int = new_scheme_id;
structure_map.structure_name = scheme_name;
structure_map.b_use = 1;
structure_map.is_rrot = 1;
structure_map.create_time = create_time;
structure_map.ts = ts;
structure_map.parent_id = -1;
structure_map.type_id = type_id;
structure_map.level = 1;

cache:hmset("t_resource_structure_"..new_structure_id,structure_map);

local resultJson={};
resultJson.success = true;
resultJson.info = "新增版本成功！";
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
