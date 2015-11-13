

local DBUtil   = require "common.DBUtil";
local _QuestionModel = {};
local cjson = require "cjson"
local p_myTs      = require "resty.TS"
local currentTS = p_myTs.getTs();
local CacheUtil = require "common.CacheUtil";
local quote = ngx.quote_sql_str;
local SSDBUtil = require "common.SSDBUtil";


-- -----------------------------------------------------------------------------------
-- 描述：试题后台管理 -> 查询版本
-- 作者：刘全锋
-- 日期：2015年8月27日
-- 参数：product_id	产品id
-- -----------------------------------------------------------------------------------


local function querySchemeByProduct(product_id,zsd)

	local db = DBUtil: getDb();

	local sql = "select t2.scheme_id,t2.scheme_name,t2.type_id from t_resource_product_scheme as t1 inner join t_resource_scheme as t2 on t1.scheme_id = t2.scheme_id where t1.product_id ="..product_id.." and t1.b_use=1  and t2.client_id = 1";

	if zsd == "isTrue" then
		sql = sql.." and t2.type_id in(1,2)";
	else
		sql = sql.." and t2.type_id =1";
	end

	sql = sql.." order by t1.sort_id ";


	local res, err, errno, sqlstate = db:query(sql);
        
	if not res then
	    return {success=false, info="查询数据出错！"};
	end

	local resultListObj = {};

	for i=1, #res do
	    local record = {};
	    record.scheme_id       = res[i]["scheme_id"];
	    record.scheme_name     = res[i]["scheme_name"];
	    table.insert(resultListObj, record);
	end

	
	local resultJsonObj		= {};
	resultJsonObj.success 		= 	true;
	resultJsonObj.scheme_list 	= 	resultListObj;

	DBUtil: keepDbAlive(db);
		
    return true,resultJsonObj;
end

_QuestionModel.querySchemeByProduct = querySchemeByProduct;


---------------------------------------------------------------------------
--[[
    局部函数：获取新的试题 T_TK_QUESTION_INFO 表的主键ID（从Redis中获取）
    作者： 刘全锋 2015-08-31
    返回值：number类型，新的试题记录的ID
]]
local function getNewRecordPK()
    -- 获取redis连接
    local cache = CacheUtil: getRedisConn();
    -- 获取T_TK_QUESTION_INFO表的新的主键
    local newPK = cache:incr("t_tk_question_info_pk");
    -- 将Redis连接归还连接池
    CacheUtil:keepConnAlive(cache);
    return newPK;
end

_QuestionModel.getNewRecordPK = getNewRecordPK;


-- -----------------------------------------------------------------------------------
-- 描述：试题后台管理 -> 试题复制
-- 作者：刘全锋
-- 日期：2015年8月28日
-- 参数：structure_ids_table	结构id数组(格式:{aaa,bbb,ccc})
-- 参数：question_ids_table		试题id数组（格式:{id:1,question_id_char:aaa},{id:2,question_id_char:bbb}）
-- 参数：oper_type				1复制	2移动
-- -----------------------------------------------------------------------------------

