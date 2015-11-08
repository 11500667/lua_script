--[[
	局部函数：错题本的DAO类
]]
local _WrongQuestion = {};
--[[
	局部函数：错题录入错题本
	ssdb_info：错题记录信息
]]
local log = require("social.common.log")
log.outfile = "/tmp/yxx.log";
log.level="trace"
function _WrongQuestion:wq_save(ssdb_info)
	local dbUtil = require "yxx.wrong_question_book.util.DbUtil";
	local ssdb_db = dbUtil:getSSDb();
	local mysql_db = dbUtil:getMysqlDb();
	local wq_id = ssdb_db:incr("wrong_question_book_pk");--生成主键ID
	ssdb_db:set("wrong_question_exsit_v34_"..ssdb_info["student_id"].."_"..ssdb_info["question_id"],wq_id[1]);--一个学生对同一道题重复答错时，不进入错题本
	--保存错题本（ssdb）
	ssdb_db:multi_hset("wrong_question_book_v34_"..wq_id[1],ssdb_info);
	--保存错题本（mysql）
	mysql_db:query("INSERT INTO t_wrong_question_book("..
								  "wq_id,"..			--错题本ID
								  "student_id,"	..		--学生ID
								  "class_id,"..			--班级id
								  "subject_id,"..		--学段学科id
								  "create_source,"..	--错题来源（作业、同步练习、班级错题本）
								  "create_time,"..		--创建时间
								  "stu_answer,"..		--学生的答案
								  "cause_content,"..	--错题原因(技巧类、态度类、知识点掌握不好)
								  "question_id,"..		--班级错题率id
								  "priority_levels,"..	--错题优先级
								  "question_answer,"..	--是否是精品
								  "question_type_name,".. --试题类型
								  "nd_name,"..			--难度
								  "nd_star,"..			--难度星星
								  "file_id,"..			--文件ID
								  "knowledge_point_ids,"..			--知识点IDs
								  "knowledge_point_codes,"..			--知识点IDs
								  "knowledge_point_names,"..			--知识点NAMEs
								  "is_delete"..			--1：错题我会了   0：错题我不会
								  ")"..
						" VALUES ( "..
									wq_id[1]..","..
									ssdb_info["student_id"]..","..
									ssdb_info["class_id"]..","..
									ssdb_info["subject_id"]..", "..
									ssdb_info["create_source"]..", "..
									"'"..ssdb_info["create_time"].."',"..
									"'"..ssdb_info["stu_answer"].."',"..
									ssdb_info["cause_content"]..","..
									ssdb_info["question_id"]..","..
									ssdb_info["priority_levels"]..","..
									"'"..ssdb_info["question_answer"].."',"..
									"'"..ssdb_info["question_type_name"].."',"..
									"'"..ssdb_info["nd_name"].."',"..
									"'"..ssdb_info["nd_star"].."',"..
									"'"..ssdb_info["file_id"].."',"..
									"'"..ssdb_info["knowledge_point_ids"].."',"..
									"'"..ssdb_info["knowledge_point_codes"].."',"..
									"'"..ssdb_info["knowledge_point_names"].."',"..
									ssdb_info["is_delete"]..");");
	------------------------------------------------------------------------------------------------------------------------------------------------------
	ssdb_db:set_keepalive(0,v_pool_size);
	mysql_db:set_keepalive(0,v_pool_size);
end

