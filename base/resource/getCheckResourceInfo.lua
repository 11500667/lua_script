#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-03-31
#描述：
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

local cjson  = require "cjson";
--连接redis
local redis  = require "resty.redis"
local cache  = redis:new();
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--传参数
--resource_id 1652212
if args["resource_id"] == nil or args["resource_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"resource_id参数错误！\"}")
    return
end
local resource_id = args["resource_id"]
--type_id 1、带审核信息 2、不带审核信息
if args["type_id"] == nil or args["type_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"type_id参数错误！\"}")
    return
end
local type_id = args["type_id"]

--resource_type 1资源，2试题，3试卷，4备课，5微课',
if args["resource_type"] == nil or args["resource_type"] == "" then
    ngx.say("{\"success\":false,\"info\":\"resource_type参数错误！\"}")
    return
end
local resource_type = args["resource_type"]
local person_info = {} ;

local resource_info={};

local strucId = nil;

if resource_type == "1" or resource_type == "4" then 
    resource_info= ssdb_db:multi_hget("resource_"..resource_id,"person_id","create_time","resource_id_int");
elseif resource_type == "2" then
    
    local quesCache   = cache: hmget("question_" .. resource_id, "create_person", "json_question", "question_id_char");
    local jsonQues       = quesCache[2];
    local jsonQuesObjStr = ngx.decode_base64(jsonQues);
    local jsonQuesObj    = cjson.decode(jsonQuesObjStr);
    local createTime  = jsonQuesObj["create_time"];
    strucId = jsonQuesObj["structure_id"];
    person_info[1] = quesCache[1];
    person_info[2] = createTime;
    person_info[3] = quesCache[3];

elseif resource_type=="3" then
    person_info= cache:hmget("paper_"..resource_id,"person_id","create_time","paper_id_int");
elseif resource_type=="5" then
    person_info= cache:hmget("wkds_"..resource_id,"person_id","create_time","wkds_id_int");
end

local person_id       = person_info[1];
local create_time     = person_info[2];
local resource_id_int = person_info[3];
if resource_type == "1" or resource_type == "4" then 
     person_id = resource_info[2];
     create_time = resource_info[4];
     resource_id_int = resource_info[6];
end

--根据人员id获得上次人所在的组织机构。
local xiao_id         = cache:hmget("person_"..person_id.."_5","xiao","person_name")
local person_name     = xiao_id[2];
--连接数据库
local mysql           = require "resty.mysql"
local db              = mysql:new()
db:connect{
    host            = v_mysql_ip,
    port            = v_mysql_port,
    database        = v_mysql_database,
    user            = v_mysql_user,
    password        = v_mysql_password,
    max_packet_size = 1024*1024
}

--根据学校id获得对应的学校名称
local sel_org_name = "select org_name from t_base_organization  WHERE org_id = "..xiao_id[1];

local org_name_info, err, errno, sqlstate = db:query(sel_org_name);

if not org_name_info then
	 ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
   return
end

local org_name    = org_name_info[1]["org_name"];
--ngx.log(ngx.ERR,"org_name==="..org_name)
local responseObj = {};
responseObj.success     = true;
responseObj.person_name = person_name;
responseObj.create_time = create_time;
responseObj.org_name    = org_name;

--查询审核人
local sel_check_info = "";
if resource_type == "2" then
    sel_check_info = "SELECT T2.PERSON_ID, T2.IDENTITY_ID, T2.UNIT_ID, T2.UNIT_TYPE,CHECK_TIME,CHECK_STATUS  FROM T_BASE_CHECK_INFO T1 INNER JOIN T_BASE_CHECK_FLOW T2 ON T1.ID=T2.CHECK_ID AND T1.STRUCTURE_ID = " .. strucId .. " WHERE OBJ_ID_CHAR='"..resource_id_int.."' AND `OBJ_TYPE`="..resource_type.." ORDER BY UPDATE_TS DESC";
else
    sel_check_info = "SELECT T2.PERSON_ID, T2.IDENTITY_ID, T2.UNIT_ID, T2.UNIT_TYPE,CHECK_TIME,CHECK_STATUS  FROM T_BASE_CHECK_INFO T1 INNER JOIN T_BASE_CHECK_FLOW T2 ON T1.ID=T2.CHECK_ID WHERE OBJ_ID_INT="..resource_id_int.." AND `OBJ_TYPE`="..resource_type.." ORDER BY UPDATE_TS DESC";
end
ngx.log(ngx.ERR,"******"..sel_check_info)
local check_info, err, errno, sqlstate = db:query(sel_check_info);
if not check_info then
	 ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
   return
end
local check_info_obj ={};

for i=1,#check_info do
    
	local tab = {};
	--根据人员id获得人员名称
    local check_person_id   = check_info[i]["PERSON_ID"];
    local check_identity_id = check_info[i]["IDENTITY_ID"];
    local check_unit_id     = check_info[i]["UNIT_ID"];
    local check_time        = check_info[i]["CHECK_TIME"];
    local check_person_name = cache:hget("person_"..check_person_id.."_"..check_identity_id,"person_name")
	tab.check_person_name    = check_person_name;
	local sel_check_org_name = "select org_name from t_base_organization  WHERE org_id = "..check_unit_id;
	local check_org_name_info, err, errno, sqlstate = db:query(sel_check_org_name);

    if not check_org_name_info then
	    ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
        return
    end
    tab.check_org_name = check_org_name_info[1]["org_name"];
    tab.check_time     = check_time;
	local check_status = check_info[i]["CHECK_STATUS"];
	if check_status =="11" then
        tab.check_status = "通过";
	elseif  check_status == "12" then
        tab.check_status = "未通过";
	end
	check_info_obj[i] = tab;
end
responseObj.list = check_info_obj;
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

-- 将redis连接归还到连接池
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
    ngx.log(ngx.ERR, "====>将Redis连接归还连接池出错！");
end

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size);










