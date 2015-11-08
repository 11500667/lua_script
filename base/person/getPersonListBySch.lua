#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2015-01-20
#描述：根据传入的学校id获得该学校下的老师
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

--2.获得参数方法
--获得idS
if args["school_id"] == nil or args["school_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"school_id参数错误！\"}")
    return
end
local school_id = args["school_id"]
school_id= ngx.quote_sql_str(school_id);


local  sel_person = "SELECT PERSON_ID,PERSON_NAME,XB_NAME";
local sel_count_person = "SELECT count(1) as COUNT";
local sel_person_name=" FROM t_base_person WHERE BUREAU_ID = "..school_id.." AND B_USE = 1 AND IDENTITY_ID = 5 ";

if args["person_name"] == nil or args["person_name"] == "" then
  
else
  local person_name= ngx.decode_base64(args["person_name"]);
  sel_person_name=sel_person_name.." and ( person_name like '%"..person_name.."%' or jp like '%"..person_name.."%' or qp like '%"..person_name.."%')";
   
end

--[[
if args["person_name"] == nil or args["person_name"] == "" then
  
else
  local person_name= args["person_name"];
  sel_person_name=sel_person_name.." AND person_name like '%"..person_name.."%'";
   
end


if args["jp"] == nil or args["jp"] == "" then
  
else
  local jp= args["jp"];
  sel_person_name=sel_person_name.." AND jp like '%"..jp.."%'";
   
end

if args["qp"] == nil or args["qp"] == "" then
  
else
  local qp= args["qp"];
  sel_person_name=sel_person_name.." AND qp like '%"..qp.."%'";
   
end

]]
local responseObj = {};
local recordsPerson = {};
local pageNumber = args["pageNumber"]
local pageSize = args["pageSize"]
local page_sql =""
if pageSize==nil or pageSize == "" or pageNumber == nil or pageNumber =="" then

else
	local offset = pageSize*pageNumber-pageSize
	local limit = pageSize

	page_sql = " LIMIT "..offset..","..limit..";"
	
	local res_count = db:query(sel_count_person..sel_person_name);
	local totalRow = res_count[1]["COUNT"]
	local totalPage = math.floor((totalRow+pageSize-1)/pageSize)
	responseObj["totalRow"] = tonumber(totalRow)
	responseObj["totalPage"] = tonumber(totalPage)
	responseObj["pageNumber"] = tonumber(pageNumber)
	responseObj["pageSize"] = tonumber(pageSize)
end

 
 ngx.log(ngx.ERR,"hy_log--->"..sel_person..sel_person_name..page_sql);
-- 4.查询学生对应的名称记录
local results, err, errno, sqlstate = db:query(sel_person..sel_person_name..page_sql);



if not results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end





for i=1, #results do
	local temp_personId= results[i]["PERSON_ID"];
	local temp_personName = results[i]["PERSON_NAME"];
	local temp_xbName = results[i]["XB_NAME"];

	local record = {};
	record.personID = temp_personId;
	record.personName = temp_personName;
	record.xbName = temp_xbName;
	table.insert(recordsPerson, record);
end

responseObj.success = true;
responseObj.list = recordsPerson;


-- 5.将table对象转换成json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(responseObj);

-- 6.输出json串到页面
ngx.say(responseJson);

-- 7.将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end









