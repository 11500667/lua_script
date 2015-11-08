#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2014-12-30
#描述：根据学生id获得对应的学生姓名,id以“，”分隔
]]
--1.获得参数方法
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

--2.获得参数
--获得人员id
if args["person_id"] == nil or args["person_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
    return
end
local person_id = args["person_id"]

--获得人员身份id
if args["identity_id"] == nil or args["identity_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"identity_id参数错误！\"}")
    return
end
local identity_id = args["identity_id"]
--3.连接数据库
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

--4.连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local school_id = cache:hget("person_"..person_id.."_"..identity_id,"xiao");
--ngx.say(school_id);

local sel_person = "SELECT person_id,person_name,avatar_url from t_base_person WHERE BUREAU_ID = "..school_id.." AND IDENTITY_ID = "..identity_id.." limit 50";

--local sel_person = "SELECT t1.PERSON_ID as person_id,t2.PERSON_NAME as person_name,login_name from t_base_person AS t1 INNER JOIN t_sys_loginperson AS t2 on t1.person_id = t2.person_id WHERE t1.BUREAU_ID = "..ngx.quote_sql_str(school_id).." AND t1.IDENTITY_ID = "..ngx.quote_sql_str(identity_id).." limit 50";
local results, err, errno, sqlstate = db:query(sel_person);
if not results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end

--调用空间接口取基本信息
local personIds = {}
for i=1,#results do
    table.insert(personIds, results[i].person_id)
end
local aService = require "space.services.PersonAndOrgBaseInfoService"
local rt = aService:getPersonBaseInfo(identity_id, unpack(personIds))
for i=1,#results do
    for _, v in ipairs(rt) do
        if tostring(results[i].person_id) == tostring(v.personId) then
            results[i].avatar_fileid = v and v.avatar_fileid or ""
            --teacherlist[i].description = v and v.person_description or ""
            break
        end
    end
end

--查询关注情况
local attentionService = require "space.attention.service.AttentionService"
local param = {}
param.personid = person_id
param.identityid = identity_id
param.page_size = 100000
param.page_num = 1
--ngx.log(ngx.ERR,cjson.encode(param))
local at = attentionService.queryAttention(param)
for i=1,#results do
    results[i].attention = 0
    for _, v in ipairs(at) do
        if tostring(results[i].person_id) == tostring(v.personId) then
            results[i].attention = 1
            break
        end
    end
end

local responseObj = {};
local recordsPerson = {};
--local recordsClass = {};

for i=1, #results do
	local temp_personId= results[i]["person_id"];
	local temp_personName = results[i]["person_name"];
	local temp_avatar_url = results[i]["avatar_url"];
    local temp_avatar_fileid = results[i]["avatar_fileid"];
    local temp_attention = results[i]["attention"];

	local record = {};
	record.id = temp_personId;
	record.name = temp_personName;
	record.userPhoto = temp_avatar_url;
    record.avatar_fileid = temp_avatar_fileid;
    record.attention = temp_attention;
	
	table.insert(recordsPerson, record);
end

responseObj.success = true;
responseObj.teacherlist = recordsPerson;
--[[
local sel_class = "SELECT t1.class_id as class_id,class_name FROM t_base_class AS t1 INNER JOIN t_base_class_subject AS t2 on t1.class_id = t2.class_id WHERE teacher_id = "..person_id;

local results_class, err, errno, sqlstate = db:query(sel_class);
if not results_class then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end

for i=1, #results_class do
	local temp_personId= results_class[i]["class_id"];
	local temp_personName = results_class[i]["class_name"];

	local record = {};
	record.id = temp_personId;
	record.name = temp_personName;
    record.userPhoto = "0";	
	table.insert(recordsClass, record);
end

responseObj.classlist = recordsClass;
]]
-- 5.将table对象转换成json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(responseObj);

-- 6.输出json串到页面
ngx.say(responseJson);


-- 将redis连接归还到连接池
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
    ngx.log(ngx.ERR, "====>将Redis连接归还连接池出错！");
end

-- 7.将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end









