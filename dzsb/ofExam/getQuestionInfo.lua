#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#张爱旭 2015-08-11
#描述：老师获取某个班某次考试中某道题的信息
 参数：class_id：班级的id resource_id：试卷大id  question_id：试题的id
 返回值：answer、rightRate、highest、lowest、average、que_list
 涉及到的表：t_bag_sjinfo、t_bag_ststuinfo、t_base_student
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
--获得班级class_id
if args["class_id"] == nil or args["class_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"class_id参数错误！\"}");
    return;
end
local class_id = tonumber(args["class_id"]);
ngx.log(ngx.ERR, "$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$", class_id);

--获得试卷resource_id
if args["resource_id"] == nil or args["resource_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"resource_id参数错误！\"}");
    return;
end
local resource_id = ngx.quote_sql_str(tostring(args["resource_id"]));
ngx.log(ngx.ERR, "$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$", resource_id);

--获得试卷question_id
if args["question_id"] == nil or args["question_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"question_id参数错误！\"}");
    return;
end
local question_id = ngx.quote_sql_str(tostring(args["question_id"]));
ngx.log(ngx.ERR, "$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$", question_id);

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

--4.查询数据
local sql = "SELECT RIGHT_ANSWER,QUESTION_TYPE,SCORE FROM T_BAG_SJINFO WHERE QUESTION_ID="..question_id..";";
    
local list, err, errno, sqlstate = db:query(sql);
if not list then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"查询试题信息数据出错！\"}");
    return;
end

--正确答案
local answer = tostring(list[1]["RIGHT_ANSWER"]);

--题型
local question_type = tonumber(list[1]["QUESTION_TYPE"]);

--该题的分数
local score = tonumber(list[1]["SCORE"]);

--答这道题学生的总数
sql = "SELECT COUNT(1) AS TotalCount FROM T_BAG_STSTUINFO WHERE QUESTION_ID="..question_id.." AND CLASS_ID="..class_id.." AND RESOURCE_ID="..resource_id..";";
list, err, errno, sqlstate = db:query(sql);
if not list then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"查询答这道题学生的总数出错！\"}");
    return;
end
local total_count = tonumber(list[1]["TotalCount"]);

--正确的个数
sql = "SELECT COUNT(1) AS RightCount FROM T_BAG_STSTUINFO WHERE IS_RIGHT=1 AND QUESTION_ID="..question_id.." AND CLASS_ID="..class_id.." AND RESOURCE_ID="..resource_id..";";
list, err, errno, sqlstate = db:query(sql);
if not list then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return;
end
local right_count = tonumber(list[1]["RightCount"]);

--正确率
local rightRate = "0";	
if question_type==1 or question_type==2 or question_type==3
    or question_type==4 or question_type==10 or question_type==11
    or question_type==14 or question_type==101 or question_type==102
    or question_type==103 or question_type==104 or question_type==110
    or question_type==114
then--客观题
	rightRate = string.format("%.2f", right_count/total_count);
elseif question_type==5 or question_type==6  or question_type==7 
        or question_type==8 or question_type==105
then--主观题
	sql = "SELECT SUM(SCORE) AS stuScore,COUNT(1)*"..score.." AS queScore FROM T_BAG_STSTUINFO WHERE QUESTION_ID="..question_id.." AND CLASS_ID="..class_id.." AND RESOURCE_ID="..resource_id..";";
    list, err, errno, sqlstate = db:query(sql);
    if not list then
        ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
        ngx.say("{\"success\":\"false\",\"info\":\"查询主观题分数出错！\"}");
        return;
    end
    local stuScore = tonumber(list[1]["stuScore"]);
    local queScore = tonumber(list[1]["queScore"]);
	rightRate = string.format("%.2f", stuScore/queScore);
end

sql = "SELECT MAX(sTotal) AS highest,MIN(sTotal) AS lowest,AVG(sTotal) AS average FROM (SELECT SUM(SCORE) AS sTotal FROM T_BAG_STSTUINFO WHERE QUESTION_ID = "..question_id.." AND CLASS_ID = "..class_id.." AND  RESOURCE_ID="..resource_id.." GROUP BY STUDENT_ID) A";
list, err, errno, sqlstate = db:query(sql);
if not list then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"查询最高分、最低分、平均分出错！\"}");
    return;
end
--最高分
local highest = list[1]["highest"];
--最低分
local lowest = list[1]["lowest"];
--平均分
local average = list[1]["average"];

--查询学生和学生的答案列表
sql = "SELECT t2.student_name,t1.answer FROM t_bag_ststuinfo t1 INNER JOIN t_base_student t2 ON t1.student_id = t2.STUDENT_ID WHERE t1.question_id = "..question_id.." AND t1.class_id = "..class_id.." AND t1.resource_id = "..resource_id.." AND t1.answer != ''";
list, err, errno, sqlstate = db:query(sql);
if not list then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"查询学生和学生的答案出错！\"}");
    return;
end
local que_list = list;

local result = {};
result["success"] = true;
result["answer"] = answer;
result["rightRate"] = rightRate;
result["highest"] = highest;
result["lowest"] = lowest;
result["average"] = average;
result["right_count"] = right_count;
result["wrong_count"] = total_count - right_count;
result["que_list"] = que_list;

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