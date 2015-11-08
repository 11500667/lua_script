#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#曹洪念 2015.8.14
#描述： 上传“测试”文件单独的信息 更新处理也在此
#参数：资源id(resource_id)  需上传xml信息(需要传json数据)
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

--2.获取参数
--获得资源id
if args["resource_id"] == nil or args["resource_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"resource_id参数错误！\"}")
    return
end
local resource_id = args["resource_id"]

--获得试卷信息
if args["sj_info"] == nil or args["sj_info"] == "" then
    ngx.say("{\"success\":false,\"info\":\"sj_info参数错误！\"}")
    return
end

local cjson = require "cjson"
cjson.encode_empty_table_as_object(false);
local sj_info = cjson.decode(args["sj_info"])
local sj_info_list = sj_info.list;

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
		ngx.print("{\"success\":false,\"info\":\"数据库连接失败！\"}")
		ngx.log(ngx.ERR, "[sj_log]->[DBUtil]-> 连接数据库失败!");
		return false;
	end

--4.数据处理
--获取试题信息
--xml中的id
local item_id = nil
--题的id
local question_id = nil
--难度
local difficulty = nil
--题型
local question_type = nil
--问题内容
local question_title = nil
--正确答案
local right_answer = nil
--分数
local score = nil	

local responseObj = {};	
	
--插入每条试题信息  
for i=1,#sj_info_list
do
    item_id = ngx.quote_sql_str(tostring(sj_info_list[i]["item_id"]));
	question_id = ngx.quote_sql_str(tostring(sj_info_list[i]["question_id"]));
	difficulty = ngx.quote_sql_str(tostring(sj_info_list[i]["difficulty"]));
    question_type = tonumber(sj_info_list[i]["question_type"]);
	question_title = ngx.quote_sql_str(tostring(sj_info_list[i]["question_title"]));
    right_answer = ngx.quote_sql_str(tostring(sj_info_list[i]["right_answer"]));
    score = tonumber(sj_info_list[i]["score"]);
	
--添加判断处理 先查询数据 如果有数据进行更新处理 如果没有数据进行插入处理
local sql3 = "SELECT * FROM t_bag_sjinfo WHERE QUESTION_ID = "..question_id
local sel_sjinfo_results, err, errno, sqlstate = db:query(sql3);

if not sel_sjinfo_results then
     ngx.log(ngx.ERR, "查询试卷信息出错bad result: ", err, ": ", errno, ": ", sqlstate, ".");
     ngx.say("{\"success\":\"false\",\"info\":\"查询试卷信息出错！\"}");
     return
	 end
	 
if (#sel_sjinfo_results == 0) then
	 -- 表示没有数据 插入操作
	 
--删除该试卷中的该试题信息
-- local sql = "DELETE FROM T_BAG_SJINFO WHERE QUESTION_ID = "..question_id
-- local del_sjinfo_results, err, errno, sqlstate = db:query(sql);

-- if not del_sjinfo_results then
--      ngx.log(ngx.ERR, "删除试卷信息出错bad result: ", err, ": ", errno, ": ", sqlstate, ".");
 --     ngx.say("{\"success\":\"false\",\"info\":\"删除试卷信息出错！\"}");
 --     return
-- 	 end

 local sql2 = "INSERT INTO T_BAG_SJINFO (QUESTION_ID,RESOURCE_ID,ITEM_ID,DIFFICULTY,QUESTION_TYPE,QUESTION_TITLE,RIGHT_ANSWER,SCORE) VALUES ("..question_id..",'"..resource_id.."',"..item_id..","..difficulty..",'"..question_type.."',"..question_title..","..right_answer..",'"..score.."')";
 local list2, err, errno, sqlstate = db:query(sql2);

if not list2 then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"插入试卷信息有误\"}");
    return
	end
	
	responseObj.success = true;
	responseObj.info = "插入试卷信息成功";
	 
 else
 -- 表示有数据  更新操作
 local sql4 = "UPDATE t_bag_sjinfo SET RESOURCE_ID = "..resource_id..",ITEM_ID = "..item_id..",DIFFICULTY = "..difficulty..",QUESTION_TYPE = "..question_type..",QUESTION_TITLE = "..question_title..",RIGHT_ANSWER ="..right_answer..",SCORE = "..score.." where QUESTION_ID = "..question_id
 
 local list4, err, errno, sqlstate = db:query(sql4);
 
 if not list4 then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"更新试卷信息有误\"}");
    return
	end
	
	responseObj.success = true;
	responseObj.info = "更新试卷信息成功";
		
--end 判断是更新还是插入 
 end

--end for
end

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