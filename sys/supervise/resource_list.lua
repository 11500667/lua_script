#ngx.header.content_type = "text/plain;charset=utf-8"
-- local cookie_person_id = tostring(ngx.var.cookie_person_id);
-- local cookie_identity_id = tostring(ngx.var.cookie_identity_id);

local function isNull(obj) 
	local nullFlag = false;
	if obj==nil or obj==ngx.null then
		nullFlag = true;
		return nullFlag;
	end
	
	if type(obj)=="string" and obj=="" then
		nullFlag = true;
		return nullFlag;
	end 
	
	return nullFlag;
end;

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--UFT_CODE
local function urlencode(str)
    if (str) then
        str = string.gsub (str, "\n", "\r\n")
        str = string.gsub (str, "([^%w ])",
        function (c) return string.format ("%%%%%02X", string.byte(c)) end)
        --str = string.gsub (str, " ", " ")
    end
    return str
end

local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["person_id"] == nil or args["person_id"]=="" then
	ngx.say("{\"success\":\"false\",\"info\":\"参数person_id不能为空！\"}");
	return;
elseif not tonumber(args["person_id"]) then
	ngx.say("{\"success\":\"false\",\"info\":\"参数person_id不合法！\"}");
	return;
elseif args["pageNumber"] == nil or args["pageNumber"]=="" then
	ngx.say("{\"success\":\"false\",\"info\":\"参数pageNumber不能为空！\"}");
	return;
elseif not tonumber(args["pageNumber"]) then
	ngx.say("{\"success\":\"false\",\"info\":\"参数pageNumber不合法！\"}");
	return;
elseif args["pageSize"] == nil or args["pageSize"]=="" then
	ngx.say("{\"success\":\"false\",\"info\":\"参数pageSize不能为空！\"}");
	return;
elseif not tonumber(args["pageSize"]) then
	ngx.say("{\"success\":\"false\",\"info\":\"参数pageSize不合法！\"}");
	return;
end

local personId = tostring(args["person_id"]);

--第几页
local pageNumber = tostring(args["pageNumber"]);
--判断是否有第几页的参数
if pageNumber == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"参数错误！\"}")    
    return
end
if pageNumber == "0" then
    pageNumber = "1"
end

--一页显示多少
local pageSize = tostring(args["pageSize"])
--判断是否有一页显示多少条的参数
if pageSize == "nil" then
    ngx.say("{\"success\":\"false\",\"info\":\"参数错误！\"}")    
    return
end

local offset = pageSize*pageNumber-pageSize
local limit = pageSize

-- 获取数据库连接
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
    ngx.say("failed to connect: ", err, ": ", errno, " ", sqlstate)
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

local sql = "SELECT ID FROM T_RESOURCE_INFO_SPHINXSE WHERE QUERY='filter=group_id,2;filter=person_id,"..personId.."filter=res_type,1;sort=attr_desc:ts;maxmatches=1000;offset=" .. offset .. ";limit=" .. limit .. "';SHOW ENGINE SPHINX STATUS;";

local results, err, errno, sqlstate = db:query(sql);
if not results then
    ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    return
end

--去第二个结果集中的Status中截取总个数
local res1 = db:read_result()
local _,s_str = string.find(res1[1]["Status"],"found: ")
local e_str = string.find(res1[1]["Status"],", time:")
local totalRow = string.sub(res1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

local personBUse  = {};

local responseObj = {};
local recordsCollect = {};

for i=1, #results do

	local resInfoId = results[i]["ID"];
	ngx.log(ngx.ERR, "===resInfoId==>" , resInfoId, "<====");
	local infoCache = ssdb_db:multi_hget("resource_"..resInfoId, "resource_id_int", "resource_title", "resource_type_name", "create_time", "person_id", "person_name", "structure_id", "resource_size", "for_iso_url", "for_urlencoder_url", "file_id", "resource_format", "preview_status", "resource_page", "url_code", "width", "height");
	
	if infoCache==ngx.null or #infoCache==0 then
		ngx.log(ngx.ERR, "===错误的id==>", resInfoId);
		
	else
	
		local resIdInt = infoCache[2];
		local resTitle = infoCache[4];	
		local resTypeName = infoCache[6];
		local createTime = infoCache[8];
		local personId = infoCache[10];
		local personName = infoCache[12];
		local structureId = infoCache[14];
		local resSize = infoCache[16];
		local isoUrl = infoCache[18];
		local encodeUrl = infoCache[20];
		local fileId = infoCache[22];
		local resFormat = infoCache[24];
		local previewStatus = infoCache[26];
		local resPage = infoCache[28];
		local width = infoCache[30];
		local height = infoCache[32];

		local bUse = 1;

		local curr_path = "";	
		local structures = cache:zrange("structure_code_"..structureId,0,-1);
		for i=1, #structures do
			-- ngx.log(ngx.ERR, structures[i]);
			local structure_info = cache:hget("t_resource_structure_"..structures[i], "structure_name");
			if structure_info==ngx.null then
				curr_path = "未知";
			else
				curr_path = curr_path .. structure_info .. "->";
			end
		end
		curr_path = string.sub(curr_path, 0, #curr_path-2);
		
		local record = {};
		record.resource_title = resTitle;
		record.info_id = resInfoId;
		record.resource_title = resTitle;
		record.file_title = resTitle;
		record.resource_type_name = resTypeName;
		record.create_time = createTime;
		record.person_id = personId;
		record.person_name = personName;
		record.structure_id = structureId;
		record.resource_size = resSize;
		record.for_iso_url = isoUrl;
		record.for_urlencoder_url = encodeUrl;
		record.file_id = fileId;
		record.file_ext = resFormat;
		record.preview_status = previewStatus;
		record.p_status = previewStatus;
		record.resource_page = resPage;
		record.file_page = resPage;
		record.resource_id_int = resIdInt;
		record.structure_path = curr_path;
		record.url_code = urlencode(resTitle);
		record.b_use = bUse;
		record.p_type = 1;
		record._width = width;
		record._height = height;
		
		table.insert(recordsCollect, record);
	end
end

responseObj.list = recordsCollect;
responseObj.totalRow = totalRow;
responseObj.totalPage = totalPage;
responseObj.pageNumber = pageNumber;
responseObj.pageSize = pageSize;
responseObj.success = true;

-- 将table对象转换成json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(responseObj);

-- 输出json串到页面
ngx.say(responseJson);

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

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size);