function _WrongQuestion:zg_wq_save(ssdb_info)
    local dbUtil = require "yxx.wrong_question_book.util.DbUtil";
    local ssdb_db = dbUtil:getSSDb();
    local mysql_db = dbUtil:getMysqlDb();
    local wq_id = ssdb_db:incr("wrong_question_book_pk");--生成主键ID
    ssdb_db:set("wrong_question_exsit_v34_"..ssdb_info["student_id"].."_"..ssdb_info["question_id"],wq_id[1]);--一个学生对同一道题重复答错时，不进入错题本
    --保存错题本（ssdb）
    ssdb_db:multi_hset("wrong_question_book_v34_"..wq_id[1],ssdb_info);
    --保存错题本（mysql）
    mysql_db:query("INSERT INTO t_wrong_question_book("..
            "wq_id,"..			--错题本ID
            "student_id,"	..		--学生ID
            "class_id,"..			--班级id
            "subject_id,"..		--学段学科id
            "create_source,"..	--错题来源（作业、同步练习、班级错题本）
            "create_time,"..		--创建时间
            "stu_answer,"..		--学生的答案
            "cause_content,"..	--错题原因(技巧类、态度类、知识点掌握不好)
            "question_id,"..		--班级错题率id
            "priority_levels,"..	--错题优先级
            "question_answer,"..	--是否是精品
            "question_type_name,".. --试题类型
            "nd_name,"..			--难度
            "nd_star,"..			--难度星星
            "file_id,"..			--文件ID
            "knowledge_point_ids,"..			--知识点IDs
            "knowledge_point_codes,"..			--知识点IDs
            "knowledge_point_names,"..			--知识点NAMEs
            "zy_id,"..			--作业ID
            "is_delete"..			--1：错题我会了   0：错题我不会
            ")"..
            " VALUES ( "..
            wq_id[1]..","..
            ssdb_info["student_id"]..","..
            ssdb_info["class_id"]..","..
            ssdb_info["subject_id"]..", "..
            ssdb_info["create_source"]..", "..
            "'"..ssdb_info["create_time"].."',"..
            "'"..ssdb_info["stu_answer"].."',"..
            ssdb_info["cause_content"]..","..
            ssdb_info["question_id"]..","..
            ssdb_info["priority_levels"]..","..
            "'"..ssdb_info["question_answer"].."',"..
            "'"..ssdb_info["question_type_name"].."',"..
            "'"..ssdb_info["nd_name"].."',"..
            "'"..ssdb_info["nd_star"].."',"..
            "'"..ssdb_info["file_id"].."',"..
            "'"..ssdb_info["knowledge_point_ids"].."',"..
            "'"..ssdb_info["knowledge_point_codes"].."',"..
            "'"..ssdb_info["knowledge_point_names"].."',"..
            ssdb_info["zy_id"]..","..
            ssdb_info["is_delete"]..");");
    ------------------------------------------------------------------------------------------------------------------------------------------------------
    ssdb_db:set_keepalive(0,v_pool_size);
    mysql_db:set_keepalive(0,v_pool_size);
end
--[[
	局部函数：学生是否做过此题
	student_id：学生ID
	question_id：问题ID
]]

function _WrongQuestion:wq_is_exsit(student_id,question_id)
	local dbUtil = require "yxx.wrong_question_book.util.DbUtil";
	local ssdb_db = dbUtil:getSSDb();
	local is_exsit = ssdb_db:exists("wrong_question_exsit_v34_"..student_id.."_"..question_id);--判断错题存在否
	ssdb_db:set_keepalive(0,v_pool_size);
	return is_exsit
end

