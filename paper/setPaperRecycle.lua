#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#lzy 2015-09-06
#描述：设置试卷的删除状态
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
if person_id == "nil"  or person_id == "" then
    ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
    return
end

local identity_id = tostring(args["identity_id"])
if identity_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"identity_id参数错误！\"}")
    return
end

local paper_id_int = tostring(args["paper_id_int"])
if paper_id_int == "nil" then
    ngx.say("{\"success\":false,\"info\":\"paper_id_int参数错误！\"}")
    return
end

local delete_status = tostring(args["delete_status"])
if delete_status == "nil" then
    ngx.say("{\"success\":false,\"info\":\"delete_status参数错误！\"}")
    return
end

local b_delete;
local type_id;
local b_delete_check;

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
local myts = require "resty.TS";
--去缓存中取sheng,shi,qu,xiao
local person_map = cache:hmget("person_"..person_id.."_"..identity_id,"sheng","shi","qu","xiao");

local provinceId = person_map[1];
local cityId 	 = person_map[2];
local districtId = person_map[3];
local schoolId   = person_map[4];

--local  sql = "SELECT SQL_NO_CACHE ID FROM t_sjk_paper_info_sphinxse WHERE QUERY='filter=paper_id_int,"..paper_id_int..";filter=b_delete,"..b_delete_check..";"..
		--		"select=(IF(group_id="..provinceId..",0,1) AND IF(group_id="..cityId..",0,1) "..
		--		"AND IF(group_id="..districtId..",0,1) AND IF(group_id="..schoolId..",0,1)) as c_condition;filter=c_condition,1';";
				
local sql = "SELECT SQL_NO_CACHE ID FROM t_sjk_paper_info_sphinxse WHERE QUERY='filter=group_id,2;filter=paper_id_int,"..paper_id_int..";filter=b_delete,"..b_delete_check..";'";

local infoIdList = db:query(sql);

for i=1,#infoIdList do
    local update_ts =  myts.getTs();
	local sql_up = "UPDATE t_sjk_paper_info SET B_DELETE="..b_delete..", UPDATE_TS="..update_ts.." WHERE ID="..infoIdList[i]["ID"];
	db:query(sql_up);
	local paper_info = {};
	paper_info.b_delete = b_delete;
	paper_info.type_id = type_id;
	--修改缓存
    cache:hmset("paper_"..infoIdList[i]["ID"],paper_info)
end	
					
local sql_myinfo = "SELECT SQL_NO_CACHE ID FROM t_sjk_paper_my_info_sphinxse WHERE "..
				"QUERY='filter=group_id,2;filter=paper_id_int,"..paper_id_int..";filter=b_delete,"..b_delete_check.."';";
	
local myinfoIdList = db:query(sql_myinfo);

for i=1,#myinfoIdList do
    local update_ts =  myts.getTs();
	local sql_up = "UPDATE t_sjk_paper_my_info SET B_DELETE="..b_delete..",TYPE_ID = "..type_id..", UPDATE_TS="..update_ts.." WHERE ID="..myinfoIdList[i]["ID"];
	db:query(sql_up);
	local paper_info = {};
	paper_info.b_delete = b_delete;
	paper_info.type_id = type_id;
	--修改缓存
    cache:hmset("mypaper_"..myinfoIdList[i]["ID"],paper_info)
end

-- 申健 2015年10月22日添加，删除试卷后，向异步队列中写入消息 begin
local paramObj  = {};
paramObj["paper_id_int"] = paper_id_int;
local asyncQueueService = require "common.AsyncDataQueue.AsyncQueueService";
local asyncCmdStr       = asyncQueueService: getAsyncCmd("002003", paramObj)
ngx.log(ngx.ERR, "[sj_log] -> [supervise] -> asyncCmdStr: [", asyncCmdStr, "]");
asyncQueueService: sendAsyncCmd(asyncCmdStr);
-- 申健 2015年10月22日添加，删除试卷后，向异步队列中写入消息 begin

--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池

db:set_keepalive(0,v_pool_size)
local responseObj = {};
responseObj.success = true;
responseObj.info = "操作成功";
-- 8.将table对象转换成json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(responseObj);

ngx.say(responseJson)


