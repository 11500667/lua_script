--[[
@Author cuijinlong
@date 2015-7-11
--]]
local _Question = {};

--[[
	局部函数：组装测评模块试题的vo
]]
function _Question:getQuestionVo(cp_table,question_id)
    local questionBase = require "question.model.QuestionBase";
    local stringUtil = require "yxx.wrong_question_book.util.stringUtil";
    local question_info = questionBase:getQuesDetailByIdChar(question_id);
    local knowledge_point_codes = stringUtil:kwonledge_point_code_convert(question_info.knowledge_point_codes);
    local question_vo = {};
    question_vo.cp_id = cp_table.cp_id;
    question_vo.question_id = question_id;
    question_vo.bus_id = cp_table.bus_id;
    question_vo.cp_type_id = cp_table.cp_type_id;
    question_vo.subject_id = cp_table.subject_id;
    question_vo.scheme_id = cp_table.scheme_id;
    question_vo.structure_id = cp_table.structure_id;
    question_vo.knowledge_point_codes = knowledge_point_codes;
    question_vo.question_type_id = question_info.question_type_id;
    question_vo.nd_id = question_info.nd_id;
    question_vo.right_count = 0;
    question_vo.wrong_count = 0;
    question_vo.sequence_number = 0;
    question_vo.score = 0;
    return question_vo;
end

--[[
	局部函数：组装测评模块试题的insert语句
]]
function _Question:getQuestionInsertSqlTable(cp_question_table_arrs)
    local tableUtil = require "yxx.tool.TableUtil";
    local question_insert_sql_arrs = {};
    for i=1,#cp_question_table_arrs do
        local k_v_table = tableUtil:convert_sql(cp_question_table_arrs[i]);
        question_insert_sql_arrs[i] = "insert into t_cp_question("..k_v_table["k_str"]..") value("..k_v_table["v_str"]..");"
    end
    return question_insert_sql_arrs;
end
--[[
	局部函数：组装测评模块试题的insert语句
]]
function _Question:getQuestionList(paper_id)
    local ZyModel = require "zy.model.zyModel";
    local paper_info = ZyModel:get_gs_question_paper(paper_id);
    return paper_info;
end
return _Question;