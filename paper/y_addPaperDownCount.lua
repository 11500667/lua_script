#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#申健 2014-12-3
#描述：增加试卷的下载次数
]]

local function getTS() 
	local t=ngx.now();
	local n=os.date("%Y%m%d%H%M%S").."00"..string.sub(t,12,14);
	n=n..string.rep("0",19-string.len(n));
	return n;
end

local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["paper_id_char"] == nil or args["paper_id_char"]=="" then
	ngx.say("{\"success\":\"false\",\"info\":\"参数paper_id_char不能为空！\"}");
	return;
end

local paperIdChar = tostring(args["paper_id_char"]);

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
    ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}")
	ngx.log(ngx.ERR, "=====> 连接数据库失败!");
    return
end

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip, v_redis_port);
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end


local paperInfoCache = cache: hmget("paperinfo_" .. paperIdChar, "paper_id_int", "down_count");
local paperIdInt = tostring(paperInfoCache[1]);
local downCount = "1";
if paperInfoCache[2] ~= nil and paperInfoCache[2] ~= ngx.null and  tostring(paperInfoCache[2])~="userdata: NULL" then
	downCount = tostring(tonumber(paperInfoCache[2]) + 1);
end
-- 获取当前时间
local currentTS = getTS();


local sql = "SELECT ID FROM T_SJK_PAPER_INFO_SPHINXSE WHERE QUERY='filter=paper_id_int," .. paperIdInt .. ";maxmatches=1000;offset=0;limit=1000;';" .. 
			"SELECT ID FROM T_SJK_PAPER_MY_INFO WHERE PAPER_ID_INT=" .. paperIdInt .. ";";
ngx.log(ngx.ERR, "===sql===> " .. sql .. " <===sql===");

cache: hset("paperinfo_" .. paperIdChar, "down_count", downCount);
-- 更新数据库的sql语句
local updateSql = "START TRANSACTION;" .. 
				  "UPDATE T_SJK_PAPER_BASE SET UPDATE_TS=" .. currentTS .. ", DOWN_COUNT=" .. downCount .." WHERE PAPER_ID_INT='" .. paperIdInt .. "';";

-- 获取info表的ID				  			  
local results, err, errno, sqlstate = db:query(sql);
if not results then
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}");
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    return;
end

for i=1, #results do
	local infoId = results[i]["ID"];
	local setCountResult = cache: hset("paper_" .. infoId, "down_count", downCount);
	updateSql = updateSql .. "UPDATE T_SJK_PAPER_INFO SET UPDATE_TS=" .. currentTS .. ", DOWN_COUNT=" .. downCount .." WHERE ID='" .. infoId .. "';";
end

-- 获取my_info表的ID
if err == "again" then
    res, err, errno, sqlstate = db:read_result()
    if not res then
        ngx.log(ngx.ERR, "bad result #2: ", err, ": ", errno, ": ", sqlstate, ".")
        return ngx.exit(500)
    end
	for j=1, #res do
		local myInfoId = res[j]["ID"];
		local setCountResult = cache: hset("mypaper_" .. myInfoId, "down_count", downCount);
		updateSql = updateSql .. "UPDATE T_SJK_PAPER_MY_INFO SET UPDATE_TS=" .. currentTS .. ", DOWN_COUNT=" .. downCount .." WHERE ID='" .. myInfoId .. "';";
	end
end

local updateSql = updateSql .. "COMMIT;";
-- 执行update的sql语句				  
local res, err, errno, sqlstate = db:query(updateSql);
if not res then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".")
    return
end

while err == "again" do
    res, err, errno, sqlstate = db:read_result()
    if not res then
        ngx.log(ngx.ERR, "bad result #2: ", err, ": ", errno, ": ", sqlstate, ".")
        return ngx.exit(500)
    end
end


local responseObj = {};
responseObj.info = "增加下载次数成功";
responseObj.success = true;

-- 将table对象转换成json
local cjson = require "cjson";
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