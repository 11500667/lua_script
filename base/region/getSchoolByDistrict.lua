#ngx.header.content_type = "text/plain;charset=utf-8"
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["district_id"] == nil or args["district_id"]=="" then
	ngx.say("{\"success\":\"false\",\"info\":\"参数district_id不能为空！\"}");
	return;
elseif not tonumber(args["district_id"]) then
	ngx.say("{\"success\":\"false\",\"info\":\"参数district_id只能为数字！\"}");
	return;
elseif args["stage_id"]==nil or args["stage_id"]=="" then
	ngx.say("{\"success\":\"false\",\"info\":\"参数stage_id不能为空！\"}");
	return;
elseif not tonumber(args["stage_id"]) then
	ngx.say("{\"success\":\"false\",\"info\":\"参数stage_id只能为数字！\"}");
	return;
end

local stageIdNum = tonumber(args["stage_id"]);
if not (stageIdNum == 0 or stageIdNum == 4 or stageIdNum == 5 or stageIdNum == 6) then
	ngx.say("{\"success\":\"false\",\"info\":\"参数stage_id不合法！\"}");
	return;
end

local districtId = args["district_id"];
-- 学校类型：0全部，4小学，5初中，6高中
local stageId = args["stage_id"];
local school_type = "";
if stageId == "4" then
	school_type = "1,5,6";
elseif stageId == "5" then
	school_type = "2,4,5,6";
elseif stageId == "6" then
	school_type = "3,4,6";
else
	school_type = "1,2,3,4,5,6";
end

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
    ngx.say("failed to connect: ", err, ": ", errno, " ", sqlstate);
	ngx.log(ngx.ERR, "=====> 连接数据库失败!");
    return;
end

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

local sel_count = "select count(1) as COUNT ";

local sel_org = "SELECT ORG_ID,ORG_NAME,SCHOOL_TYPE AS STAGE_ID";

local sel_condition = " FROM t_base_organization WHERE ORG_TYPE=2 AND EDU_TYPE=1 AND DISTRICT_ID="..districtId.." AND SCHOOL_TYPE IN ("..school_type..")";

local org_name = args["org_name"];

if org_name == nil or org_name =="" then 

else 
	sel_condition = sel_condition.." AND ORG_NAME like'%"..ngx.decode_base64(org_name).."%'";
end



ngx.log(ngx.ERR, "===>sql===> ".. sel_org..sel_condition.. "<===sql<===");

local responseObj = {};
local recordsCollect = {};
local pageNumber = args["pageNumber"]
local pageSize = args["pageSize"]
local page_sql =""
if pageSize==nil or pageSize == "" or pageNumber == nil or pageNumber =="" then

else
	local offset = pageSize*pageNumber-pageSize
	local limit = pageSize

	page_sql = " LIMIT "..offset..","..limit..";"
	
	local res_count = db:query(sel_count..sel_condition);
	local totalRow = res_count[1]["COUNT"]
	local totalPage = math.floor((totalRow+pageSize-1)/pageSize)
	responseObj["totalRow"] = tonumber(totalRow)
	responseObj["totalPage"] = tonumber(totalPage)
	responseObj["pageNumber"] = tonumber(pageNumber)
	responseObj["pageSize"] = tonumber(pageSize)
end

local results, err, errno, sqlstate = db:query(sel_org..sel_condition..page_sql);
if not results then
    ngx.say("{\"success\":\"false\",\"info\":\"查询过程出错！\"}");
	ngx.log(ngx.ERR, "err: ".. err);
    return
end

--[[if #results == 0 then
	ngx.say("{\"success\":\"true\",\"table_list\":[]}");
	ngx.log(ngx.ERR, "该区（县）下没有查询到区（县）");
    return
end]]

--2015-3-13 lzy新增返回该学校的管理员
for i=1, #results do
	local temp_schoolId = results[i]["ORG_ID"];
	local temp_schoolName = results[i]["ORG_NAME"];
	local temp_stageId = results[i]["STAGE_ID"];
	local temp_adminName =  ssdb_db:get("school_admin_"..temp_schoolId);
	--ngc
	local record = {};
	record.school_id = temp_schoolId;
	record.school_name = temp_schoolName;
	record.stage_id = temp_stageId;
	record.person_id = 
	ngx.log(ngx.ERR,"temp_adminName[1]=="..temp_adminName[1]);
	if temp_adminName[1] == "" then
	    record.admin_name = '--';
		record.person_id = -1;
	else
	   record.admin_name = cache:hget("person_"..temp_adminName[1].."_5","person_name");
	   record.person_id = temp_adminName[1];
	end
	
	
	table.insert(recordsCollect, record);
end

responseObj.success = true;
responseObj.table_list = recordsCollect;

-- 将table对象转换成json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(responseObj);

-- 输出json串到页面
ngx.say(responseJson);

-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size);


-- 将redis连接归还到连接池
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
    ngx.log(ngx.ERR, "====>将Redis连接归还连接池出错！");
end






