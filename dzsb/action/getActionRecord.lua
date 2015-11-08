#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#李政言 2014-02-02
#描述：获得用户行为记录
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
--2.获得参数方法
--获得教师id
if args["teacher_id"] == nil or args["teacher_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"teacher_id参数错误！\"}")
    return
end
local teacher_id = tostring(args["teacher_id"]);
--获得学生id
if args["student_id"] == nil or args["student_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"student_id参数错误！\"}")
    return
end
local student_id = tostring(args["student_id"]);
--获得行为类型id
if args["action_type"] == nil or args["action_type"] == "" then
    ngx.say("{\"success\":false,\"info\":\"action_type参数错误！\"}")
    return
end
local action_type = tostring(args["action_type"]);

local pageNumber = args["pageNumber"]
-- 判断是否有pageNumber参数
if pageNumber==nil  then
    ngx.say("{\"success\":false,\"info\":\"pageNumber参数错误！\"}")
    return
end


local pageSize = args["pageSize"]
-- 判断是否有pageSize参数
if pageSize == nil then
    ngx.say("{\"success\":false,\"info\":\"pageSize参数错误！\"}")
    return
end



local answer_type = "";
local answer_type_str = "";
if action_type == "5" then
    --获得答案类型id
   if args["answer_type"] == nil or args["answer_type"] == "" then
       ngx.say("{\"success\":false,\"info\":\"answer_type参数错误！\"}")
       return
    end
    answer_type = tostring(args["answer_type"]);
	answer_type_str = " AND answer_type = "..answer_type;
end

--开始时间
if args["start_time"] == nil or args["start_time"] == "" then
    ngx.say("{\"success\":false,\"info\":\"start_time参数错误！\"}")
    return
end
local start_time = tostring(args["start_time"]);

--结束时间
if args["end_time"] == nil or args["end_time"] == "" then
    ngx.say("{\"success\":false,\"info\":\"end_time参数错误！\"}")
    return
end
local end_time = tostring(args["end_time"]);

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
local sel_record="";
local  sel_record_count = "";

if action_type == "3" then
    sel_record = "SELECT id,time as start_time,end_time,time_format(timediff(end_time, time),'%Hh%im') as time   FROM T_BAG_CQJSTW WHERE TEACHER_ID='"..teacher_id.."' "..answer_type_str.." AND STUDENT_ID = '"..student_id.."' AND TYPE_ID="..action_type.." AND end_time!='0000-00-00 00:00:00' AND TIME BETWEEN '"..start_time.."' AND '"..end_time.."' ";
    sel_record_count= "SELECT count(*) as count  FROM T_BAG_CQJSTW WHERE TEACHER_ID="..teacher_id.." "..answer_type_str.." AND STUDENT_ID = "..student_id.." AND TYPE_ID="..action_type.." AND end_time!='0000-00-00 00:00:00' AND TIME BETWEEN '"..start_time.."' AND '"..end_time.."' ";
else
    sel_record = "SELECT date(TIME) AS date ,COUNT(1) AS turnOut  FROM T_BAG_CQJSTW WHERE TEACHER_ID="..teacher_id.."  "..answer_type_str.." AND STUDENT_ID = "..student_id.." AND TYPE_ID="..action_type.."  AND TIME BETWEEN  '"..start_time.."' AND '"..end_time.."' GROUP BY date(TIME) ";
	sel_record_count="SELECT date(TIME) AS date ,COUNT(1) AS turnOut  FROM T_BAG_CQJSTW WHERE TEACHER_ID="..teacher_id.."  "..answer_type_str.." AND STUDENT_ID = "..student_id.." AND TYPE_ID="..action_type.."  AND TIME BETWEEN  '"..start_time.."' AND '"..end_time.."' GROUP BY date(TIME) ";
end

local offset = pageSize*pageNumber-pageSize
local limit = pageSize
--local str_maxmatches = pageNumber*pageSize

local sql_limit = " limit "..offset..","..limit;

local res_count = db:query(sel_record_count);

local totalRow =0;
if action_type == "3" then
    totalRow = res_count[1]["count"];
 else
    totalRow = #res_count;
 end
 
local totalPage = math.floor((totalRow+pageSize-1)/pageSize);


ngx.log(ngx.ERR,"sel_record==+++++++++++++"..sel_record..sql_limit);
-- 4.查询用户行为
local results, err, errno, sqlstate = db:query(sel_record);
if not results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end

local responseObj = {};
local tab = {};
 responseObj.success = true;
for i=1,#results do
     local tab_temp = {};
	 --根据资源id去查找缓存
	 if action_type == "3" then
    	tab_temp.id =  results[i]["id"];
    	tab_temp.start_time =  results[i]["start_time"];
    	tab_temp.end_time =  results[i]["end_time"];
    	tab_temp.time =  results[i]["time"];
    	tab[i]=tab_temp
	else
	    tab_temp.date =  results[i]["date"];
    	tab_temp.turnOut =  results[i]["turnOut"];
    	tab[i]=tab_temp
	end
end
responseObj.list= tab;
responseObj.success = true;

responseObj.totalPage = totalPage;
responseObj.totalRow = totalRow;
responseObj.pageNumber =pageNumber;
responseObj.pageSize =pageSize;
-- 5.将table对象转换成json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(responseObj);
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









