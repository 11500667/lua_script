#ngx.header.content_type = "text/plain;charset=utf-8"
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["school_id"] == nil or args["school_id"]=="" then
	ngx.say("{\"success\":\"false\",\"info\":\"参数school_id不能为空！\"}");
	return;
elseif not tonumber(args["school_id"]) then
	ngx.say("{\"success\":\"false\",\"info\":\"参数school_id只能为数字！\"}");
	return;
end

local schoolId = tostring(args["school_id"]);


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

local sql = "SELECT T2.STAGE_ID, T2.STAGE_NAME FROM T_BASE_ORG_STAGE T1 " ..
				"INNER JOIN T_DM_STAGE T2 ON T1.STAGE_ID=T2.STAGE_ID WHERE ORG_ID='" .. schoolId .. "'";

local results, err, errno, sqlstate = db:query(sql);
if not results then
    ngx.say("{\"success\":\"false\",\"info\":\"查询过程出错！\"}");
	ngx.log(ngx.ERR, "err: ".. err);
    return
end

local responseObj = {};
local recordsCollect = {};

for i=1, #results do
	local stageId = results[i]["STAGE_ID"];
	local stageName= results[i]["STAGE_NAME"];
	
	local record = {};
	record.stage_id = stageId;
	record.stage_name = stageName;
	
	table.insert(recordsCollect, record);
end

responseObj.table_list = recordsCollect;
responseObj.success = true;

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