local function questionCopyOrMove(version_id,structure_ids_table,question_ids_table,op_type)

	local db = DBUtil: getDb();
	local cache = nil;

	for k,v in pairs(question_ids_table.list) do

		local sql = "SELECT id,question_id_char,question_title ,question_tips,question_type_id,question_difficult_id,create_person,group_id,down_count,ts,kg_zg,scheme_id_int,structure_id_int,json_question,json_answer,update_ts,structure_path,b_in_paper ,paper_id_int,b_delete,oper_type,check_status,check_msg,use_count,sort_id  FROM t_tk_question_info WHERE id = "..v.id;

		local res, err, errno, sqlstate = db:query(sql);
		
		if not res then
			return {success=false, info="查询数据出错！"};
		end

		local question_id_char			= res[1]["question_id_char"];
		local question_title			= res[1]["question_title"];
		local question_tips				= res[1]["question_tips"];
		local question_type_id			= res[1]["question_type_id"];
		local question_difficult_id		= res[1]["question_difficult_id"];
		local create_person				= res[1]["create_person"];
		local group_id					= res[1]["group_id"];
		local down_count				= res[1]["down_count"];
		if tostring(down_count)=="userdata: NULL" then
			down_count = 0
		end
		local ts						= currentTS;
		local kg_zg						= res[1]["kg_zg"];
		local scheme_id_int				= version_id;
		local json_answer				= res[1]["json_answer"];
		local update_ts					= currentTS;
		local b_in_paper				= res[1]["b_in_paper"];
		local paper_id_int				= res[1]["paper_id_int"];
		local b_delete					= res[1]["b_delete"];
		local oper_type					= res[1]["oper_type"];
		local check_status				= res[1]["check_status"];
		local check_msg					= res[1]["check_msg"];
		local use_count					= res[1]["use_count"];
		if tostring(use_count)=="userdata: NULL" then
			use_count = 0
		end
		local sort_id					= res[1]["sort_id"];
		for i=1, #structure_ids_table do

			cache = CacheUtil: getRedisConn();

			local structure_path_num	= structure_ids_table[i];--结构id

			--从缓存中取完整结构id
			local strucCode = cache:hget("t_resource_structure_" .. structure_path_num, "structure_code");


			local structure_path = "";

			--根据完整结构id取结构名称
			if strucCode ~= nil or strucCode ~= "" then
				local struccode_table = Split(strucCode,"_");
				for s=1, #struccode_table do
					local strucName = cache:hget("t_resource_structure_" .. struccode_table[s], "structure_name");
            		if s == 1 then
                		structure_path = strucName;
           			else
           			 	structure_path = structure_path .."->".. strucName;
                	end
				end
			else
				return false;
			end

			local json_question					= res[1]["json_question"];
			json_question_table					= cjson.decode(ngx.decode_base64(json_question));
			json_question_table.structure_id 	= structure_path_num;
			json_question_table.structure_path	= structure_path;
			local json_question_new 			= ngx.encode_base64(cjson.encode(json_question_table));

			local question_id = getNewRecordPK();

			local insertSql = "insert into t_tk_question_info (id,question_id_char,question_title ,question_tips,question_type_id,question_difficult_id,create_person,group_id,down_count,ts,kg_zg,scheme_id_int,structure_id_int,json_question,json_answer,update_ts,structure_path,b_in_paper ,paper_id_int,b_delete,oper_type,check_status,check_msg,use_count,sort_id) values("..question_id..","..quote(question_id_char)..","..quote(question_title)..","..quote(question_tips)..","..question_type_id..","..question_difficult_id..","..create_person..","..group_id..","..down_count..","..ts..","..kg_zg..","..scheme_id_int..","..structure_ids_table[i]..","..quote(json_question_new)..","..quote(json_answer)..","..update_ts..","..quote(structure_path)..","..b_in_paper..","..paper_id_int..","..b_delete..","..oper_type..","..check_status..","..quote(check_msg)..","..use_count..","..sort_id..")";

			local res, err, errno, sqlstate =db:query(insertSql);
			if not res then
				ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
				return false;
			end

			cache:hmset("question_"..question_id,"scheme_id_int",scheme_id_int,"json_question",json_question_new,"create_person",create_person,"question_id_char",question_id_char,"sort_id",sort_id,"json_answer",json_answer,"down_count",down_count,"b_delete",b_delete);
		end

		if op_type == 2 then
			local delSql = "update t_tk_question_info set b_delete=1,update_ts = "..currentTS.." where id = "..v.id
			local res, err, errno, sqlstate =db:query(delSql);
			if not res then
				ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
				return false;
			end
		end
	end

	CacheUtil:keepConnAlive(cache);
	DBUtil: keepDbAlive(db);

	return true;
end

_QuestionModel.questionCopyOrMove = questionCopyOrMove;


-- -----------------------------------------------------------------------------------
-- 描述：试题后台管理 -> 试题审核
-- 作者：刘全锋
-- 日期：2015年9月9日
-- 参数：question_id_table	id数组
-- 参数：check_type	1审核通过	3审核不通过
-- -----------------------------------------------------------------------------------

