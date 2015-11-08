#ngx.header.content_type = "text/plain;charset=utf-8"
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["city_id"] == nil or args["city_id"]=="" then
	ngx.say("{\"success\":\"false\",\"info\":\"参数city_id不能为空！\"}");
	return;
elseif not tonumber(args["city_id"]) then
	ngx.say("{\"success\":\"false\",\"info\":\"参数city_id只能为数字！\"}");
	return;
end

local cityId = tostring(args["city_id"]);


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

local sql = "SELECT ID, DISTRICTNAME FROM T_GOV_DISTRICT WHERE CITYID=".. cityId .." ORDER BY ID ASC";

local results, err, errno, sqlstate = db:query(sql);
if not results then
    ngx.say("{\"success\":\"false\",\"info\":\"查询过程出错！\"}");
	ngx.log(ngx.ERR, "err: ".. err);
    return
end

--[[if #results == 0 then
	ngx.say("{\"success\":\"false\",\"info\":\"该市下没有区（县）！\"}");
	ngx.log(ngx.ERR, "该市下没有查询到区（县）");
    return
end]]

local responseObj = {};
local recordsCollect = {};

for i=1, #results do
	local districtId = results[i]["ID"];
	local districtName = results[i]["DISTRICTNAME"];
	
	
	local record = {};
	record.district_id = districtId;
	record.district_name = districtName;
	
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