--[[
	局部函数：班级针对此题的作答情况
	class_id：班级ID
	question_id：试题ID
	is_wrong_right：对/错   1:对   2:错
]]
function _WrongQuestion:wq_rate(class_id,question_id,subject_id,knowledge_point_ids,knowledge_point_codes,question_type_id,question_type_name,nd_id,nd_name,is_wrong_right)
	--------------------------------------------------------------------------------------------------------------------------------------------------------
	--初始化
	local dbUtil = require "yxx.wrong_question_book.util.DbUtil";
	local ssdb_db = dbUtil:getSSDb();
	local mysql_db = dbUtil:getMysqlDb();
	local wrong_count = 0;
	local right_count = 0;
	local is_edit = 0;
	--------------------------------------------------------------------------------------------------------------------------------------------------------
	--获得本班针对此题的作答情况
	local wrong_question_info = ssdb_db:multi_hget("wrong_question_rate_v34_"..class_id.."_"..question_id, "wrong_count","right_count");
    ngx.log(ngx.ERR,"###########"..is_wrong_right.."##############");
    if #wrong_question_info > 0 and wrong_question_info[1] ~= "ok" then
		if is_wrong_right == 0 then
			right_count = tonumber(wrong_question_info[4]);
			wrong_count = tonumber(wrong_question_info[2]) + 1;
		else
			right_count = tonumber(wrong_question_info[4])+ 1;
			wrong_count = tonumber(wrong_question_info[2]);
		end
		is_edit = 1;
		--ngx.log(ngx.ERR, "@@@@@@@@@@@@@@"..wrong_question_info[2].."_"..wrong_question_info[4].."@@@@@@@@@");
	else
		if is_wrong_right == 0 then
			wrong_count = 1;
		else
			right_count = 1;
		end
	end
	--------------------------------------------------------------------------------------------------------------------------------------------------------
	--存在就更新 不存在就插入 由于nosql与mysql数据是保存一致的，所以拿缓存时间判断mysql中是否存在
	if is_edit == 1 then
		if is_wrong_right == 0 then
			--如果是错题时更新，那么记录最后错题的时间，否则不记录错题时间（本功能为班级错题本列表的按时间倒序排序）
			mysql_db:query("update t_class_wrong_question_rate set right_count="..right_count..",wrong_count="..wrong_count..",last_wrong_time='"..ngx.localtime().."' where class_id="..class_id.." and question_id="..question_id.." and subject_id="..subject_id);
		else
			mysql_db:query("update t_class_wrong_question_rate set right_count="..right_count..",wrong_count="..wrong_count.." where class_id="..class_id.." and question_id="..question_id.." and subject_id="..subject_id);
		end
    else

       -- ngx.log(ngx.ERR,"insert into t_class_wrong_question_rate(class_id,question_id,subject_id,right_count,wrong_count,last_wrong_time,knowledge_point_ids,knowledge_point_codes,question_type_id,question_type_name,nd_id,nd_name) values ("..class_id..","..question_id..","..subject_id..","..right_count..","..wrong_count..",'"..ngx.localtime().."','"..knowledge_point_ids.."','"..knowledge_point_codes.."',"..question_type_id..",'"..question_type_name.."',"..nd_id..","..ngx.quote_sql_str(nd_name)..");")
		mysql_db:query("insert into t_class_wrong_question_rate(class_id,question_id,subject_id,right_count,wrong_count,last_wrong_time,knowledge_point_ids,knowledge_point_codes,question_type_id,question_type_name,nd_id,nd_name) values ("..class_id..","..question_id..","..subject_id..","..right_count..","..wrong_count..",'"..ngx.localtime().."','"..knowledge_point_ids.."','"..knowledge_point_codes.."',"..question_type_id..",'"..question_type_name.."',"..nd_id..",'"..nd_name.."');");
    end

	--------------------------------------------------------------------------------------------------------------------------------------------------------
	--更新班级针对此题的作答情况
	local table={};
	table["right_count"] = right_count;
	table["wrong_count"] = wrong_count;
	ssdb_db:multi_hset("wrong_question_rate_v34_"..class_id.."_"..question_id,table);
	--------------------------------------------------------------------------------------------------------------------------------------------------------
	ssdb_db:set_keepalive(0,v_pool_size);
	mysql_db:set_keepalive(0,v_pool_size);
