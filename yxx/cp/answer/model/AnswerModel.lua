--[[
@Author cuijinlong
@date 2015-7-28
--]]
local _Answer = {};

--[[
	局部函数：通过业务ID和业务类型获得测评ID
	bus_id：业务ID  作业：zy_id  预习:yx_id
	cp_type_id: 作业：1   预习：2
]]
function _Answer:isExistAnswerQuestion(bus_id,cp_type_id)
    local sql = "SELECT count(*) as TOTAL_ROW FROM t_cp_answer where bus_id="..bus_id.." and cp_type_id="..cp_type_id;
    local DBUtil = require "common.DBUtil";
    local queryResult = DBUtil:querySingleSql(sql);
    return tonumber(queryResult[1]["TOTAL_ROW"]);
end
--[[
	局部函数：记录学生回答试题
	参数： table
]]
function _Answer:SetAnswerQuestion(table)
    local MysqlUtil = require "yxx.tool.MysqlUtil";
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local tableUtil = require "yxx.tool.TableUtil";
    local db = MysqlUtil:getDb();
    local k_v_table = tableUtil:convert_sql(table);
    local query_sql = "replace into t_cp_answer("..k_v_table["k_str"]..") value("..k_v_table["v_str"]..");";
    MysqlUtil:query(query_sql);
    SSDBUtil:multi_hset("yxx_cp_answer_question_"..table.cp_id.."_"..table.question_id.."_"..table.identity_id.."_"..table.person_id,table);
    MysqlUtil:close(db);
    SSDBUtil:keepAlive();
end
--[[
	局部函数：记录学生回答试题
	参数： table
]]
function _Answer:GetAnswerQuestion(cp_id,question_id,identity_id,person_id)
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local answerQuestionDetail = SSDBUtil:multi_hget_hash("yxx_cp_answer_question_"..cp_id.."_"..question_id.."_"..identity_id.."_"..person_id,"question_id","answer","is_full_score");
    SSDBUtil:keepAlive();
    return answerQuestionDetail;
end
--[[
	局部函数：删除学生回答试题的记录
	参数： table
]]
function _Answer:DelAnswerQuestion(table)
    local MysqlUtil = require "yxx.tool.MysqlUtil";
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local db = MysqlUtil:getDb();
    local query_sql = "delete from t_cp_answer where cp_id="..table.cp_id.." and question_id="..table.question_id.." and identity_id="..table.identity_id.." and person_id="..table.person_id;
    MysqlUtil:query(query_sql);
    SSDBUtil:hclear("yxx_cp_answer_question_"..table.cp_id.."_"..table.question_id.."_"..table.identity_id.."_"..table.person_id);
    MysqlUtil:close(db);
    SSDBUtil:keepAlive();
end
return _Answer;