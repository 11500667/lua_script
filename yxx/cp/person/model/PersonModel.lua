--[[
@Author cuijinlong
@date 2015-7-23
--]]
local _Person = {};

--[[
	局部函数：通过基础数据的人员信息，组装测评表的参与人插入脚本
]]
function _Person:getPersonInsertSqlTable(cp_id,bus_id,cp_type_id,person_table)
    local tableUtil = require "yxx.tool.TableUtil";
    local _SSDBUtil = require "yxx.tool.SSDBUtil";
    local TS = require "resty.TS";
    local person_insert_sql = "";
    if person_table and #person_table>0 then
        for i=1,#person_table do
            local update_ts = TS.getTs();
            local cptoperson_id = _SSDBUtil:incr("t_cp_cptoperson_pk");
            local person_vo = {};
            person_vo.id = tonumber(cptoperson_id);
            person_vo.cp_id = tonumber(cp_id);
            person_vo.bus_id = tonumber(bus_id);
            person_vo.cp_type_id = tonumber(cp_type_id);
            person_vo.person_id = tonumber(person_table[i].STUDENT_ID);
            person_vo.identity_id = 6;
            person_vo.bureau_id = tonumber(person_table[i].BUREAU_ID);
            person_vo.class_id = tonumber(person_table[i].CLASS_ID);
            if person_table[i].group_id and string.len(person_table[i].group_id)>0 then
                person_vo.group_id = person_table[i].group_id;
            end
            person_vo.sum_score = 0;--测评得分
            person_vo.submit_state = 0;--0:未提交   1：已提交
            person_vo.update_ts = update_ts;
            _SSDBUtil:multi_hset("yxx_cptoperson_"..cptoperson_id,person_vo);
            local k_v_table = tableUtil:convert_sql(person_vo);
            if i == 1 then
                person_insert_sql = "insert into t_cp_person("..k_v_table["k_str"]..") values ";
            elseif i == #person_table then
                person_insert_sql = person_insert_sql.." ("..k_v_table["v_str"]..");";
            else
                person_insert_sql = person_insert_sql.." ("..k_v_table["v_str"].."),";
            end
        end
    end
    return person_insert_sql;
end

--[[
	局部函数：通过基础数据的人员信息，组装测评表的参与人插入脚本
]]
function _Person:delCpPerson(cp_id)
    local sql = "delete FROM t_cp_person where cp_id="..cp_id;
    local DBUtil = require "common.DBUtil";
    DBUtil:querySingleSql(sql);
end
return _Person;