local function examineQuestion(question_id_table,check_type)

	local db = DBUtil: getDb();
	local ssdb = SSDBUtil:getDb();
	local cache = CacheUtil: getRedisConn();

	local update_ts					= currentTS;

	for s=1,#question_id_table do

		local question_id_char = question_id_table[s];

		if tonumber(check_type) == 1 then

			local qryOldZsdSql = "select t1.id,t1.structure_id_int,t1.json_question,t2.structure_name,t1.check_status,t1.group_id from t_tk_question_info t1 left join t_resource_structure t2 on t1.structure_id_int=t2.structure_id and t2.type_id=2 where t1.question_id_char="..quote(question_id_char).." and t1.b_delete=0 and  t1.group_id in (1,2) and t1.check_status <>3 ";

			local resultOldZsd = db:query(qryOldZsdSql);

			if not resultOldZsd then
				return false;
			end

			local strucStr = "";

			for i=1, #resultOldZsd do

				if tostring(resultOldZsd[i]["structure_name"]) ~=  "userdata: NULL" then

					if tonumber(resultOldZsd[i]["group_id"]) == 1 or tonumber(resultOldZsd[i]["check_status"]) == 2 then
						if strucStr == "" then
							strucStr   	=  resultOldZsd[i]["structure_name"];
						else
							if (string.find(","..strucStr..",",","..resultOldZsd[i]["structure_name"]..",")==nil) then
									strucStr   	=  strucStr .. "," .. resultOldZsd[i]["structure_name"];
							end
						end
					end
				end
				
			end


			for s=1, #resultOldZsd do

				if tonumber(resultOldZsd[s]["group_id"]) == 1 then
					local temId = resultOldZsd[s]["id"];
					local json_question		= resultOldZsd[s]["json_question"];
					local json_question_table					= cjson.decode(ngx.decode_base64(json_question));
					json_question_table.zsd	= strucStr;
					local json_question_new 			= ngx.encode_base64(cjson.encode(json_question_table));
					local updateStSql = "update t_tk_question_info set json_question="..quote(json_question_new).. ", update_ts="..currentTS.." where id="..temId;

					local updateResult = db:query(updateStSql);

					if not updateResult then
						return false;
					end

					cache:hmset("question_"..temId,"json_question",json_question_new);
				end
			end

			local sql = "SELECT id,question_id_char,question_title ,question_tips,question_type_id,question_difficult_id,create_person,group_id,down_count,ts,kg_zg,scheme_id_int,structure_id_int,json_question,json_answer,update_ts,structure_path,b_in_paper ,paper_id_int,b_delete,oper_type,check_status,check_msg,use_count,sort_id  FROM t_tk_question_info WHERE b_delete=0 and question_id_char = "..quote(question_id_char).."  and group_id=2 and check_status = 2";

			local res, err, errno, sqlstate = db:query(sql);

			if not res then
				return {success=false, info="查询数据出错！"};
			end

			for i=1, #res do
				local question_id_char			= res[i]["question_id_char"];
				local question_title			= res[i]["question_title"];
				local question_tips				= "东师理想提供";
				local question_type_id			= res[i]["question_type_id"];
				local question_difficult_id		= res[i]["question_difficult_id"];
				local create_person				= 1;
				local create_person_tem			= res[i]["create_person"];
				local group_id					= 1;
				local down_count				= res[i]["down_count"];
				if tostring(down_count)=="userdata: NULL" then
					down_count = 0
				end
				local ts						= currentTS;
				local kg_zg						= res[i]["kg_zg"];
				local cheme_id_int				= res[i]["scheme_id_int"];
				local structure_id_int			= res[i]["structure_id_int"];
				local json_answer				= res[i]["json_answer"];
				local b_in_paper				= res[i]["b_in_paper"];
				local paper_id_int				= res[i]["paper_id_int"];
				local b_delete					= res[i]["b_delete"];
				local oper_type					= res[i]["oper_type"];
				local check_status				= 0;
				local check_msg					= res[i]["check_msg"];
				local use_count					= res[i]["use_count"];
				if tostring(use_count)=="userdata: NULL" then
					use_count = 0
				end
				local sort_id					= res[i]["sort_id"];
				local structure_path			= res[i]["structure_path"];
				local json_question				= res[i]["json_question"];
				json_question_table				= cjson.decode(ngx.decode_base64(json_question));
				json_question_table.t_title 	= "东师理想提供";
				json_question_table.zsd 		= strucStr;
				local json_question_new 			= ngx.encode_base64(cjson.encode(json_question_table));

				local questionModel = require "management.question.model.QuestionModel";
				local question_tem_id = questionModel.getNewRecordPK();

				local insertSql = "insert into t_tk_question_info (id,question_id_char,question_title ,question_tips,question_type_id,question_difficult_id,create_person,group_id,down_count,ts,kg_zg,scheme_id_int,structure_id_int,json_question,json_answer,update_ts,structure_path,b_in_paper ,paper_id_int,b_delete,oper_type,check_status,check_msg,use_count,sort_id) values("..question_tem_id..","..quote(question_id_char)..","..quote(question_title)..","..quote(question_tips)..","..question_type_id..","..question_difficult_id..","..create_person..","..group_id..","..down_count..","..ts..","..kg_zg..","..cheme_id_int..","..structure_id_int..","..quote(json_question_new)..","..quote(json_answer)..","..update_ts..","..quote(structure_path)..","..b_in_paper..","..paper_id_int..","..b_delete..","..oper_type..","..check_status..","..quote(check_msg)..","..use_count..","..sort_id..")";

				local res, err, errno, sqlstate =db:query(insertSql);

				if not res then
					ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".");
					return false;
				end

				local cache = CacheUtil: getRedisConn();

				cache:hmset("question_"..question_tem_id,"scheme_id_int",cheme_id_int,"json_question",json_question_new,"create_person",create_person,"question_id_char",question_id_char,"sort_id",sort_id,"json_answer",json_answer,"down_count",down_count,"b_delete",b_delete);

				local result = ssdb:hset(create_person_tem.."_5_"..question_id_char.."_"..structure_id_int,"check_status",1);

			end
		end

		local upateSql = "update t_tk_question_info set check_status="..check_type..",update_ts="..update_ts.." where question_id_char="..quote(question_id_char).." and group_id=2 and check_status = 2";

		local updateresult, err, errno, sqlstate = db:query(upateSql);
		if not updateresult then
			ngx.say("{\"success\":\"false\",\"info\":\"处理数据出错！\"}");
			return false;
		end

	end
	
	DBUtil: keepDbAlive(db);
	
	return true;
	
