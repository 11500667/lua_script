#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#申健 2014-12-24
#描述：获取带审核的对象
]]


--  获取request的参数
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["unit_id"] == nil or args["unit_id"]=="" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数unit_id不能为空！\"}");
	return;
elseif args["unit_code"] == nil or args["unit_code"]=="" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数unit_code不能为空！\"}");
	return;	
elseif args["check_id"] == nil or args["check_id"]=="" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数check_id不能为空！\"}");
	return;		
end

local unitId   = args["unit_id"];
local unitCode = args["unit_code"];
local checkId  = args["check_id"];

-- 3. 获取数据库连接
local function getDb()
	local mysql = require "resty.mysql";
	local db, err = mysql : new();
	if not db then 
		ngx.log(ngx.ERR, err);
		return;
	end

	db:set_timeout(1000) -- 1 sec

	local ok, err, errno, sqlstate = db:connect{
		host = v_mysql_ip,
		port = v_mysql_port,
		database = v_mysql_database,
		user = v_mysql_user,
		password = v_mysql_password,
		max_packet_size = 1024 * 1024 }

	if not ok then
		ngx.print("{\"success\":\"false\",\"info\":\"查询数据失败！\"}")
		ngx.log(ngx.ERR, "=====> 连接数据库失败!");
		return false;
	end
	
	return db;
end

--[[
	局部函数：获取redis连接
]]
local function getCache()
	-- 4.获取redis链接
	local redis = require "resty.redis"
	local cache = redis:new()
	local ok,err = cache:connect(v_redis_ip,v_redis_port)
	if not ok then
		ngx.print("{\"success\":\"false\",\"info\":\""..err.."\"}")
		return false;
	end
	
	return cache;
end

local db = getDb();
if not db then
	return;
end

local function encodeURI(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end

local cache = getCache();
if not cache then
	return;
end
local cjson = require "cjson";


--[[
	局部函数：获取审核对象所在的节点的路径
	参数：p_strucId 结构ID
]]
local function getStrucPath(p_strucId)
	-- 获取
	local p_structure_id = p_strucId;
	local p_structurePath = ""
	local p_structures = cache:zrange("structure_code_"..p_structure_id,0,-1)
	for i=1,#p_structures do
		local p_structure_info = cache:hmget("t_resource_structure_"..p_structures[i],"structure_name")
		p_structurePath = p_structurePath..p_structure_info[1].."->"
	end
	p_structurePath = string.sub(p_structurePath,0,#p_structurePath-2)
	
	return p_structurePath;
end

local sql = "SELECT T1.ID AS CHECK_ID, T1.OBJ_TYPE, T1.OBJ_ID_INT, T1.CHECK_STATUS, T1.CHECK_MODE, T1.CURRENT_TARGET, T2.ID AS INFO_ID, T2.RESOURCE_TITLE, T2.PREVIEW_STATUS, T2.FILE_ID, T2.RESOURCE_FORMAT, DATE_FORMAT(T2.CREATE_TIME, '%Y-%m-%d %H:%i:%S') AS CREATE_TIME, T2.SCHEME_ID_INT, T2.STRUCTURE_ID, T2.RESOURCE_PAGE, T2.THUMB_ID, T2.WIDTH, T2.HEIGHT, T2.FOR_URLENCODER_URL, T2.FOR_ISO_URL " ..
"FROM T_BASE_CHECK_INFO T1 INNER JOIN T_RESOURCE_INFO T2 ON T1.OBJ_ID_INT=T2.RESOURCE_ID_INT AND T2.GROUP_ID=2 WHERE T1.ID=" .. checkId .. " LIMIT 1";

local res, err, errno, sqlstate = db:query(sql);
if not res or #res==0 then
	ngx.print("{\"success\":\"false\", \"isObjExist\":false, \"info\":\"获取下一条带审核资源出错，该资源已经被删除！\"}")
	return;
end

local responseObj = {}

for i=1, #res do
	
	local record = {};
	-- 资源类型：1资源，2试题，3试卷，4备课，5微课
	local objType = res[1].OBJ_TYPE;
	
	if objType == 1 then -- 如果为资源
		record.CHECK_ID 	  = res[i].CHECK_ID;
		record.OBJ_ID_INT 	  = res[i].OBJ_ID_INT;
		record.OBJ_TYPE 	  = res[i].OBJ_TYPE;
		record.CHECK_STATUS   = res[i].CHECK_STATUS;
		record.CHECK_MODE 	  = res[i].CHECK_MODE;
		record.CURRENT_TARGET = res[i].CURRENT_TARGET;
		record.INFO_ID 		  = res[i].INFO_ID;
		record.RESOURCE_TITLE = res[i].RESOURCE_TITLE;
		record.PREVIEW_STATUS = res[i].PREVIEW_STATUS;
		record.FILE_ID 		  = res[i].FILE_ID;
		record.RESOURCE_FORMAT= res[i].RESOURCE_FORMAT;
		record.CREATE_TIME    = res[i].CREATE_TIME;
		record.SCHEME_ID_INT  = res[i].SCHEME_ID_INT;
		record.STRUCTURE_ID   = res[i].STRUCTURE_ID;
		record.STRUCTURE_PATH = getStrucPath(record.STRUCTURE_ID);
		record.RESOURCE_PAGE  = res[i].RESOURCE_PAGE;
		record.THUMB_ID  	  = res[i].THUMB_ID;
		record.WIDTH  	      = res[i].WIDTH;
		record.HEIGHT  	  	  = res[i].HEIGHT;
		record.FOR_URLENCODER_URL = res[i].FOR_URLENCODER_URL;
		record.FOR_ISO_URL    = res[i].FOR_ISO_URL;
		record.url_code       = encodeURI(res[i].RESOURCE_TITLE);
	end
	responseObj.success = true;
	responseObj.obj_info = record;
end



-- cjson.encode_empty_table_as_object(false);
local toJsonStr = cjson.encode(responseObj);

ngx.print(toJsonStr);


-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

