#增加教育单位维护 by huyue 2015-06-29
--1.获得参数方法

local args = getParams();
local _DBUtil = require "common.DBUtil";
--引用模块
local cjson = require "cjson"
cjson.encode_empty_table_as_object(false);

local _SSDBUtil = require "common.SSDBUtil"

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--从SSDB中获取组织ID
local org_id = _SSDBUtil: incr("t_base_group_new_pk");

if args["area_id"] == nil or args["area_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"area_id参数错误！\"}")
	ngx.log(ngx.ERR, "ERR MSG =====> 参数area_id不能为空！");
    return
end
local area_id = args["area_id"];

--省
if args["pId1"] == nil or args["pId1"] == "" then
    ngx.say("{\"success\":false,\"info\":\"pId1参数错误！\"}")
	ngx.log(ngx.ERR, "ERR MSG =====> 参数pId1不能为空！");
    return
end
local pId1 = tonumber(args["pId1"]);

--市
if args["pId2"] == nil or args["pId2"] == "" then
    ngx.say("{\"success\":false,\"info\":\"pId2参数错误！\"}")
	ngx.log(ngx.ERR, "ERR MSG =====> 参数pId2不能为空！");
    return
end
local pId2 = tonumber(args["pId2"]);

--区
if args["pId3"] == nil or args["pId3"] == "" then
    ngx.say("{\"success\":false,\"info\":\"pId3参数错误！\"}")
	ngx.log(ngx.ERR, "ERR MSG =====> 参数pId3不能为空！");
    return
end
local pId3 = tonumber(args["pId3"]);

local district_id;
local city_id;
local province_id;
if pId1 == 0 then
--省
	district_id = 0;
	city_id = 0;
	province_id = pId1;
elseif pId2 == 0 then 
--市
	district_id = 0;
	city_id = pId2;
	province_id = pId1;

else
	district_id = pId3;
	city_id = pId2;
	province_id = pId1;
end

ngx.log(ngx.ERR,"省ID："..province_id..",市ID："..city_id..",区ID："..district_id);

--单位名称
if args["unit_name"] == nil or args["unit_name"] == "" then
    ngx.say("{\"success\":false,\"info\":\"单位名称不能为空！\"}")
	ngx.log(ngx.ERR, "ERR MSG =====> 参数unit_name不能为空！");
    return
end
local unit_name  = args["unit_name"];

local check_sql = "select count(1) as COUNT from t_base_organization where org_name = '"..unit_name.."' and district_id ="..district_id.." and city_id ="..city_id.." and province_id ="..province_id;
ngx.log(ngx.ERR,check_sql);

local check_res=_DBUtil:querySingleSql(check_sql);
--ngx.log(ngx.ERR,"----------------------------"..check_res[1]["COUNT"]);

if check_res and check_res[1] then 
	if tonumber(check_res[1]["COUNT"]) >0 then
		  ngx.say("{\"success\":false,\"info\":\""..unit_name.."已存在,同一个地区不能添加同名的学校！\"}");
		  return;
	end
end



--单位类型 1为教育局2为学校3为部门
if args["org_type"] == nil or args["org_type"] == "" then
    ngx.say("{\"success\":false,\"info\":\"单位类型不能为空！\"}")
	ngx.log(ngx.ERR, "ERR MSG =====> 参数org_type不能为空！");
    return
end
local org_type = args["org_type"];


--业务系统来源
if args["business_system"] == nil or args["business_system"] == "" then
    business_system='COMMON';
end
local business_system  = args["business_system"];

local register_flag = args["register_flag"];
if register_flag == nil or register_flag=="" then 
	register_flag =1;
end

local create_time = os.date("%Y-%m-%d %H:%M:%S", os.time());

local insert_sql_before = "INSERT INTO T_BASE_ORGANIZATION(ORG_ID,ORG_NAME,PARENT_ID, SORT_ID,CREATE_TIME,DISTRICT_ID,CITY_ID,PROVINCE_ID,LEVEL,register_flag";

local insert_sql_after ="("..org_id..",'"..unit_name.."',-1,0,'"..create_time.."',"..district_id..","..city_id..","..province_id..",1,"..register_flag;
--教育类型
local edu_type  = args["edu_type"];
if edu_type==nil or edu_type =="" then

else
	insert_sql_before = insert_sql_before..",EDU_TYPE";
	insert_sql_after = insert_sql_after..","..edu_type;

end
--学校性质
local school_type = args["school_type"];
if school_type==nil or school_type =="" then

else
	insert_sql_before = insert_sql_before..",SCHOOL_TYPE";
	insert_sql_after = insert_sql_after..","..school_type;

end

--简拼
local jp = args["jp"];

if jp==nil or jp=="" then 

else 
	insert_sql_before = insert_sql_before..",JP";
	insert_sql_after = insert_sql_after..",'"..jp.."'";

end

