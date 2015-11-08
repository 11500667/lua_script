#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#lzy 2015-09-06
#描述：设置微课的删除状态
]]
local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local person_id = tostring(args["person_id"])
if person_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
    return
end

local identity_id = tostring(args["identity_id"])
if identity_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"identity_id参数错误！\"}")
    return
end

local wkds_id_int = tostring(args["wkds_id_int"])
if wkds_id_int == "nil" then
    ngx.say("{\"success\":false,\"info\":\"wkds_id_int参数错误！\"}")
    return
end

local b_delete;
local type_id;
local b_delete_check;

local delete_status = tostring(args["delete_status"])
if delete_status == "nil" then
    ngx.say("{\"success\":false,\"info\":\"delete_status参数错误！\"}")
    return
end

if delete_status == "2" then
    b_delete = 2;
	type_id = 10;
	b_delete_check = "0";
elseif delete_status == "0" then
    b_delete = 0;
	type_id = 6;
	b_delete_check = "2";
elseif delete_status == "1" then
    b_delete = 1;
	type_id = 6;
	b_delete_check = "2";
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

--去缓存中取sheng,shi,qu,xiao
local person_map = cache:hmget("person_"..person_id.."_"..identity_id,"sheng","shi","qu","xiao");

local provinceId = person_map[1];
local cityId 	 = person_map[2];
local districtId = person_map[3];
local schoolId   = person_map[4];

local sql = "SELECT SQL_NO_CACHE ID FROM T_WKDS_INFO_SPHINXSE WHERE QUERY='filter=wkds_id_int,"..wkds_id_int..";filter=b_delete,"..b_delete_check..";"..
						"select=(IF(group_id=" ..provinceId..",0,1) AND IF(group_id="..cityId..",0,1) "..
						"AND IF(group_id="..districtId..",0,1) AND IF(group_id="..schoolId..",0,1)) as c_condition;filter=c_condition,1';";
local infoIdList = db:query(sql);
local myts = require "resty.TS";

for i=1,#infoIdList do
    local update_ts =  myts.getTs();
	local sql_up = "UPDATE T_WKDS_INFO SET B_DELETE="..b_delete..",TYPE_ID = "..type_id..", UPDATE_TS="..update_ts.." WHERE ID="..infoIdList[i]["ID"].." AND ISDRAFT=0 AND B_DELETE="..b_delete_check;
	db:query(sql_up);
	local wkds_info = {};
	wkds_info.b_delete = b_delete;
	wkds_info.type_id = type_id;
	--修改缓存
    cache:hmset("wkds_"..infoIdList[i]["ID"],wkds_info)
end
						
local sql_wkds = "";
--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池

db:set_keepalive(0,v_pool_size)
local responseObj = {};
responseObj.success = true;
responseObj.info = "还原成功";

-- 8.将table对象转换成json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(responseObj);

ngx.say(responseJson)


