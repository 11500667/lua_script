--[[
@Author cuijinlong
@date 2015-7-11
--]]
local _Cp = {};

--[[
    获得测评主表的mysql插入脚本
    cp_id:测评ID
    cp_name:测评名称
    bus_id：业务ID（作业/预习/复习）
    parent_id：父亲ID 默认值-1
    paper_id：试卷ID
    person_id：人员ID
    identity_id：身份ID
    scheme_id：版本ID
    structure_id：目录结构ID
    subject_id：学科ID
    cp_type_id：测评类型（1：作业 2：测评）
--]]

function _Cp:getCpInsertSql(cp_id,cp_name,bus_id,parent_id,paper_id,person_id,identity_id,scheme_id,structure_id,subject_id,cp_type_id)
    --第一步：组装测评主表的信息 start
    local say = ngx.say();
    local cp_table = {};
    --测评ID
    if not cp_id or string.len(cp_id) == 0  then
        say("{\"success\":false,\"info\":\"参数错误,cp_id不能为空！\"}");
        return
    else
        cp_table.cp_id = cp_id;
    end

    --测评名称
    if not cp_name or string.len(cp_name) == 0  then
        say("{\"success\":false,\"info\":\"参数错误,cp_name不能为空！\"}");
        return
    else
        cp_table.cp_name = cp_name;
    end

    --试卷ID
    if not paper_id or string.len(paper_id) == 0  then
        say("{\"success\":false,\"info\":\"参数错误,paper_id不能为空！\"}");
        return
    else
        cp_table.paper_id = paper_id;
    end

    --业务ID
    if not bus_id or string.len(bus_id) == 0 then
        say("{\"success\":false,\"info\":\"参数错误,cp_type_id不能为空！\"}");
        return
    else
        cp_table.bus_id = bus_id;
    end

    --类型
    if not cp_type_id or string.len(cp_type_id) == 0 then
        say("{\"success\":false,\"info\":\"参数错误,cp_type_id不能为空！\"}");
        return
    else
        cp_table.cp_type_id = cp_type_id;
    end

    --参与人
    if not person_id or string.len(person_id) == 0 then
        say("{\"success\":false,\"info\":\"参数错误,person_id不能为空！\"}");
        return
    else
        cp_table.person_id = person_id;
    end

    --参与人身份
    if not identity_id or string.len(identity_id) == 0 then
        say("{\"success\":false,\"info\":\"参数错误,person_id不能为空！\"}");
        return
    else
        cp_table.identity_id = identity_id;
    end

    --父亲ID
    if not parent_id or string.len(parent_id) == 0  then
        cp_table.paper_id = -1;
    else
        cp_table.paper_id = parent_id;
    end

    --教材版本ID
    if not structure_id or string.len(structure_id) == 0 then
        cp_table.structure_id = -1;
    else
        cp_table.structure_id = structure_id;
    end

    --版本章节目录
    if not scheme_id or string.len(scheme_id) == 0 then
        cp_table.scheme_id = -1;
    else
        cp_table.scheme_id = scheme_id;
    end

    --教材版本ID
    if not subject_id or string.len(subject_id) == 0 then
        cp_table.subject_id = -1;
    else
        cp_table.subject_id = subject_id;
    end

    local cp_insert_sql = cpModel:getCpInsertSqlTable(cp_table);
    --组装测评信息的信息 end

    --第二步：组装试卷中试题的信息 start
    local cp_question_insert_sql_table = {}; --测评中的试题的insert语句数组
    local cp_question_table_arrs = {};--装着本次测评的所有试题信息
    --todo cp_question_table_arrs = 通过paper_id获得试卷中的所有试题信息
    for i=1,#cp_question_table_arrs do
        local question_info = questionBase:getQuesDetailByIdChar(cp_question_table_arrs[i].question_id);
        local knowledge_point_codes = stringUtil:kwonledge_point_code_convert(question_info.knowledge_point_codes);
        --组装试卷中试题的Vo数组 start
        local question_vo = {};
        question_vo.cp_id = tonumber(SSDBUtil:incr("cheping_moudel_pk"));
        question_vo.question_id = 10;
        question_vo.bus_id = bus_id;
        question_vo.cp_type_id = cp_type_id;
        question_vo.subject_id = subject_id;
        question_vo.scheme_id = scheme_id;
        question_vo.structure_id = structure_id;
        question_vo.knowledge_point_codes = knowledge_point_codes;
        question_vo.question_type_id = question_info.question_type_id;
        question_vo.nd_id = question_info.nd_id;
        question_vo.right_count = 0;
        question_vo.wrong_count = 0;
        question_vo.sequence_number = 0;
        question_vo.score = 0;
        table.insert(cp_question_table_arrs, question_vo);
        --组装试卷中试题的Vo数组 end
    end
    if cp_question_table_arrs and #cp_question_table_arrs>0then
        cp_question_insert_sql_table = cpQuestionModel:getQuestionInsertSqlTable(cp_question_table_arrs);
    end
    --组装试卷中试题的信息 end

    --第三步：保存到数据库 start
    local cp_model_insert_sql_table = cpModel:getCpInsertSqlTable(cp_insert_sql,cp_question_insert_sql_table);

end
--[[
	局部函数：获得测评模块的insert语句（不发布发布）
]]
function _Cp:getCpInsertSqlForUpPublic(cp_insert_sql,cp_question_insert_sql_table)
    local MysqlUtil = require "yxx.tool.MysqlUtil";
    local cpSqlTable = {};
    cpSqlTable[1] = cp_insert_sql;
    if cp_question_insert_sql_table then
        for i=1,#cp_question_insert_sql_table do
            cpSqlTable[1+i] = cp_question_insert_sql_table[i];
        end
    end
end
--[[
	局部函数：带事务的保持测评信息（发布）
]]
function _Cp:getCpInsertSqlForPublic(cp_insert_sql,cp_question_insert_sql_table,cp_person_insert_table)
    local MysqlUtil = require "yxx.tool.MysqlUtil";
    local cpSqlTable = {};
    cpSqlTable[1] = cp_insert_sql;
    if cp_question_insert_sql_table then
        for i=1,#cp_question_insert_sql_table do
            cpSqlTable[1+i] = cp_question_insert_sql_table[i];
        end
    end
    if cp_person_insert_table then
        for i=1,#cp_person_insert_table do
            cpSqlTable[1+#cp_question_insert_sql_table+i] = cp_person_insert_table[i];
        end
    end
    return cpSqlTable;
end

--[[
	局部函数：带事务的保持测评信息（发布）
]]
function _Cp:PublicCp(cp_person_insert_table)
    local MysqlUtil = require "yxx.tool.MysqlUtil";
    local sqlTable = {};
    if cp_person_insert_table then
        for i=1,#cp_person_insert_table do
            sqlTable[i] = cp_person_insert_table[i];
        end
    end
    local db = MysqlUtil:getDb();
    local success = MysqlUtil:batch(sqlTable,#sqlTable);
    MysqlUtil:close(db);
    return success;
end

--[[
	局部函数：组装测评模块测评主表的insert语句
]]
local function getCpInsertSqlTable(cp_table)
    local tableUtil = require "yxx.tool.TableUtil";
    local k_v_table = tableUtil:convert_sql(cp_table);
    local insert_sql = "insert into t_cp_info("..k_v_table["k_str"]..") value("..k_v_table["v_str"]..");"
    return insert_sql;
end
_Cp.getCpInsertSqlTable = getCpInsertSqlTable;

return _Cp;