end
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
---------------------------------------------------------------------------
function _WrongQuestion:person_wq_list(student_id,subject_id,create_source,cause_content,knowledge_point_code,is_include_know,sort_type,sort_num,page_size,page_number)
	--------------------------------------------------------------------------------------------------------------------------------------------------------
	--初始化变量
	local dbUtil = require "yxx.wrong_question_book.util.DbUtil";
	local ssdb_db = dbUtil:getSSDb();
	local mysql_db = dbUtil:getMysqlDb();
	local total_row	= 0;
	local total_page = 0;
	local query_order = "";
	local wqbArray  = {};
	local query_condition = " and t1.student_id="..student_id;
	if subject_id ~= -1 then
		query_condition = query_condition.." and t1.subject_id="..subject_id;
	end
	if create_source ~= -1 then
		query_condition = query_condition.." and t1.create_source="..create_source;
	end
	if cause_content ~= -1 then
		query_condition = query_condition.." and t1.cause_content="..cause_content;
	end
	if knowledge_point_code ~= -1 then
        query_condition = query_condition.." and (t1.knowledge_point_codes like '%,"..knowledge_point_code..",%' or t1.knowledge_point_codes ='') ";
    end
	if is_include_know == 0 then
		query_condition = query_condition.." and is_delete=0";--is_delete  1：我会了   0：我不会
	end
	if sort_type == 1 then
		if sort_num == 1 then
			query_order = " order by t1.wq_id desc";
		else
			query_order = " order by t1.wq_id asc";
		end
	end
	if sort_type == 2 then
		if sort_num == 1 then
			query_order = " order by wq_rate desc";
		else
			query_order = " order by wq_rate asc";
		end
	end
	--------------------------------------------------------------------------------------------------------------------------------------------------------
	--获得我的错题总数
	local total_rows_sql = "SELECT COUNT(1) AS TOTAL_ROW FROM T_WRONG_QUESTION_BOOK t1 WHERE 1=1 "..query_condition..";";
    local total_query, err, errno, sqlstate = mysql_db:query(total_rows_sql);
	if not total_query then
		return {success=false, info="查询数据出错。"};
	end
	total_row = total_query[1]["TOTAL_ROW"];
	total_page = math.floor((total_row+page_size-1)/page_size);
	local offset = page_size*page_number-page_size;
	local limit  = page_size;
	local query_sql = "select t1.wq_id,truncate(t2.wrong_count/(t2.right_count+t2.wrong_count),2) as wq_rate from t_wrong_question_book t1 left join t_class_wrong_question_rate t2 on t1.class_id = t2.class_id and t1.question_id = t2.question_id where 1=1 "..query_condition.. query_order .." LIMIT " .. offset .. "," .. limit .. ";";
	--ngx.log(ngx.ERR, "@@@@@@@@@@@@@@"..query_sql.."@@@@@@@@@");
	local rows, err, errno, sqlstate = mysql_db:query(query_sql);
	if not rows then
		ngx.print("{\"success\":\"false\",\"info\":\"查询数据出错。\"}");
		return;
	end
	--------------------------------------------------------------------------------------------------------------------------------------------------------
	for i=1,#rows do
		local wqbs_info = ssdb_db:multi_hget("wrong_question_book_v34_"..rows[i]["wq_id"],"student_id","class_id","subject_id","create_source","create_time","stu_answer","cause_content","priority_levels","question_id","question_answer","question_type_name","nd_name","nd_star","file_id","knowledge_point_ids","knowledge_point_names","is_delete","zy_id")
		local question_id  = wqbs_info[22];
		local ssdb_info = {};
		ssdb_info["wq_id"]= rows[i]["wq_id"];									--错题本ID
		ssdb_info["student_id"]= wqbs_info[2];									--学生ID
		ssdb_info["class_id"] =  wqbs_info[4];									--班级ID
		ssdb_info["subject_id"] = wqbs_info[6];									--学科
		ssdb_info["create_source"] = wqbs_info[8];								--知识点
		ssdb_info["create_time"] = wqbs_info[10];								--错题来源
		ssdb_info["stu_answer"] = wqbs_info[12];								--错题时间
		ssdb_info["cause_content"] = wqbs_info[14];								--学生答案
		ssdb_info["priority_levels"] = wqbs_info[16];							--错题等级
		ssdb_info["question_id"] = wqbs_info[18];								--试题ID
		ssdb_info["question_answer"] = wqbs_info[20];							--错题优先级
		ssdb_info["question_type_name"] = wqbs_info[22];						--试题类型名称
		ssdb_info["nd_name"] = wqbs_info[24];  									--难度名称
		ssdb_info["nd_star"] = wqbs_info[26];            						--难度星级
		ssdb_info["file_id"] =wqbs_info[28];           							--用于获取文件路径的guid
		ssdb_info["knowledge_point_ids"] =wqbs_info[30]; 						--知识点ID
		ssdb_info["knowledge_point_names"] =wqbs_info[32]; 						--知识点名称
		ssdb_info["is_delete"] =wqbs_info[34]; 									--会/不会
        ssdb_info["zy_id"] =wqbs_info[36];
		ssdb_info["wq_rate"] = rows[i]["wq_rate"]*100;								--错题率
		table.insert(wqbArray, ssdb_info);
	end
	--------------------------------------------------------------------------------------------------------------------------------------------------------
	local wqbListJson = {};
	wqbListJson.success    = true;
	wqbListJson.total_row   = total_row;
	wqbListJson.total_page  = total_page;
	wqbListJson.page_number = page_number;
	wqbListJson.page_size   = page_size;
	wqbListJson.list = wqbArray;
	ssdb_db:set_keepalive(0,v_pool_size);
	mysql_db:set_keepalive(0,v_pool_size);
	return wqbListJson;