end

_QuestionModel.examineQuestion = examineQuestion;



-- -----------------------------------------------------------------------------------
-- 描述：试题后台管理 -> 试题合并
-- 作者：刘全锋
-- 日期：2015年9月15日
-- 参数：question_id_char
-- 参数：t_id
-- 参数：content_md5_new_unique
-- -----------------------------------------------------------------------------------

local function distinctQuestion(content_md5_new_unique)

	local db = DBUtil: getDb();


	local querySql = "select i.id,i.structure_id_int,i.json_question,i.question_id_char from t_tk_question_info i left join t_tk_question_base b on i.question_id_char = b.question_id_char where i.b_delete=0 and i.create_person=1 and i.group_id=1 and i.question_id_char in (select question_id_char from t_tk_question_base where content_md5_new_unique='"..content_md5_new_unique.."' and b_repeat=0) order by i.id desc";

	local queryRes  = db: query(querySql);

	if not queryRes then
		ngx.say("{\"success\":false,\"info\":\"查询数据错误！\"}");
		return false;
	end

	local structure_id_tem = ",";

	for index, record in ipairs(queryRes) do
		if string.find(structure_id_tem, ","..record["structure_id_int"]..",") == nil then

			structure_id_tem = structure_id_tem..record["structure_id_int"]..",";
		else
			local updateSql = "update t_tk_question_info set b_delete = 1 where id="..record["id"];
			local res, err, errno, sqlstate =db:query(updateSql);
			if not res then
				ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
				return false;
			end

			local question_id_char 		= record["question_id_char"];
			local updateBaseSql         = "update t_tk_question_base set b_repeat=1 where question_id_char = '"..question_id_char.."'";
			local resBase, err, errno, sqlstate =db:query(updateBaseSql);
			if not resBase then
				ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
				return false;
			end
		end

	end
	DBUtil: keepDbAlive(db);
	return true;
