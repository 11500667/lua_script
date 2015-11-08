#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#张爱旭 2015-08-12
#描述：学生提交试卷
 参数：student_id：学生id   id:试卷小id  answerInfo：学生答案信息的json字符串
 涉及到的表：t_base_student、t_resource_sendstudent、t_bag_ststuinfo
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
--获得学生id
if args["student_id"] == nil or args["student_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"student_id参数错误！\"}");
    return;
end
local student_id = tonumber(args["student_id"]);
ngx.log(ngx.ERR, "$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$student_id:", student_id);

--获得试卷小id
if args["id"] == nil or args["id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"id参数错误！\"}");
    return;
end
local id = ngx.quote_sql_str(tostring(args["id"]));
ngx.log(ngx.ERR, "$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$id:", id);

--获得学生试卷答案信息
if args["answerInfo"] == nil or args["answerInfo"] == "" then
    ngx.say("{\"success\":false,\"info\":\"answerInfo参数错误！\"}");
    return;
end
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local answerInfo = cjson.decode(args["answerInfo"]);
local answerInfo_list = answerInfo.list;
ngx.log(ngx.ERR, "$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$answerInfo_list:", #answerInfo_list);

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

local sql = "SELECT class_id FROM t_base_student WHERE student_id = "..student_id..";"; 
local list, err, errno, sqlstate = db:query(sql);
if not list then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"查询班级id出错！\"}");
    return;
end
local class_id = tonumber(list[1]["class_id"]);
ngx.log(ngx.ERR, "$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$class_id:", class_id);

sql = "SELECT resource_id FROM t_resource_sendstudent WHERE id="..id..";";
list, err, errno, sqlstate = db:query(sql);
if not list then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"查询试卷id出错！\"}");
    return;
end
local resource_id = ngx.quote_sql_str(tostring(list[1]["resource_id"]));
ngx.log(ngx.ERR, "$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$resource_id:", resource_id);
--题的ID
local question_id = nil;
--XML中的ID
local item_id = nil;
--题型
local question_type = nil;
--是否正确 0：错    1：对
local is_right = false;
--该题的得分
local score = nil;
--答案 如果是主观题是ZIP的ID
local answer = nil;

for i=1, #answerInfo_list do
    question_id = ngx.quote_sql_str(tostring(answerInfo_list[i]["question_id"]));
	ngx.log(ngx.ERR, "$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$question_id:", question_id);
    item_id = tonumber(answerInfo_list[i]["item_id"]);
	ngx.log(ngx.ERR, "$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$item_id:", item_id);
    question_type = tonumber(answerInfo_list[i]["question_type"]);
	ngx.log(ngx.ERR, "$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$question_type:", question_type);
    is_right = tonumber(answerInfo_list[i]["is_right"]);
	ngx.log(ngx.ERR, "$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$is_right:", is_right);
    score = tonumber(answerInfo_list[i]["score"]);
	ngx.log(ngx.ERR, "$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$score:", score);
    answer = ngx.quote_sql_str(tostring(answerInfo_list[i]["answer"]));
	ngx.log(ngx.ERR, "$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$answer:", answer);
    
    sql = "DELETE FROM t_bag_ststuinfo WHERE resource_id="..resource_id.." AND question_id="..question_id.." AND student_id="..student_id..";";
    list, err, errno, sqlstate = db:query(sql);
    if not list then
        ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
        ngx.say("{\"success\":\"false\",\"info\":\"删除数据出错！\"}");
        return;
    end
    sql = "INSERT INTO t_bag_ststuinfo (resource_id,question_id,student_id,stu_sjid,item_id,question_type,is_right,score,answer,class_id) VALUES ("..resource_id..", "..question_id..", "..student_id..", "..id..", "..item_id..", "..question_type..", "..is_right..", "..score..", "..answer..", "..class_id..");";
    list, err, errno, sqlstate = db:query(sql);
    if not list then
        ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
        ngx.say("{\"success\":\"false\",\"info\":\"插入数据出错！\"}");
        return;
    end
end

local result = {};
result["success"] = true;

-- 5.将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

-- 6.返回值
local responseJson = tostring(cjson.encode(result));
ngx.say(responseJson);