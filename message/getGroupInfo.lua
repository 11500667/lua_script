#ngx.header.content_type = "text/plain;charset=utf-8"
local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)
--判断是否有person_id的cookie信息
if cookie_person_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"Cookie的人员信息未获取到！\"}")
    return
end
--判断是否有identity_id的cookie信息
if cookie_identity_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"Cookie的人员身份信息未获取到！\"}")
    return
end

-- 获取参数
local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end
--参数：群组id
if not tonumber(args["group_id"]) then
	ngx.say("{\"success\":false,\"info\":\"参数group_id只能为数字！\"}")
	return
end

local p_groupId = tonumber(args["group_id"])
ngx.log(ngx.ERR, "pram--->group_id--->value: " .. p_groupId);
--判断参数group_id是否有效
if p_groupId == "nil" then
    ngx.say("{\"success\":false,\"info\":\"参数group_id不能为空！\"}")
    return
end


local resultJson = {}

--连接数据库
local redis = require "resty.redis"
local cjson = require "cjson"
local red = redis:new()

red:set_timeout(1000) -- 1 sec

local redis_ok, redis_err = red:connect(v_redis_ip, v_redis_port)
if not redis_ok then
    ngx.log(ngx.ERR, "failed to connect: ", redis_err)
    ngx.say("{\"success\":false,\"info\":\"连接缓存服务器出错！\"}")
    return
end

-- 判断p_groupId对应的群组是否存在
local isGroupExist = red: exists("groupinfo_" .. p_groupId)

if isGroupExist==ngx.null or isGroupExist==0 then
	ngx.say("{\"success\":false,\"info\":\"不存在编号为" .. p_groupId .. "的群组！\"}")
	return
end 


local redisResult = red: hmget("groupinfo_" .. p_groupId, "org_id", "org_name", "avatar_url");

if not redisResult then
	ngx.log(ngx.ERR, "无法从缓存中获取数据，缓存的key--> groupinfo_" .. p_groupId);
	ngx.say("{\"success\":false,\"info\":\"获取群组信息出错！\"}");
	return;
end

local groupInfoJson = {};

groupInfoJson["groupID"]   = tonumber(redisResult[1]);
groupInfoJson["groupName"] = redisResult[2];
if redisResult[3] ~= ngx.null then
	groupInfoJson["groupICON"] = redisResult[3];
else
	groupInfoJson["groupICON"] = "images/head_icon/group/default.png";
end


local memberList = {};

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
    ngx.log(ngx.ERR, "failed to connect: ", err, ": ", errno, " ", sqlstate)
    ngx.say("{\"success\":false,\"info\":\"连接数据库服务器出错！\"}")
    return
end
-- ngx.say("connected to mysql.")

local subSql = "filter=group_id," .. p_groupId .. ";filter=state_id,1;"
local memberIds, err, errno, sqlstate = db:query("SELECT SQL_NO_CACHE ID FROM t_base_group_member_sphinxse WHERE QUERY='" .. subSql .. "sort=attr_desc:ts;'");

if not memberIds then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".")
    ngx.say("{\"success\":false,\"info\":\"获取成员信息出错！\"}")
    return
end

for i=1, #memberIds do
	local memberId = memberIds[i]["ID"];
	local memberInfo = red:hmget("member_" .. memberId, "person_id", "identity_id");
	if memberinfo==ngx.null or memberInfo[1]==ngx.null or memberInfo[2]==ngx.null then
		ngx.log(ngx.ERR, "获取member_[memberId]缓存为空！");
	end

	if memberInfo[1] ~= ngx.null and memberInfo[2] ~= ngx.null then
		local personId = memberInfo[1];
		local identityId = memberInfo[2];

		local personInfo = red:hmget("person_" .. personId .. "_" .. identityId, "person_name", "avatar_url");
		
		local personJsonObj = {};
		
		if personId~=ngx.null then
			personJsonObj["person_id"] = tonumber(personId);
		else
			personJsonObj["person_id"] = "";
		end
		
		if identityId~=ngx.null then
			personJsonObj["identity_id"] = tonumber(identityId);
		else
			personJsonObj["identity_id"] = "";
		end

		if personInfo[1] ~= ngx.null then
			personJsonObj["person_name"] = personInfo[1];
		else
			personJsonObj["person_name"] = "";
		end
		
		if personInfo[2] ~= ngx.null then
			personJsonObj["avatar_url"] = personInfo[2];
		else
			personJsonObj["avatar_url"] = "";
		end

		personJsonObj["person_type"] = 4;
		personJsonObj["update"] = "";
		table.insert(memberList, personJsonObj);

		local memberType = red:hget("member_"..p_groupId.."_"..personId.."_"..identityId, "member_type");
		-- ngx.say("\n memberType[1]--->" .. memberType);
		-- ngx.say("\n memberInfo[3] == 0--->" .. (memberInfo[3] == "0"));
		if memberType ~= ngx.null and memberType == "0" then 
			groupInfoJson["createrID"] = tonumber(personId);
		end
	end
end

groupInfoJson["groupUser"] = memberList;

resultJson["success"] = true;
resultJson["groupInfo"] = groupInfoJson;

local jsonData = cjson.encode(resultJson)

ngx.say(jsonData);

-- 将redis连接归还连接池
local ok, err = red:set_keepalive(0, v_pool_size);
if not ok then
    ngx.say("failed to set keepalive: ", err)
    return
end

-- 将mysql连接归还到连接池
local ok, err = db:set_keepalive(0, v_pool_size);
if not ok then
    ngx.say("failed to set keepalive: ", err)
    return
end