end
--------------------------------------------------------------------------------------------------------------------------------------------------------
--[[
	局部函数：班级错题列表
	按学科查询方式：
	class_id:班级ID
	subject_id：学科ID
	sort_type：排序类型(1、录入时间 2:错题率)
	sort_num：升/降序
	pageSize:每页记录数
	pageNumber：页数
]]
---------------------------------------------------------------------------
function _WrongQuestion:class_wq_list(class_id,subject_id,knowledge_point_code,question_type_id,nd_id,sort_type,sort_num,page_size,page_number)
	--------------------------------------------------------------------------------------------------------------------------------------------------------
	--初始化变量
	local dbUtil = require "yxx.wrong_question_book.util.DbUtil";
	local ssdb_db = dbUtil:getSSDb();
	local mysql_db = dbUtil:getMysqlDb();
	local total_row	= 0;
	local total_page = 0;
	local query_order = "";
	local query_condition = " AND wrong_count>0 ";
	if class_id ~= '-1' and class_id ~= -1 and class_id ~= '' and #class_id>0 then
		query_condition = query_condition.." AND class_id in ("..class_id..") ";
	end
	if subject_id ~= -1 then
		query_condition = query_condition.." AND subject_id="..subject_id.." ";
	end
	if question_type_id ~= nil and question_type_id ~= -1 then
		query_condition = query_condition.." AND question_type_id="..question_type_id.." ";
	end
	if nd_id ~= nil and nd_id ~= -1 then
		query_condition = query_condition.." AND nd_id="..nd_id.." ";
	end
	if knowledge_point_code ~= nil and knowledge_point_code ~= -1 then
        query_condition = query_condition.." and (knowledge_point_codes like '%,"..knowledge_point_code..",%' or knowledge_point_codes ='') ";
	end

	if sort_type == 1 then
		if sort_num == 1 then
			query_order = " ORDER BY last_wrong_time DESC";
		else
			query_order = " ORDER BY last_wrong_time ASC";
		end
	end
	if sort_type == 2 then
		if sort_num == 1 then
			query_order = " ORDER BY wq_rate DESC";
		else
			query_order = " ORDER BY wq_rate ASC";
		end
	end
	--------------------------------------------------------------------------------------------------------------------------------------------------------
	--获得我的错题总数
	local total_rows_sql = "SELECT count(1) as TOTAL_ROW from t_class_wrong_question_rate where 1=1 "..query_condition..";";
    local total_query, err, errno, sqlstate = mysql_db:query(total_rows_sql);
	if not total_query then
		return {success=false, info="查询数据出错。"};
	end
	total_row = total_query[1]["TOTAL_ROW"];
	total_page = math.floor((total_row+page_size-1)/page_size);
	local offset = page_size*page_number-page_size;
	local limit  = page_size;
	local query_sql = "SELECT question_id,truncate(wrong_count / (right_count + wrong_count),2) AS wq_rate,last_wrong_time as create_time,subject_id,class_id,nd_id,knowledge_point_codes from t_class_wrong_question_rate where 1=1"..query_condition.. query_order .." limit " .. offset .. "," .. limit .. ";";
	--ngx.log(ngx.ERR, "@@@@@@@@@@@@@@"..query_sql.."@@@@@@@@@");
	local rows, err, errno, sqlstate = mysql_db:query(query_sql);
	if not rows then
		ngx.print("{\"success\":\"false\",\"info\":\"查询数据出错。\"}");
		return;
	end
	--------------------------------------------------------------------------------------------------------------------------------------------------------
	local wqbArray = {}
	for i=1,#rows do
		local question_id = rows[i]["question_id"];
		local questionBase = require "question.model.QuestionBase";
		local question_info = questionBase:getQuesDetailByIdChar(question_id);
		local ssdb_info = {};
		ssdb_info["question_id"] = rows[i]["question_id"];									--试题ID
		ssdb_info["question_answer"]= question_info["question_answer"];						--试题答案
		ssdb_info["question_type_name"] = question_info["question_type_name"];				--试题类型名称
		ssdb_info["nd_name"] = question_info["nd_name"];  									--难度名称
		ssdb_info["nd_star"] = question_info["nd_star"];  									--难度星级
		ssdb_info["file_id"] = question_info["file_id"];									--用于获取文件路径的guid
		ssdb_info["knowledge_point_ids"] = question_info["knowledge_point_ids"];			--知识点ID
		ssdb_info["knowledge_point_names"] = question_info["knowledge_point_names"];		--知识点名称
		ssdb_info["wq_rate"] = rows[i]["wq_rate"]*100;										--错题率
		ssdb_info["create_time"] = rows[i]["create_time"];									--错题时间
		ssdb_info["subject_id"] = rows[i]["subject_id"];									--学科ID
		ssdb_info["class_id"] = rows[i]["class_id"];										--班级ID
		ssdb_info["nd_id"] = rows[i]["nd_id"];												--试题难度
		ssdb_info["knowledge_point_codes"] = rows[i]["knowledge_point_codes"];				--知识点CODE
		table.insert(wqbArray, ssdb_info);
	end
	--------------------------------------------------------------------------------------------------------------------------------------------------------
	local wqbListJson = {};
	wqbListJson.success    = true;
	wqbListJson.total_row   = total_row;
	wqbListJson.total_page  = total_page;
	wqbListJson.page_number = page_number;
	wqbListJson.page_size   = page_size;
	wqbListJson.list = wqbArray;
	ssdb_db:set_keepalive(0,v_pool_size);
	mysql_db:set_keepalive(0,v_pool_size);
	return wqbListJson;