end

_QuestionModel.distinctQuestion = distinctQuestion;



-- -----------------------------------------------------------------------------------
--[[
	局部函数：	试题反馈
	作者：		刘全锋 2015-09-18
	参数：		paramTable -- 存储参数的table对象
	返回值：	 	boolean true操作成功，false操作失败
]]
-- -----------------------------------------------------------------------------------

local function updateFeedBack(paramTable)

	local feedback_id = paramTable["feedback_id"];
	if feedback_id == nil or feedback_id == ngx.null then
		return false, "feedback_id不能为空";
	end

	local feedback_status		= paramTable["feedback_status"];
	local deal_content		= paramTable["deal_content"];

	local updateSql = "UPDATE t_base_feedback SET  deal_content = "..quote(deal_content)..", feedback_status = "..feedback_status.." WHERE feedback_id ="..feedback_id;

	local result = DBUtil: querySingleSql(updateSql);
	if not result then
		return false;
	else
		return true;
	end
end

_QuestionModel.updateFeedBack = updateFeedBack;



---------------------------------------------------------------------------

--[[
	局部函数：	根据ID查询试题反馈
	作者：		刘全锋 2015-09-18
	参数：		feedback_id -- 反馈ID
	返回值： 	根据ID查询的数据，空返回false
]]

local function queryFeedBackById(feedback_id)

	local db = DBUtil: getDb();
	local sql = "select feedback_id,feedback_content,feedback_status,deal_content from t_base_feedback where feedback_id = "..tonumber(feedback_id).." limit 1";

	local queryResult = db:query(sql);

	if not queryResult or #queryResult == 0 then
		return false;
	end

	local record = {};
	record.feedback_id  = queryResult[1]["feedback_id"];
	record.feedback_content  = queryResult[1]["feedback_content"];
	record.feedback_status  = queryResult[1]["feedback_status"];
	record.deal_content  = queryResult[1]["deal_content"];

	record.success = true;
	DBUtil: keepDbAlive(db);

	return record;
end

_QuestionModel.queryFeedBackById = queryFeedBackById;
---------------------------------------------------------------------------


-- -----------------------------------------------------------------------------------
--[[
	局部函数：	删除评论
	作者：		刘全锋 2015-10-14
]]
-- -----------------------------------------------------------------------------------

local function delReview(review_id)
	local sql = "delete from t_base_review where review_id = "..tonumber(review_id);
	local result = DBUtil: querySingleSql(sql);
	if not result then
		return false;
	else
		return true;
	end
end
_QuestionModel.delReview = delReview;


-- -----------------------------------------------------------------------------------


-- -----------------------------------------------------------------------------------
--[[
	局部函数：	删除试题
	作者：		刘全锋 2015-10-24
]]
-- -----------------------------------------------------------------------------------