--单位地址
local address = args["address"];

if address==nil or address=="" then

else
	insert_sql_before = insert_sql_before..",ADDRESS";
	insert_sql_after = insert_sql_after..",'"..address.."'";

end



--主校ID
local main_school_id = args["main_school_id"];

if main_school_id == nil or main_school_id =="" then

else
	insert_sql_before = insert_sql_before..",MAIN_SCHOOL_ID";
	insert_sql_after = insert_sql_after..","..main_school_id;
end
--描述

local description = args["description"];

if description == nil or description =="" then

else
	insert_sql_before = insert_sql_before..",DESCRIPTION";
	insert_sql_after = insert_sql_after..",'"..description.."'";
end

insert_sql_before= insert_sql_before..",AREA_ID,ORG_TYPE,BUSINESS_SYSTEM_SOURCE ) VALUES";
insert_sql_after = insert_sql_after..","..area_id..","..org_type..",'"..business_system.."')";


--ngx.log(ngx.ERR,"area_id="..area_id.."&pId1"..pId1.."&pId2="..pId2.."&school_type="..school_type.."&org_type="..org_type.."&unit_name="..unit_name.."&edu_type="..edu_type.."&school_type="..school_type.."&address="..address.."&main_school_id="..main_school_id);
local insert_sql = insert_sql_before..insert_sql_after; --插入组织表的SQL

ngx.log(ngx.ERR,insert_sql);

local insert_org_res,err,errno,sqlstate = _DBUtil:querySingleSql(insert_sql);

if not insert_org_res then
	ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	return
end
 


local bureau_id = org_id;

--更新部门ID与组织ID相同
local update_sql="UPDATE T_BASE_ORGANIZATION SET BUREAU_ID = "..bureau_id..", ORG_CODE = '_"..org_id.."_' WHERE ORG_ID = "..org_id;

local update_org_res = _DBUtil:querySingleSql(update_sql);

local identity_id ;
local identity_id;
local role_id;

if org_type == '2' then
	--学校管理员
		identity_id = 4;
		role_id = 2;
	else
	--教育局
		identity_id = 3;
		role_id = 3;	
end

--往t_base_person表里插入数据
local insert_person_sql="INSERT INTO T_BASE_PERSON( PERSON_NAME, ORG_ID, BUREAU_ID ,DISTRICT_ID,CITY_ID, PROVINCE_ID,CREATE_TIME, B_USE, IDENTITY_ID )VALUES('"..unit_name.."',"..org_id..","..bureau_id..","..district_id..","..city_id..","..province_id..",'"..create_time.."',1,"..identity_id..");";

ngx.log(ngx.ERR,"org_log:insert_person_sql->"..insert_person_sql);

local insert_person_res=_DBUtil:querySingleSql(insert_person_sql);

local person_id = insert_person_res.insert_id;

--增加登录账号

local login_name;

--根据身份获取登录名开头字符串
local get_login_begin_sql = "SELECT LOGIN_BEGIN FROM T_SYS_IDENTITY WHERE IDENTITY_ID = "..identity_id;

ngx.log(ngx.ERR,"org_log:get_login_begin_sql->"..get_login_begin_sql);

local login_name_begin_res = _DBUtil:querySingleSql(get_login_begin_sql);

local login_name_begin="";
if login_name_begin_res[1] == nil or login_name_begin_res[1]=="" then 

else
	login_name_begin = login_name_begin_res[1]["LOGIN_BEGIN"];
end

ngx.log(ngx.ERR,"org_log:login_name_begin->"..login_name_begin);

local get_max_login_name_sql = "SELECT MAX(LOGIN_NAME) LOGIN_NAME FROM T_SYS_LOGINPERSON WHERE IDENTITY_ID = "..identity_id.." AND LOGIN_NAME LIKE '"..login_name_begin.."%';";

ngx.log(ngx.ERR,get_max_login_name_sql);

local get_max_login_name_res = _DBUtil:querySingleSql(get_max_login_name_sql);

local max_login_name = login_name_begin.."000000";
if get_max_login_name_res[1]["LOGIN_NAME"]~=nil and get_max_login_name_res[1]["LOGIN_NAME"]~="" then 
	 max_login_name = get_max_login_name_res[1]["LOGIN_NAME"];
end

local login_name_end = tonumber(string.sub(max_login_name,4,string.len(max_login_name)))+1;

login_name = login_name_begin..string.format("%06d", login_name_end);
--ngx.log(ngx.ERR,"login_name->"..string.sub(max_login_name,4,string.len(max_login_name)).."----"..login_name);

local login_password= ngx.md5(123456);
local insert_loginperson_sql = "INSERT INTO T_SYS_LOGINPERSON(PERSON_NAME,LOGIN_NAME,LOGIN_PASSWORD,IDENTITY_ID,B_USE,PERSON_ID) VALUES('"..unit_name.."','"..login_name.."','"..login_password.."',"..identity_id..",1,"..person_id..")";
ngx.log(ngx.ERR,"org_log:insert_loginperson_sql->"..insert_loginperson_sql);

