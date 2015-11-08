--[[
	局部函数：游戏的DAO类
]]
local _WqDiscuss= {};

--[[
	局部函数：消息发送
	ssdb_info：消息的内容
]]
function _WqDiscuss:send_message(ssdb_info)
	local dbUtil = require "yxx.wrong_question_book.util.DbUtil";
	local ssdb_db = dbUtil:getSSDb();
	local mysql_db = dbUtil:getMysqlDb();
	--保存错题本（ssdb、mysql）
	------------------------------------------------------------------------------------------------------------------------------------------------------
	local discuss_id = ssdb_db:incr("wrong_question_discuss_pk_v26_");--生成主键ID
	--保存错题本（ssdb）
	ssdb_db:multi_hset("wrong_question_discuss_v26_"..discuss_id[1],ssdb_info);
	--保存错题本（mysql）
	mysql_db:query("INSERT INTO t_wrong_question_discuss("..
								  "discuss_id,"..		--讨论ID
								  "question_id,".. 		--错题ID
								  "class_id,"..			--班级id
								  "person_id,"..  		--发送消息人ID
								  "person_name,"..		--发送消息人Name
								  "identity_id,"..		--身份ID
								  "avatar_url,"..		--头像
								  "content_info,"..		--消息内容
								  "create_time"..		--发送时间
								  ")"..
						" VALUES ( "..
									discuss_id[1]..","..
									ssdb_info["question_id"]..","..
									ssdb_info["class_id"]..","..
									ssdb_info["person_id"]..","..
									"'"..ssdb_info["person_name"].."',"..
									ssdb_info["identity_id"]..", "..
									"'"..ssdb_info["avatar_url"].."',"..
									"'"..ssdb_info["content_info"].."',"..
									"'"..ssdb_info["create_time"].."');");
	-------------------------------------------------------------------------------------------------------------------------------------------------------
	ssdb_db:set_keepalive(0,v_pool_size);
	mysql_db:set_keepalive(0,v_pool_size);
end
-----------------------------------------------------------------------------------------------------------------------------------------------------------
--[[
	局部函数：个人错题列表
	按学科查询方式：
	subject_id：学科ID
	create_source:错题来源（作业、同步练习）
	cause_content:错题原因（技巧类、态度类、知识点类）
	sort_type：排序类型(1、录入时间 2:错题率)
	sort_num：升/降序
	pageSize:每页记录数
	pageNumber：页数
]]
------------------------------------------------------------------------------------------------------------------------------------------------------------
function _WqDiscuss:message_list(question_id,class_id)
	--------------------------------------------------------------------------------------------------------------------------------------------------------
	--初始化变量
	local dbUtil = require "yxx.wrong_question_book.util.DbUtil";
	local ssdb_db = dbUtil:getSSDb();
	local mysql_db = dbUtil:getMysqlDb();
	local wqDiscussArray  = {};
	--------------------------------------------------------------------------------------------------------------------------------------------------------
	local query_sql = "select discuss_id from t_wrong_question_discuss where (question_id="..question_id.. " and class_id in ("..class_id..")) or (question_id="..question_id .." and class_id=-1)  ORDER BY CREATE_TIME asc";
	--ngx.log(ngx.ERR, "@@@@@@@@@@@@@@"..query_sql.."@@@@@@@@@");
	local rows, err, errno, sqlstate = mysql_db:query(query_sql);
	if not rows then
		ngx.print("{\"success\":\"false\",\"info\":\"查询数据出错。\"}");
		return;
	end
	--------------------------------------------------------------------------------------------------------------------------------------------------------
	for i=1,#rows do
		local wq_discuss_info = ssdb_db:multi_hget("wrong_question_discuss_v26_"..rows[i]["discuss_id"], "question_id","person_id","class_id","person_name","identity_id","avatar_url","content_info","create_time")
		local ssdb_info = {};
		--ssdb_info["discuss_id"]= rows[i]["discuss_id"];				--错题讨论ID
		ssdb_info["question_id"]= wq_discuss_info[2];					--错题ID
		ssdb_info["person_id"] =  wq_discuss_info[4];					--发送人ID
		ssdb_info["class_id"] =  wq_discuss_info[6];					--发送人ID
		ssdb_info["person_name"] = wq_discuss_info[8];				--发送人姓名
		ssdb_info["identity_id"] = wq_discuss_info[10];					--身份ID
		ssdb_info["avatar_url"] = wq_discuss_info[12];					--班级DI
		ssdb_info["content_info"] = wq_discuss_info[14];				--发送内容
		ssdb_info["create_time"] = wq_discuss_info[16];					--发送时间
		table.insert(wqDiscussArray, ssdb_info);
	end
	--------------------------------------------------------------------------------------------------------------------------------------------------------
	local wqDiscussListJson = {};
	wqDiscussListJson.success= true;
	wqDiscussListJson.list = wqDiscussArray;
	ssdb_db:set_keepalive(0,v_pool_size);
	mysql_db:set_keepalive(0,v_pool_size);
	return wqDiscussListJson;
end
function _WqDiscuss:decodeURI(s)
    s = string.gsub(s, '%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
    return s
end
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- 返回_GameModel对象
return _WqDiscuss;
