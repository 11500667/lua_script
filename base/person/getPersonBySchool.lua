local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["school_id"] == nil or args["school_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"school_id参数错误\"}")
    return
end
if args["pageNum"] == nil or args["pageNum"] == "" then
    ngx.say("{\"success\":false,\"info\":\"pageNum参数错误\"}")
    return
end
if args["pageSize"] == nil or args["pageSize"] == "" then
    ngx.say("{\"success\":false,\"info\":\"pageSize参数错误\"}")
    return
end

local school_id = args["school_id"]
local pageNumber = args["pageNum"]
local pageSize = args["pageSize"]
local org_id = args["org_id"]

local org_str = "";
if org_id ~= "-1" then
	org_str = " AND T1.ORG_ID = " .. org_id
end

--连接数据库
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
    max_packet_size = 1024 * 1024 
}

local queryCount = "SELECT count(1) as count FROM t_base_person T1  WHERE T1.BUREAU_ID = "..school_id.." AND T1.IDENTITY_ID = 5"..org_str;
local per_count = db:query(queryCount);
ngx.log(ngx.ERR,"================"..per_count[1]["count"])

local offset = pageSize*pageNumber-pageSize
local limit = pageSize
local str_maxmatches = pageNumber*pageSize

local sql_limit = " limit "..offset..","..limit;

local totalRow = per_count[1]["count"];
 
local totalPage = math.floor((totalRow+pageSize-1)/pageSize);

--查询
local queryList = "SELECT person_id,person_name,T1.BUREAU_ID AS school_id,T2.ORG_NAME AS school_name,t1.org_id as org_id,(SELECT ORG_NAME FROM t_base_organization WHERE ORG_ID = t1.ORG_ID) AS org_name,T1.stage_id,T1.stage_name,T1.subject_id,T1.subject_name FROM t_base_person T1 INNER JOIN t_base_organization T2 ON T1.BUREAU_ID = T2.ORG_ID WHERE T1.BUREAU_ID = "..school_id.." AND T1.IDENTITY_ID = 5 "..org_str..sql_limit;
local results, err, errno, sqlstate = db:query(queryList);
if not results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end

local person_list = results;
local returnJson = {};
returnJson["totalPage"] = totalPage;
returnJson["totalRow"] = totalRow;
returnJson["pageNumber"] = pageNumber;
returnJson["pageSize"] = pageSize;
returnJson["success"] = true;
returnJson["list"] = person_list;

local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(returnJson);

ngx.say(responseJson);

ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