end
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[
	局部函数：错题编辑
	wq_id：错题ID
	create_source:错题来源
	cause_content：错题原因
	is_delete：会/不会
]]
function _WrongQuestion:wq_edit(wq_id,create_source,cause_content,is_delete)
	local dbUtil = require "yxx.wrong_question_book.util.DbUtil";
	local ssdb_db = dbUtil:getSSDb();
	local mysql_db = dbUtil:getMysqlDb();
	--保存错题本（ssdb）
    if is_delete ~= nil then
        ssdb_db:multi_hset("wrong_question_book_v34_"..wq_id,"create_source",create_source,"cause_content",cause_content,"is_delete",is_delete);
        mysql_db:query("update t_wrong_question_book set create_source="..create_source..",cause_content="..cause_content..",is_delete="..is_delete.." where wq_id="..wq_id..";");
    else
        ssdb_db:multi_hset("wrong_question_book_v34_"..wq_id,"create_source",create_source,"cause_content",cause_content);
        mysql_db:query("update t_wrong_question_book set create_source="..create_source..",cause_content="..cause_content.." where wq_id="..wq_id..";");
    end
	--保存错题本（mysql）
	------------------------------------------------------------------------------------------------------------------------------------------------------
	ssdb_db:set_keepalive(0,v_pool_size);
	mysql_db:set_keepalive(0,v_pool_size);
end
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[
	局部函数：如果学生多次错题,那么把错题记录修改为有效状态。
	student_id：学生ID
	question_id：试题ID
]]
function _WrongQuestion:more_once_wq(student_id,question_id,stu_answer)
	local dbUtil = require "yxx.wrong_question_book.util.DbUtil";
	local ssdb_db = dbUtil:getSSDb();
	local mysql_db = dbUtil:getMysqlDb();
	local wq_id = ssdb_db:get("wrong_question_exsit_v34_"..student_id.."_"..question_id);
	--这里不需判断wq_id是否为nil，这里可定不为空因为在ACT中进行了判断。
	ssdb_db:hset("wrong_question_book_v34_"..wq_id[1], "create_time", ngx.localtime(),"stu_answer", stu_answer);
	--保存错题本（mysql）
	mysql_db:query("update t_wrong_question_book set is_delete=0,".."create_time='"..ngx.localtime().."',".."stu_answer="..stu_answer.." where student_id="..student_id.." and question_id="..question_id..";");
	------------------------------------------------------------------------------------------------------------------------------------------------------
	ssdb_db:set_keepalive(0,v_pool_size);
	mysql_db:set_keepalive(0,v_pool_size);
end
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--[[
	局部函数：错题移除
	student_id：student_id
	question_id:试题ID
	wq_id：错题本id
]]
function _WrongQuestion:wq_delete(student_id,question_id,wq_id)
	local dbUtil = require "yxx.wrong_question_book.util.DbUtil";
	local mysql_db = dbUtil:getMysqlDb();
	local ssdb_db = dbUtil:getSSDb();
	--删除本人错题的记录表，以便下次再做错此题，依然进入错题本。
	ssdb_db:del("wrong_question_exsit_v34_"..student_id.."_"..question_id);
	--删除错题本（mysql）
	mysql_db:query("update wrong_question_book set is_delete=1 where wq_id="..wq_id..";");
	------------------------------------------------------------------------------------------------------------------------------------------------------
	ssdb_db:set_keepalive(0,v_pool_size);
	mysql_db:set_keepalive(0,v_pool_size);
