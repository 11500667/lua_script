--[[
@Author cuijinlong
@date 2015-5-22
--]]
local _Scheme = {};
--[[
	局部函数：教师选择教材版本
]]
function _Scheme:teach_choose_scheme(table)
    local MysqlUtil = require "yxx.tool.MysqlUtil";
    local tableUtil = require "yxx.tool.TableUtil";
    local db = MysqlUtil:getDb();
    local k_v_table = tableUtil:convert_sql(table);
    local row_total = MysqlUtil:query("select count(1) as total from t_teacher_choose_scheme where teacher_id="..table.teacher_id.. " and subject_id="..table.subject_id.." and xq_id="..table.xq_id);

    if row_total and tonumber(row_total[1].total)>0 then
        MysqlUtil:query("update t_teacher_choose_scheme set version_id="..table.version_id..",version_name='"..  table.version_name.."',root_structure_id="..  table.root_structure_id.." where teacher_id="..table.teacher_id.. " and subject_id="..table.subject_id.." and xq_id="..table.xq_id);
    else
        MysqlUtil:query("insert into t_teacher_choose_scheme("..k_v_table["k_str"]..") value("..k_v_table["v_str"]..")");
    end
    MysqlUtil:close(db);
end

--[[
	局部函数：学生获得教材版本
]]
function _Scheme:get_scheme_by_teach_subject(teacher_id,xq,subject_id)
    local MysqlUtil = require "yxx.tool.MysqlUtil";
    local db = MysqlUtil:getDb();
    local row = MysqlUtil:query("select version_id,version_name,root_structure_id from t_teacher_choose_scheme where teacher_id="..teacher_id.." and xq_id="..xq.." and subject_id="..subject_id);
    MysqlUtil:close(db);
    return row;
end

--[[
	局部函数：教师获得教材版本
]]
function _Scheme:get_scheme_by_teach(teacher_id,xq_id)
    local MysqlUtil = require "yxx.tool.MysqlUtil";
    local db = MysqlUtil:getDb();
    local row = MysqlUtil:query("select subject_id,version_id,version_name from t_teacher_choose_scheme where teacher_id="..teacher_id.." and xq_id="..xq_id);
    MysqlUtil:close(db);
    return row;
end
return _Scheme;