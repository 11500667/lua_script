#修改教育单位 by huyue 2015-06-30
--1.获得参数方法
local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
  args = ngx.req.get_uri_args()
else
  ngx.req.read_body()
  args = ngx.req.get_post_args()
end

--引用模块
local cjson = require "cjson"
cjson.encode_empty_table_as_object(false);
local _DBUtil = require "common.DBUtil";
--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end
--组织ID
if args["org_id"] == nil or args["org_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"org_id参数错误！\"}")
	ngx.log(ngx.ERR, "ERR MSG =====> 参数org_id不能为空！");
    return
end

local org_id = args["org_id"];

--单位名称
if args["unit_name"] == nil or args["unit_name"] == "" then
    ngx.say("{\"success\":false,\"info\":\"单位名称不能为空！\"}")
	ngx.log(ngx.ERR, "ERR MSG =====> 参数unit_name不能为空！");
    return
end
local unit_name  = args["unit_name"];

--单位类型
if args["org_type"] == nil or args["org_type"] == "" then
    ngx.say("{\"success\":false,\"info\":\"参数org_type不能为空！\"}")
	ngx.log(ngx.ERR, "ERR MSG =====> 参数org_type不能为空！");
    return
end
local org_type  = args["org_type"];

--业务系统来源
if args["business_system"] == nil or args["business_system"] == "" then
    ngx.say("{\"success\":false,\"info\":\"参数business_system不能为空！\"}")
	ngx.log(ngx.ERR, "ERR MSG =====> 参数business_system不能为空！");
    return
end
local business_system  = args["business_system"];

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


local check_sql = "select count(1) as COUNT from t_base_organization where org_name = '"..unit_name.."' and district_id ="..district_id.." and city_id ="..city_id.." and province_id ="..province_id.." and org_id <>"..org_id;
ngx.log(ngx.ERR,check_sql);

local check_res=_DBUtil:querySingleSql(check_sql);
--ngx.log(ngx.ERR,"----------------------------"..check_res[1]["COUNT"]);

if check_res and check_res[1] then 
	if tonumber(check_res[1]["COUNT"]) >0 then
		  ngx.say("{\"success\":false,\"info\":\""..unit_name.."已存在,同一个地区不能添加同名的学校！\"}");
		  return;
	end
end


local update_org_sql = "UPDATE T_BASE_ORGANIZATION SET ORG_NAME = '"..unit_name.."',BUSINESS_SYSTEM_SOURCE='"..business_system.."'";

--单位地址
local address = args["address"];

if address == nil or address =="" then 

else
 update_org_sql = update_org_sql..",ADDRESS = '"..address.."'";

end

--教育类型
local edu_type  = args["edu_type"];

if edu_type == nil or edu_type =="" then  

else 
 update_org_sql = update_org_sql..",EDU_TYPE = "..edu_type;
end

--学校性质
local school_type = args["school_type"];

if  school_type==nil or school_type=="" then 
else
	update_org_sql = update_org_sql..",SCHOOL_TYPE="..school_type;
end

--主校ID
local main_school_id = args["main_school_id"];

if main_school_id == nil or main_school_id == "" then 

else
	update_org_sql = update_org_sql..",MAIN_SCHOOL_ID="..main_school_id;

end

--简拼
local jp = args["jp"];

if jp == nil or jp == "" then 

else
	update_org_sql = update_org_sql..",JP='"..jp.."' ";

end


--描述
local description = args["description"];

if description == nil or description == "" then 

else
	update_org_sql = update_org_sql..",DESCRIPTION='"..description.."' ";

end

update_org_sql = update_org_sql.." WHERE ORG_ID ="..org_id;

ngx.log(ngx.ERR,"org_log----->"..update_org_sql);

local update_org_res,err,errno,sqlstate = _DBUtil:querySingleSql(update_org_sql);

if not update_org_res then
	ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	return
end

local identity_id;

if org_type == '1' then
	--教育局
	identity_id=3 
else
	--学校
	identity_id=4
end

--更新登陆名信息
local query_person_sql = "SELECT PERSON_ID FROM T_BASE_PERSON WHERE ORG_ID = "..org_id.." AND IDENTITY_ID = "..identity_id;
ngx.log(ngx.ERR,"org_log------->"..query_person_sql);

local query_person_res,err,errno,sqlstate = _DBUtil:querySingleSql(query_person_sql);

if not query_person_res then
	ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	return
end

local person_id;
if query_person_res[1] ~= nil then
	person_id = query_person_res[1]["PERSON_ID"];
end

if person_id then

	local update_loginperson_sql = "UPDATE T_SYS_LOGINPERSON SET PERSON_NAME = '"..unit_name.."' WHERE PERSON_ID = "..person_id.." AND IDENTITY_ID = "..identity_id;

	ngx.log(ngx.ERR,"org_log------------>"..update_loginperson_sql);

	local update_loginperson_res,err,errno,sqlstate = _DBUtil:querySingleSql(query_person_sql);

	if not update_loginperson_res then
		ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
		return
	end

	local update_person_sql = "UPDATE T_BASE_PERSON SET PERSON_NAME = "..unit_name.." WHERE PERSON_ID = "..person_id;
	ngx.log(ngx.ERR,"org_log------------>"..update_person_sql);

	local update_person_res,err,errno,sqlstate = _DBUtil:querySingleSql(query_person_sql);

	if not update_person_res then
		ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
		return
	end
	--维护登录缓存
	local query_loginperson_sql = "select login_name from T_SYS_LOGINPERSON where person_id="..person_id;
	ngx.log(ngx.ERR,"org_log---------->"..query_loginperson_sql);

	local query_loginperson_res,err,errno,sqlstate = _DBUtil:querySingleSql(query_loginperson_sql);

	if not query_loginperson_res then
		ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
		return
	end

	local login_name;
	if query_loginperson_res[1] ~= nil then
		login_name = query_loginperson_res[1]["login_name"];
	end

	cache:hmset("login_"..login_name,"person_name",unit_name);

end

--维护缓存
local bureau_id = org_id;
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

--维护缓存开始
cache:set("bureau_"..bureau_id,cjson.encode(bureau_cache_tab));
cache:hmset("t_base_organization_"..bureau_id,"org_name",unit_name,"bureau_id",bureau_id,"school_type",school_type);

--缓存结束

--redis放回连接池
cache:set_keepalive(0,v_pool_size)

local result = {} 
result.success = true;
result.info = "修改教育单位成功！";
ngx.print(cjson.encode(result));

