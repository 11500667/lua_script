#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#张爱旭 2015-08-12
#描述：获取学生一段时间内的考试情况
 参数：teacher_id：老师的ID student_id：学生id startDate：开始日期 endDate：结束日期
 返回值：DATE 日期、SCORE 分数、SORT 排名、HIGH 最高分、LOW 最低分、AVEAGE 平均分
 涉及到的表：t_bag_sjstate、t_bag_resource_info（弃用）改为t_resource_info、t_base_student、t_bag_ststuinfo
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
--获得老师id
if args["teacher_id"] == nil or args["teacher_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"teacher_id参数错误！\"}");
    return;
end
local teacher_id = tonumber(args["teacher_id"]);

--获得学生id
if args["student_id"] == nil or args["student_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"student_id参数错误！\"}");
    return;
end
local student_id = tonumber(args["student_id"]);

--获得开始日期
if args["startDate"] == nil or args["startDate"] == "" then
    ngx.say("{\"success\":false,\"info\":\"startDate参数错误！\"}");
    return;
end
local startDate = ngx.quote_sql_str(tostring(args["startDate"]));

--获得结束日期
if args["endDate"] == nil or args["endDate"] == "" then
    ngx.say("{\"success\":false,\"info\":\"endDate参数错误！\"}");
    return;
end
local endDate = tostring(args["endDate"]);
--2015-08-12格式
local Y = string.sub(endDate, 1, 4);
local M = string.sub(endDate, 6, 7);
local D = string.sub(endDate, 9, 10);
 --把日期时间字符串转换成对应的日期时间
local dt1 = os.time{year=Y, month=M, day=D};
--根据时间单位和偏移量得到具体的偏移数据
local ofset = 60 * 60 * 24 * 1;
--指定的时间+时间偏移量，此时获得的是一个table值
local newTime = os.date("*t", dt1 + tonumber(ofset));
endDate = ngx.quote_sql_str(string.format('%d-%02d-%02d', newTime.year, newTime.month, newTime.day));

--3.连接数据库
local mysql = require "resty.mysql";
local db, err = mysql : new();
if not db then
    ngx.log(ngx.ERR, err);
    return;
end

db:set_timeout(1000); -- 1 sec

local ok, err, errno, sqlstate = db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024 * 1024
}

if not ok then
    ngx.say("failed to connect: ", err, ": ", errno, " ", sqlstate);
    return;
end

--查询class_id
local sql = "SELECT CLASS_ID FROM T_BASE_STUDENT WHERE STUDENT_ID="..student_id..";";
local queryList, err, errno, sqlstate = db:query(sql);
if not queryList then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"查询学生所在班级id出错！\"}");
    return;
end
local class_id = tonumber(queryList[1]["CLASS_ID"]);

--查询id，根据id查询resource_id_int
sql = "SELECT SQL_NO_CACHE ID FROM t_resource_info_sphinxse WHERE QUERY='filter=person_id,"..teacher_id..";filter=bk_type,107;filter=release_status,1,3;filter=group_id,2';";
queryList, err, errno, sqlstate = db:query(sql);
if not queryList then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"查询id出错！\"}");
    return;
end
local ids = "";
for i=1, #queryList do
	ids = ids..ngx.quote_sql_str(tostring(queryList[i]["ID"]))..",";
end
if ids ~= "" then
	ids = string.sub(ids, 0, #ids - 1);
end
sql ="SELECT resource_id_int FROM t_resource_info WHERE id in ("..ids..");";
queryList, err, errno, sqlstate = db:query(sql);
if not queryList then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"查询resource_id_int出错！\"}");
    return;
end
local resource_ids = "";
for i=1, #queryList do
	resource_ids = resource_ids .. ngx.quote_sql_str(tostring(queryList[i]["resource_id_int"])) .. ",";
end
if resource_ids ~= "" then
	resource_ids = string.sub(resource_ids, 0, #resource_ids - 1);
end

sql = "SELECT RESOURCE_ID, date(EXAM_TIME) AS RQ FROM T_BAG_SJSTATE WHERE RESOURCE_ID IN ("..resource_ids..") AND CLASS_ID="..class_id.." AND IS_EXAM=1 AND date(EXAM_TIME) BETWEEN "..startDate.." AND "..endDate.." ORDER BY EXAM_TIME;";
queryList, err, errno, sqlstate = db:query(sql);
if not queryList then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"查询某段时间某个学生的试卷和考试日期的数据出错！\"}");
    return;
end
local myList = queryList;

-- 试卷的id
local resource_id = "";
-- 日期
local rq = "";
-- 临时变量，记录当前分数
local tmp = 0;
-- 最高分
local high = 0;
-- 最低分
local low = 0;
-- 平均分
local average = 0;
-- 总分
local total = 0;
-- 某次考试的总分
local score = -1;
-- 排名
local sort = 1;

local result = {};
local list = {};
for i=1, #myList do
	rq = tostring(myList[i]["RQ"]);
    resource_id = ngx.quote_sql_str(tostring(myList[i]["RESOURCE_ID"]));
	-- 本班所有参加这次试卷的考试的每个学生的总分和该学生的id
    sql = "SELECT SUM(score) AS SCORE,STUDENT_ID FROM T_BAG_STSTUINFO WHERE CLASS_ID="..class_id.." AND RESOURCE_ID="..resource_id.." GROUP BY STUDENT_ID;";
    queryList, err, errno, sqlstate = db:query(sql);
    if not queryList then
        ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
        ngx.say("{\"success\":\"false\",\"info\":\"查询本班所有参加这次试卷的考试的每个学生的总分和该学生的id数据出错！\"}");
        return;
    end
	
	score = -1;
	local sortScore = {};
    for r=1, #queryList do
        tmp = tonumber(queryList[r]["SCORE"]);
        sortScore[r] = tmp;
        if r == 1 then
            high = tmp;
            low = tmp;
            aveage = tmp;
        else
            --最大
            if tmp > high then
                high = tmp;
            end
            
            --最小
            if tmp < low then
                low = tmp;  
            end
        end
        
        local tmpStuID = tonumber(queryList[r]["STUDENT_ID"]);
        if tmpStuID == student_id then
            score = tmp;
        end
        
        total = total + tmp;
    end
    
    if #queryList > 0 then
        average = total / #queryList;
    end;
    
	if score ~= -1 then-- -1时代表没参加本次考试
		--算排名
		sort = 1;
		for s=1, #sortScore do
			if sortScore[s] > score then
				sort = sort + 1;
			end
		end
		list["date"] = rq;
		list["score"] = score;
		list["sort"] = sort;
		list["high"] = high;
		list["low"] = low;
		list["average"] = average;
		
		table.insert(result,list);
	end
end

result["success"] = true;

--4.将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

-- 5.返回值
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = tostring(cjson.encode(result));
ngx.say(responseJson);