end
--------------------------------------------------------------------------------------------------------------------------------------------------------
--[[
	局部函数：做错的学生列表
	question_id:试题ID
	class_id:班级
]]
function _WrongQuestion:wq_all_stu_list(question_id,class_ids)
	--初始化变量
	local dbUtil = require "yxx.wrong_question_book.util.DbUtil";
	local pseronUtil = require "base.person.model.PersonInfoModel";
	local studentModel = require "base.student.model.Student";
	local ssdb_db = dbUtil:getSSDb();
	local mysql_db = dbUtil:getMysqlDb();
	local query_condition = " AND question_id="..question_id;
	if class_id ~= -1 then
		query_condition = query_condition.." AND class_id in ("..class_ids..")";
	end
	--------------------------------------------------------------------------------------------------------------------------------------------------------
	local query_sql = "select wq_id from t_wrong_question_book where 1=1"..query_condition.." order by create_time desc;";
	local rows, err, errno, sqlstate = mysql_db:query(query_sql);
	if not rows then
		ngx.print("{\"success\":\"false\",\"info\":\"查询数据出错。\"}");
		return;
	end
	local stuArray = {};
	--------------------------------------------------------------------------------------------------------------------------------------------------------
	for i=1,#rows do
		local wqbs_info = ssdb_db:multi_hget("wrong_question_book_v34_"..rows[i]["wq_id"],"student_id","class_id","stu_answer","create_time")
		local ssdb_info = {};
		ssdb_info["wq_id"]= rows[i]["wq_id"];									--错题本ID
		ssdb_info["student_id"]= wqbs_info[2];									--学生ID
		ssdb_info["student_name"] = pseronUtil:getPersonName(wqbs_info[2],6)	--学生NAME
		ssdb_info["class_id"] =  wqbs_info[4];									--班级ID
		local record = studentModel: getByIdAndIdentity(wqbs_info[2], 6);		
		ssdb_info["class_name"] = record["class_name"];							--班级名称
		ssdb_info["stu_answer"] = wqbs_info[6];									--学科
		ssdb_info["create_time"] = wqbs_info[8];								--错题时间
		table.insert(stuArray, ssdb_info);
	end
	--------------------------------------------------------------------------------------------------------------------------------------------------------
	local studentListJson = {};
	studentListJson.success    = true;
	studentListJson.list = stuArray;
	ssdb_db:set_keepalive(0,v_pool_size);
	mysql_db:set_keepalive(0,v_pool_size);
	return studentListJson;
end
--------------------------------------------------------------------------------------------------------------------------------------------------------
--[[
	局部函数：教师解答推荐3道试题
	knowledge_point_code：知识点
	nd_id:难度
]]
function _WrongQuestion:recommend_question(knowledge_point_code,nd_id)
    local dbUtil = require "yxx.tool.DbUtil";
	local cjson = require "cjson";
	local mysql_db = dbUtil:getMysqlDb();
	local query_sql = "select ID,JSON_QUESTION,JSON_ANSWER from t_tk_question_info where kg_zg=1 and question_difficult_id="..nd_id.." and STRUCTURE_ID_INT="..knowledge_point_code.." and JSON_ANSWER is not null and JSON_QUESTION is not null ORDER BY ID asc LIMIT 3";
	local rows, err, errno, sqlstate = mysql_db:query(query_sql);
	if not rows then
		ngx.print("{\"success\":\"false\",\"info\":\"查询数据出错。\"}");
		return;
	end
	--------------------------------------------------------------------------------------------------------------------------------------------------------
	local recommendQuestionArray = {}
	for i=1,#rows do
		local JSON_QUESTION = rows[i]["JSON_QUESTION"];
		local JSON_ANSWER = rows[i]["JSON_ANSWER"];
		local question_info = ngx.decode_base64(JSON_QUESTION);
		local question_json = cjson.decode(question_info);
		local question_answer_info = ngx.decode_base64(JSON_ANSWER);
		local question_answer_json = question_answer_info;
		local ssdb_info = {};
		ssdb_info["id"] = rows[i]["ID"];													--试题ID
		ssdb_info["file_id"] = question_json["t_id"];										--试题的文件ID
		ssdb_info["question_type_name"] = question_json["qt_name"];							--试题类型名称
		ssdb_info["nd_star"] = question_json["nd_star"];  									--难度星级
		ssdb_info["create_time"] = question_json["create_time"];  							--创建时间
		ssdb_info["knowledge_point_name"] = question_json["zsd"];  							--知识点名称
		ssdb_info["question_answer"] = question_answer_json["answer"];  					--试题答案
		table.insert(recommendQuestionArray, ssdb_info);
	end
	local recommendQuestionJson = {};
	recommendQuestionJson.success = true;
	recommendQuestionJson.list = recommendQuestionArray;
	mysql_db:set_keepalive(0,v_pool_size);
	return recommendQuestionJson;
end

