#ngx.header.content_type = "text/plain;charset=utf-8"
local request_method = ngx.var.request_method;
ngx.log(ngx.ERR, "===> 请求类型 ===> ", request_method);
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

--参数：ids
if args["ids"]==nil or args["ids"]=="" then
    ngx.say("{\"success\":\"false\",\"info\":\"ids参数错误！\"}");
    return
end
local ids = tostring(args["ids"]);

--[[ 
ids = args["ids"]
local id_list = Split(ids,",");
local id = "";
for i=1, #id_list do
     id = id_list[i]..","..id;
end
id = string.sub(id,0,#id-1)
]]

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
    max_packet_size = 1024 * 1024 }

if not ok then
    ngx.say("failed to connect: ", err, ": ", errno, " ", sqlstate)
    return
end
--2015-3-19增加返回字段SCHOOL_TYPE
local org_name = db:query("SELECT ORG_ID,ORG_NAME,SCHOOL_TYPE FROM T_BASE_ORGANIZATION WHERE B_USE=1 AND ORG_ID IN ("..ids..")");
local name_info = org_name

local result = {}
result["success"] = true
result["list"] = name_info

local cjson = require "cjson"
cjson.encode_empty_table_as_object(false);
ngx.say(cjson.encode(result))

-- 7.将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end