local insert_loginperson_res = _DBUtil:querySingleSql(insert_loginperson_sql);

--增加角色关系
local insert_person_role_sql = "INSERT INTO T_SYS_PERSON_ROLE(PERSON_ID,ROLE_ID,IDENTITY_ID,ORG_ID) VALUES("..person_id..","..role_id..","..identity_id..","..org_id..")";
local insert_person_role_res = _DBUtil:querySingleSql(insert_person_role_sql);

--[[
--增加t_base_chat

local insert_chat_sql = "insert t_base_chat (chat_type) values(2);";

local insert_caht_res = _DBUtil:querySingleSql(insert_chat_sql);

local caht_id = insert_caht_res.insert_id;


--增加chat person 

local myts = require "resty.TS";
local ts =  myts.getTs();

local insert_chat_person_sql1 =  "INSERT INTO T_BASE_CHAT_PERSON (CHAT_ID,CHAT_NAME,PERSON_ID,IDENTITY_ID,B_VISIBLE,LAST_ACCESS_TIME,TS) VALUES (100,'系统消息',"..person_id..","..identity_id..",1,'"..create_time.."',"..ts..")";

local insert_chat_person_sql2 =  "INSERT INTO T_BASE_CHAT_PERSON (CHAT_ID,CHAT_NAME,PERSON_ID,IDENTITY_ID,B_VISIBLE,LAST_ACCESS_TIME,TS) VALUES ("..identity_id..",'系统消息',"..person_id..","..identity_id..",1,'"..create_time.."',"..ts..")";

local insert_chat_person_sql3 =  "INSERT INTO T_BASE_CHAT_PERSON (CHAT_ID,CHAT_NAME,PERSON_ID,IDENTITY_ID,B_VISIBLE,LAST_ACCESS_TIME,TS) VALUES ("..caht_id..",'系统消息',"..person_id..","..identity_id..",1,'"..create_time.."',"..ts..")";

_DBUtil:querySingleSql(insert_chat_person_sql1);

_DBUtil:querySingleSql(insert_chat_person_sql2);

_DBUtil:querySingleSql(insert_chat_person_sql3);
]]
--维护缓存

--bureau_100001 [{"id":"100001","pId":"0","name":"北京市教育厅"}]
local bureau_cache_sql="SELECT ORG_ID AS ID,ORG_NAME AS NAME,PARENT_ID AS PID FROM T_BASE_ORGANIZATION WHERE BUREAU_ID="..bureau_id.." ORDER BY SORT_ID DESC";

local bureau_cache_res = _DBUtil:querySingleSql(bureau_cache_sql);


local bureau_cache_tab = {}
for i=1,#bureau_cache_res do
	local bureau_table = {}
	bureau_table["id"] = bureau_cache_res[i]["ID"];
	bureau_table["pId"] = bureau_cache_res[i]["PID"];
	bureau_table["name"] = bureau_cache_res[i]["NAME"];
	bureau_cache_tab[i]=bureau_table;
end

cache:set("bureau_"..bureau_id,cjson.encode(bureau_cache_tab));

cache:hmset("t_base_organization_"..bureau_id,"org_name",unit_name,"bureau_id",bureau_id,"district_id",district_id,"city_id",city_id,"province_id",province_id,"school_type",school_type);

--登录基本信息缓存

local token = ngx.md5(person_id.."_"..identity_id.."_dsideal4r5t6y7u");
cache:hmset("login_"..login_name,"pwd",login_password,"person_id",person_id,"token",token,"identity_id",identity_id,"b_use",1,"person_name",unit_name);

--角色缓存维护
cache:rpush("role_"..person_id.."_"..identity_id,role_id);
--人员地区缓存维护
cache:hset("person_"..person_id.."_"..identity_id,"token",token);
cache:hset("person_"..person_id.."_"..identity_id,"sheng",province_id);
cache:hset("person_"..person_id.."_"..identity_id,"shi",city_id);
cache:hset("person_"..person_id.."_"..identity_id,"qu",district_id);
cache:hset("person_"..person_id.."_"..identity_id,"xiao",bureau_id);
cache:hset("person_"..person_id.."_"..identity_id,"bm",org_id);

ngx.log(ngx.ERR,"org_log:bureau_"..bureau_id..",t_base_organization_"..bureau_id..",login_"..login_name..",role_"..person_id.."_"..identity_id..",person_"..person_id.."_"..identity_id);

--缓存结束

--redis放回连接池
cache:set_keepalive(0,v_pool_size)


local result = {} 
result.success = true;
result.org_id = tonumber(org_id);
result.info = "新增教育单位成功！";
ngx.print(cjson.encode(result));