--------------------------------------------------------------------------------------------------------------------------------------------------------
--[[
	局部函数：学生获得教师推荐的试题
	question_ids：试题IDs   id1,id2,id3
]]
function _WrongQuestion:recommend_question_by_ids(question_ids)
    local dbUtil = require "yxx.tool.DbUtil";
	local cjson = require "cjson";
	local mysql_db = dbUtil:getMysqlDb();
	local query_sql = "select ID,JSON_QUESTION,JSON_ANSWER from t_tk_question_info where ID in("..question_ids..")";
	local rows, err, errno, sqlstate = mysql_db:query(query_sql);
	if not rows then
		ngx.print("{\"success\":\"false\",\"info\":\"查询数据出错。\"}");
		return;
	end
	--------------------------------------------------------------------------------------------------------------------------------------------------------
	local recommendQuestionArray = {}
	for i=1,#rows do
		local JSON_QUESTION = rows[i]["JSON_QUESTION"];
		local JSON_ANSWER = rows[i]["JSON_ANSWER"];
		local question_info = ngx.decode_base64(JSON_QUESTION);
		local question_json = cjson.decode(question_info);
		local question_answer_info = ngx.decode_base64(JSON_ANSWER);
		local question_answer_json = question_answer_info;
		local ssdb_info = {};
		ssdb_info["id"] = rows[i]["ID"];													--试题ID
		ssdb_info["file_id"] = question_json["t_id"];										--试题的文件ID
		ssdb_info["question_type_name"] = question_json["qt_name"];							--试题类型名称
		ssdb_info["nd_star"] = question_json["nd_star"];  									--难度星级
		ssdb_info["create_time"] = question_json["create_time"];  							--创建时间
		ssdb_info["knowledge_point_name"] = question_json["zsd"];  							--知识点名称
		ssdb_info["question_answer"] = question_answer_json["answer"];  					--试题答案
		table.insert(recommendQuestionArray, ssdb_info);
	end
	local recommendQuestionJson = {};
	recommendQuestionJson.success = true;
	recommendQuestionJson.list = recommendQuestionArray;
	mysql_db:set_keepalive(0,v_pool_size);
	return recommendQuestionJson;
end

--[[
	局部函数：教师对试题讲解
	question_ids：试题IDs   id1,id2,id3
]]
function _WrongQuestion:addQuestionAnswer(class_id,teacher_id,question_id,content,t_target,teacher_id,tj_question_id)
    local dbUtil = require "yxx.tool.DbUtil";
    local mysql_db = dbUtil:getMysqlDb();
    local create_time = os.date("%Y-%m-%d %H:%M:%S");
    local quote = ngx.quote_sql_str;
    local select_sql = "select id from t_question_teacher_answer where teacher_id="..teacher_id.." and question_id = "..question_id.." and dtype = 1";
    local hdzy_res = mysql_db:query(select_sql)
    if #hdzy_res ~= 0 then
        local update_sql = "update t_question_teacher_answer set content = '"..content.."' where id = "..hdzy_res[1]["id"].."";
        mysql_db:query(update_sql);
    else
        if content ~= "" then
            local add_sql = "INSERT INTO t_question_teacher_answer(class_id,teacher_id,question_id,content,dtype,file_path,create_time) VALUES ("..ngx.quote_sql_str(class_id)..","..teacher_id..","..question_id..",'"..content.."',1,'','"..create_time.."')";
            mysql_db:query(add_sql);
        end
    end

    local delete_sql = "delete from t_question_teacher_answer where teacher_id="..teacher_id.." and question_id = "..question_id.." and dtype = 2";
    mysql_db:query(delete_sql);
    for i=1,#t_target do
        local file_path = t_target[i].file_path
        local file_name = t_target[i].file_name
        local add_sql2 = "INSERT INTO t_question_teacher_answer(class_id,teacher_id,question_id,content,dtype,file_path,create_time) VALUES ("..ngx.quote_sql_str(class_id)..","..teacher_id..","..question_id..","..quote(file_name)..",2,"..quote(file_path)..",'"..create_time.."')";
        mysql_db:query(add_sql2);
    end

    --推荐试题
    local delete_sql = "delete from t_question_teacher_answer where teacher_id="..teacher_id.." and question_id = "..question_id.." and dtype = 3";
    mysql_db:query(delete_sql);
    for i=1,#tj_question_id do
        local tj_question = tj_question_id[i].question_id
        local add_sql2 = "INSERT INTO t_question_teacher_answer(class_id,teacher_id,question_id,dtype,create_time,tj_question_id) VALUES ("..ngx.quote_sql_str(class_id)..","..teacher_id..","..question_id..",3,'"..create_time.."',"..tj_question..")";
        mysql_db:query(add_sql2);
    end
end

--[[
	局部函数：教师对试题讲解
	question_ids：试题IDs   id1,id2,id3
]]
function _WrongQuestion:getClassIdsByClassTab(class_tab)
    local class_ids = ","
    for i=1,#class_tab do
        class_ids = class_ids..class_tab[i].class_id..","
    end
    return class_ids;
end
-- 返回_WrongQuestion对象
return _WrongQuestion;