local function delQuestion(question_id_char,structure_ids_table)

	local cache = CacheUtil: getRedisConn();


	local sql = "update  t_tk_question_info set b_delete=1 , update_ts="..currentTS.." where question_id_char ="..quote(question_id_char).." and group_id=1 and create_person=1";

	local sqlBase = "select i.structure_id_int,b.content_md5 from t_tk_question_base b inner join t_tk_question_info i on b.question_id_char=i.question_id_char where i.question_id_char ="..quote(question_id_char);

	if #structure_ids_table==1 then
		sql = sql.." and structure_id_int = "..tonumber(structure_ids_table[1]);
		sqlBase = sqlBase .. " and i.structure_id_int = "..tonumber(structure_ids_table[1]);
	else
		local structure_ids = "";
		for i=1, #structure_ids_table do
			structure_ids = structure_ids..structure_ids_table[i]..",";
		end
		structure_ids = string.sub(structure_ids,0,string.len(structure_ids)-1);
		sql = sql.." and structure_id_int in ("..structure_ids..")";
		sqlBase = sqlBase.." and i.structure_id_int in ("..structure_ids..")";
	end

	local db = DBUtil: getDb();
	local result = db:query(sql);


	if not result then
		return false;
	end

	local resultBase = db:query(sqlBase);

	if not resultBase or #resultBase==0 then
		return false;
	end

	for i=1, #resultBase do
		local content_md5		= resultBase[i]["content_md5"];
		local structure_id_int	= resultBase[i]["structure_id_int"];

		SSDBUtil: hdel("md5_ques_" .. content_md5, "1_2_" .. structure_id_int);
		SSDBUtil: hdel("md5_ques_" .. content_md5, "1_2");
	end

	local qryZsdSql = "select t1.structure_id_int, t2.structure_name from t_tk_question_info t1 inner join t_resource_structure t2 on t1.structure_id_int=t2.structure_id and t2.type_id=2 where t1.question_id_char="..quote(question_id_char).." and t1.b_delete=0 and t1.b_in_paper=0 and t1.create_person = 1 and t1.group_id=1 group by t1.structure_id_int";

	local resultZsd = db:query(qryZsdSql);

	if not resultZsd then
		return false;
	end

	local strucName = "";

	for i=1, #resultZsd do
		if strucName == "" then
			strucName   	=  resultZsd[i]["structure_name"];
		else
			strucName   	= strucName .. "," .. resultZsd[i]["structure_name"];
		end
	end


	local infoQry = "select id, json_question from t_tk_question_info where 1=1 and question_id_char="..quote(question_id_char).." and b_delete=0 and create_person = 1 and group_id=1";

	local resultInfo = db:query(infoQry);

	if not resultInfo then
		return false;
	end

	for i=1, #resultInfo do
		local id 				= tonumber(resultInfo[i]["id"]);
		local json_question		= resultInfo[i]["json_question"];
		local json_question_table					= cjson.decode(ngx.decode_base64(json_question));
		json_question_table.zsd	= strucName;
		local json_question_new 			= ngx.encode_base64(cjson.encode(json_question_table));

		local updateStSql = "update t_tk_question_info set json_question="..quote(json_question_new).. ", update_ts="..currentTS.." where id="..id;

		local updateResult = db:query(updateStSql);

		if not updateResult then
			return false;
		end

		cache:hmset("question_"..id,"json_question",json_question_new);
	end


	DBUtil: keepDbAlive(db);
	CacheUtil:keepConnAlive(cache);

	return true;

end
_QuestionModel.delQuestion = delQuestion;


-- -----------------------------------------------------------------------------------

--[[
	局部函数：	根据科目查询题型
	作者：		刘全锋 2015-10-15
]]
-- -----------------------------------------------------------------------------------

local function getQtBySubject(stage_id, subject_id)

	local sql = "select t1.id,t2.qt_name,t2.qt_type,t1.sort_id,t2.b_use from t_tk_qt_subject t1 inner join t_tk_question_type t2 on t1.qt_id = t2.qt_id where t1.stage_id = "..tonumber(stage_id).." and t1.subject_id = "..tonumber(subject_id).." order by t1.sort_id";

	local result = DBUtil: querySingleSql(sql);

	if not result then
		return false;
	end

	local resultListObj = {};
	for i=1, #result do
		local record = {};
		record.id 	  			= result[i]["id"];
		record.qt_name   		= result[i]["qt_name"];
		record.qt_type   		= result[i]["qt_type"];
		record.sort_id   		= result[i]["sort_id"];
		record.b_use 			= result[i]["b_use"];
		table.insert(resultListObj, record);
	end
	local resultJsonObj		= {};
	resultJsonObj.success  = true;
	resultJsonObj.list 		= resultListObj;
	return true,resultJsonObj;
end
_QuestionModel.getQtBySubject = getQtBySubject;



return _QuestionModel





