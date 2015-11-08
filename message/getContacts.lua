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

local mysql = require "resty.mysql";
local redis = require "resty.redis"
local cjson = require "cjson"
local red = redis:new()

red:set_timeout(1000) -- 1 sec

local redis_ok, redis_err = red:connect(v_redis_ip, v_redis_port)
if not redis_ok then
    ngx.say("failed to connect: ", redis_err)
    return
end

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


local resultJson = {};

local contactList = {};
-----------------------系统--------------------
local systemContact = {};
systemContact["person_id"] = 1;
systemContact["identity_id"] = "";
systemContact["person_type"] = 1; -- 1系统会话，3群组，4个人
systemContact["person_name"] = "系统";
systemContact["avatar_url"]  = "images/head_icon/sys/speaker.png";
systemContact["update"] = "";

table.insert(contactList, systemContact);

----------------------群组----------------------------
local defaultGroupAvatar = "images/head_icon/group/default.png";
--[[
local groupsFromRedis = red:smembers("group_"..cookie_person_id.."_"..cookie_identity_id.."_real");

if groupsFromRedis~=ngx.null then
	for i=1, #groupsFromRedis do
		local groupId = groupsFromRedis[i];
		local groupRecord = red:hmget("groupinfo_" .. groupId, "org_name", "avatar_url");

		local groupContact = {};
		
		if groupRecord[1] == ngx.null then
			ngx.log(ngx.ERR, "message/getContacts--->错误信息：编号为" .. groupId .. "的群组在缓存中的名称不存在！");
			groupContact.person_name = "";
		else
			groupContact.person_name = groupRecord[1];
		end

		if groupRecord[2] == ngx.null then
			ngx.log(ngx.ERR, "message/getContacts--->错误信息：编号为" .. groupId .. "的群组在缓存中的头像路径不存在！");
			groupContact.avatar_url = defaultGroupAvatar;
		else
			groupContact.avatar_url = groupRecord[2];
		end

		groupContact.person_id = tonumber(groupId);
		groupContact.identity_id = "";
		groupContact.person_type = 3;	-- 1系统会话，3群组，4个人	
		groupContact.update = "";

		table.insert(contactList, groupContact);
	end
end
-- 如果是学生的话，则获取学生所在的班级
if cookie_identity_id == '6' then
	local sql = "SELECT T1.STUDENT_ID, T1.CLASS_ID, T2.GROUPID, T3.CLASS_NAME FROM T_BASE_STUDENT T1 INNER JOIN T_HUANXIN_GROUP T2 ON T1.CLASS_ID=T2.CLASSID INNER JOIN T_BASE_CLASS T3 ON T1.CLASS_ID=T3.CLASS_ID WHERE STUDENT_ID=" .. cookie_person_id;
	
	local res, err, errno, sqlstate = db:query(sql);
	if res ~= nil and res ~= ngx.null then
		for j=1, #res do
			
			local groupContact = {};
			groupContact.person_id 	 = res[j]["GROUPID"];
			groupContact.person_name = res[j]["CLASS_NAME"];
			groupContact.avatar_url  = defaultGroupAvatar;
			groupContact.identity_id = "";
			groupContact.person_type = 3;	-- 1系统会话，3群组，4个人	
			groupContact.update      = "";

			table.insert(contactList, groupContact);
		end
	end
	
end
]]

local temp_groupContact = {};
temp_groupContact.person_id   = "123456";
temp_groupContact.person_name = "环信测试小组";
temp_groupContact.avatar_url  = defaultGroupAvatar;
temp_groupContact.identity_id = "";
temp_groupContact.person_type = 3;	-- 1系统会话，3群组，4个人	
temp_groupContact.update      = "";
temp_groupContact.clientID    = "1420354192824563";

table.insert(contactList, temp_groupContact);

local temp_groupContact = {};
temp_groupContact.person_id   = "1234567";
temp_groupContact.person_name = "一年级一班";
temp_groupContact.avatar_url  = defaultGroupAvatar;
temp_groupContact.identity_id = "";
temp_groupContact.person_type = 3;	-- 1系统会话，3群组，4个人	
temp_groupContact.update      = "";
temp_groupContact.clientID    = "1420354368672790";

table.insert(contactList, temp_groupContact);
-----------------个人------------------------------
local defaultPersonAvatar = "images/head_icon/person/default.png";
local orgId = red:hget("person_" .. cookie_person_id .. "_" .. cookie_identity_id, "bm");
if orgId == ngx.null then
	ngx.say("{\"success\":false,\"info\":\"从人员缓存中获取部门信息出错！\"}");
	return;
end

local sql = "SELECT T1.PERSON_ID, T1.IDENTITY_ID, T1.PERSON_NAME, T1.AVATAR_URL, T2.LOGIN_NAME FROM T_BASE_PERSON T1 INNER JOIN T_SYS_LOGINPERSON T2 ON T1.PERSON_ID=T2.PERSON_ID AND T1.IDENTITY_ID=T2.IDENTITY_ID WHERE T1.ORG_ID=" .. orgId .. " AND T1.PERSON_ID <> " .. cookie_person_id;

local personInOrg, err, errno, sqlstate = db:query(sql);
if not personInOrg then
    ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    return
end

for i=1, #personInOrg do
	if personInOrg[i] ~= ngx.null then
		local personId    = personInOrg[i]["PERSON_ID"];
		local identityId  = personInOrg[i]["IDENTITY_ID"];
		local person_name = personInOrg[i]["PERSON_NAME"];
		local login_name  = personInOrg[i]["LOGIN_NAME"];
		if personInOrg[i]["AVATAR_URL"] == ngx.null then
			ngx.log(ngx.ERR, "message/getContacts--->错误信息：编号为" .. personId .. "的人员在数据库中的头像路径不存在！");
			personInOrg[i]["AVATAR_URL"] = defaultPersonAvatar;
		end

		local personJsonObj = {};
		personJsonObj["person_id"]   = personId;
		personJsonObj["identity_id"] = identityId;
		personJsonObj["person_name"] = person_name;
		personJsonObj["clientID"]  = login_name;
		personJsonObj["person_type"] = 4; -- 1系统会话，3群组，4个人
		personJsonObj["avatar_url"]  = personInOrg[i]["AVATAR_URL"];
		personJsonObj["update"] = "";

		table.insert(contactList, personJsonObj);
	end
end

resultJson["success"] = true;
resultJson["contacts"] = contactList;

local resultJsonStr = cjson.encode(resultJson);

ngx.say(resultJsonStr);

-- 将redis连接归还连接池
local ok, err = red:set_keepalive(0, v_pool_size);
if not ok then
    ngx.log(ngx.ERR, "failed to set keepalive: ", err)
end

-- 将mysql连接归还到连接池
local ok, err = db:set_keepalive(0, v_pool_size);
if not ok then
    ngx.log(ngx.ERR, "failed to set keepalive: ", err)
end