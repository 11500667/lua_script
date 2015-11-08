

local DBUtil   = require "common.DBUtil";
local _QuestionModel_sd = {};
local cjson = require "cjson"
local p_myTs      = require "resty.TS"
local currentTS = p_myTs.getTs();
local CacheUtil = require "common.CacheUtil";


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

_QuestionModel_sd.querySchemeByProduct = querySchemeByProduct;


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

_QuestionModel_sd.getNewRecordPK = getNewRecordPK;


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
			down_count = 0;
		end
		local ts						= currentTS;
		local kg_zg						= res[1]["kg_zg"];
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

			if op_type == 1 then
				local insertSql = "insert into t_tk_question_info (id,question_id_char,question_title ,question_tips,question_type_id,question_difficult_id,create_person,group_id,down_count,ts,kg_zg,scheme_id_int,structure_id_int,json_question,json_answer,update_ts,structure_path,b_in_paper ,paper_id_int,b_delete,oper_type,check_status,check_msg,use_count,sort_id) values("..question_id..",'"..question_id_char.."','"..question_title.."','"..question_tips.."',"..question_type_id..","..question_difficult_id..","..create_person..","..group_id..","..down_count..","..ts..","..kg_zg..","..version_id..","..structure_ids_table[i]..",'"..json_question_new.."','"..json_answer.."',"..update_ts..",'"..structure_path.."',"..b_in_paper..","..paper_id_int..","..b_delete..","..oper_type..","..check_status..",'"..check_msg.."',"..use_count..","..sort_id..")";

				local res, err, errno, sqlstate =db:query(insertSql);
				if not res then
					ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
					return false;
				end

				cache:hmset("question_"..question_id,"scheme_id_int",version_id,"json_question",json_question_new,"create_person",create_person,"question_id_char",question_id_char,"sort_id",sort_id,"json_answer",json_answer,"down_count",down_count,"b_delete",b_delete);

			else

				local moveSql = "update t_tk_question_info set scheme_id_int="..version_id..",structure_id_int="..structure_ids_table[i]..",json_question = '"..json_question_new.."',structure_path='"..structure_path.."',ts="..currentTS..",update_ts="..currentTS.." where id = "..v.id
				local res, err, errno, sqlstate =db:query(moveSql);
				if not res then
					ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
					return false;
				end
				cache:hmset("question_"..v.id,"scheme_id_int",version_id,"json_question",json_question_new);
			end
		end
	end

	CacheUtil:keepConnAlive(cache);
	DBUtil: keepDbAlive(db);

	return true;
end

_QuestionModel_sd.questionCopyOrMove = questionCopyOrMove;


return _QuestionModel_sd





