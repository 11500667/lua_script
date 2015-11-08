#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#申健 2015-01-28
#描述：根据contentMD5获取试题记录。
]]

local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["person_id"] == nil or args["person_id"]=="" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数person_id不能为空！\"}");
	return;
elseif args["identity_id"] == nil or args["identity_id"]=="" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数identity_id不能为空！\"}");
	return;
elseif args["structure_id"] == nil or args["structure_id"]=="" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数structure_id不能为空！\"}");
	return;
elseif args["content_md5"] == nil or args["content_md5"]=="" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数content_md5不能为空！\"}");
	return;
end


local structureId = tostring(args["structure_id"]);
local contentMd5  = tostring(args["content_md5"]);

local personId 	  = tostring(args["person_id"]);
local identityId  = tostring(args["identity_id"]);

local cjson   = require "cjson";

-- 判断是否为东师理想的学科人员
local isDsidealPerson = false;
local captureResponse = ngx.location.capture("/dsideal_yy/ypt/question/isDsidealPerson", {
	method = ngx.HTTP_POST,
	body = "person_id="..personId.."&identity_id="..identityId
});
if captureResponse.status == ngx.HTTP_OK then
    resultJson = cjson.decode(captureResponse.body);
	ngx.log(ngx.ERR, "===> captureResponse.body ===> ", captureResponse.body);
	isDsidealPerson = resultJson.is_dsideal_person;
else
	ngx.print("{\"success\":false,\"info\":\"查询人员信息失败！\"}")
    return
end
ngx.log(ngx.ERR, "===> isDsidealPerson ===> ", isDsidealPerson);

-- 如果为东师理想的学科人员，则personId统一为1，因为东师理想的试题在上传时create_person为1
if isDsidealPerson then
	personId   = "1";
	identityId = "2";
end


-- 获取SSDB连接 begin
local ssdblib = require "resty.ssdb"
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.print("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
-- 获取SSDB连接 end


-- 获取mysql连接 begin
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
    ngx.print("{\"success\":\"false\",\"info\":\"查询数据失败！\"}")
	ngx.log(ngx.ERR, "=====> 连接数据库失败!");
    return
end
-- 获取mysql连接 end

local hashKey = personId.."_" .. identityId;
local exist, err = ssdb:hexists("md5_ques_" .. contentMd5, hashKey);
ngx.log(ngx.ERR, "=== exist ==>", type(exist[1]), ", value: ", cjson.encode(exist));

if exist[1] == "0" then 
	ngx.log(ngx.ERR, "ssdb中key为[md5_ques_" .. contentMd5.."], hash-key为 ["..hashKey.."] 的记录不存在！\"}");
	ngx.print("{\"success\":\"false\",\"info\":\"ssdb中key为[md5_ques_" .. contentMd5.."], hash-key为 ["..hashKey.."]的记录不存在！\"}")
	ngx.exit(ngx.HTTP_OK);
end

local quesIdCharTab, err = ssdb:hget("md5_ques_" .. contentMd5, hashKey);
ngx.log(ngx.ERR, "=== quesIdCharTab ==>", type(quesIdCharTab), ", ", cjson.encode(quesIdCharTab));
local quesIdChar = quesIdCharTab[1];

local sql = "SELECT ID, QUESTION_ID_CHAR, QUESTION_TITLE, QUESTION_TIPS, QUESTION_TYPE_ID, QUESTION_DIFFICULT_ID, CREATE_PERSON, GROUP_ID, DOWN_COUNT, TS, KG_ZG, SCHEME_ID_INT, STRUCTURE_ID_INT, JSON_QUESTION, JSON_ANSWER, UPDATE_TS, STRUCTURE_PATH, B_IN_PAPER, PAPER_ID_INT, B_DELETE, OPER_TYPE, CHECK_STATUS, CHECK_MSG, USE_COUNT, SORT_ID FROM t_tk_question_info WHERE QUESTION_ID_CHAR='".. quesIdChar .. "' AND OPER_TYPE=1 LIMIT 1";

local infoRecordObj = {}

local resultTab, err, errno, sqlstate = db:query(sql);
ngx.log(ngx.ERR, "=== resultTab ==>", type(resultTab), ", ", cjson.encode(resultTab));
if resultTab ~= nil and resultTab ~= ngx.null then
	infoRecordObj.ID                     = resultTab[1]["ID"];
	infoRecordObj.QUESTION_ID_CHAR       = resultTab[1]["QUESTION_ID_CHAR"];
	infoRecordObj.QUESTION_TITLE         = resultTab[1]["QUESTION_TITLE"];
	infoRecordObj.QUESTION_TIPS          = resultTab[1]["QUESTION_TIPS"];
	infoRecordObj.QUESTION_TYPE_ID       = resultTab[1]["QUESTION_TYPE_ID"];
	infoRecordObj.QUESTION_DIFFICULT_ID  = resultTab[1]["QUESTION_DIFFICULT_ID"];
	infoRecordObj.CREATE_PERSON          = resultTab[1]["CREATE_PERSON"];
	infoRecordObj.GROUP_ID               = resultTab[1]["GROUP_ID"];
	infoRecordObj.DOWN_COUNT             = resultTab[1]["DOWN_COUNT"];
	infoRecordObj.TS                     = resultTab[1]["TS"];
	infoRecordObj.KG_ZG                  = resultTab[1]["KG_ZG"];
	infoRecordObj.SCHEME_ID_INT          = resultTab[1]["SCHEME_ID_INT"];
	infoRecordObj.STRUCTURE_ID_INT       = resultTab[1]["STRUCTURE_ID_INT"];
	infoRecordObj.JSON_QUESTION          = resultTab[1]["JSON_QUESTION"];
	infoRecordObj.JSON_ANSWER            = resultTab[1]["JSON_ANSWER"];
	infoRecordObj.UPDATE_TS              = resultTab[1]["UPDATE_TS"];
	infoRecordObj.STRUCTURE_PATH         = resultTab[1]["STRUCTURE_PATH"];
	infoRecordObj.B_IN_PAPER             = resultTab[1]["B_IN_PAPER"];
	infoRecordObj.PAPER_ID_INT           = resultTab[1]["PAPER_ID_INT"];
	infoRecordObj.B_DELETE               = resultTab[1]["B_DELETE"];
	infoRecordObj.OPER_TYPE              = resultTab[1]["OPER_TYPE"];
	infoRecordObj.CHECK_STATUS           = resultTab[1]["CHECK_STATUS"];
	infoRecordObj.CHECK_MSG              = resultTab[1]["CHECK_MSG"];
	infoRecordObj.USE_COUNT              = resultTab[1]["USE_COUNT"];
	infoRecordObj.SORT_ID                = resultTab[1]["SORT_ID"];
end 

local resultJson = {};
resultJson.success     = true;
resultJson.record_info = infoRecordObj;

ngx.print(cjson.encode(resultJson));

-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

-- 将SSDB连接归还连接池
ssdb:set_keepalive(0,v_pool_size)

