--[[
@Author cuijinlong
@date 2015-7-23
--]]
local _Person = {};

--[[
	局部函数：通过基础数据的人员信息，组装测评表的参与人插入脚本
]]
function _Person:getPersonInsertSqlTable(yx_id,person_table)
    local tableUtil = require "yxx.tool.TableUtil";
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local TS = require "resty.TS";
    local ssdb = SSDBUtil:getDb();
    local person_insert_sql = "";
    if person_table then
        for i=1,#person_table do
            local yxtoperson_id = SSDBUtil:incr("t_yx_yxtoperson_pk");
            local update_ts = TS.getTs();
            local person_vo = {};
            person_vo.id = tonumber(yxtoperson_id);
            person_vo.yx_id = tonumber(yx_id);
            person_vo.person_id = tonumber(person_table[i].STUDENT_ID);
            person_vo.identity_id = 6;
            person_vo.bureau_id = tonumber(person_table[i].BUREAU_ID);
            person_vo.class_id = tonumber(person_table[i].CLASS_ID);
            if person_table.group_id and string.len(person_table.group_id)>0 then
                person_vo.group_id = person_table[i].group_id;
            end
            person_vo.submit_state = 0;
            person_vo.update_ts = update_ts;
            local k_v_table = tableUtil:convert_sql(person_vo);
            --组装insert语句
            if i == 1 then
                person_insert_sql = "insert into t_yx_person("..k_v_table["k_str"]..") values ";
            elseif i == #person_table then
                person_insert_sql = person_insert_sql.." ("..k_v_table["v_str"]..");";
            else
                person_insert_sql = person_insert_sql.." ("..k_v_table["v_str"].."),";
            end
            SSDBUtil:multi_hset("yxx_yxtoperson_"..yxtoperson_id,person_vo);
        end
    end
    SSDBUtil:keepAlive();
    return person_insert_sql;
end


--[[
	局部函数：通过基础数据的人员信息，组装测评表的参与人插入脚本
]]
function _Person:delYxPerson(yx_id,cp_type_id)
    local sql = "START TRANSACTION;"..
                "delete FROM t_yx_person where yx_id="..yx_id.." and person_id<>0;"..
                "delete from t_cp_person where bus_id="..yx_id.." and cp_type_id="..cp_type_id.." and person_id<>0;"..
                "COMMIT;";
    local DBUtil = require "common.DBUtil";
    DBUtil:querySingleSql(sql);
end

function _Person:getYxSubmitInfo(yx_id)
    local sql = "START TRANSACTION;"..
            "delete FROM t_yx_person where yx_id="..yx_id.." and person_id<>0;"..
            "COMMIT;";
    local DBUtil = require "common.DBUtil";
    DBUtil:querySingleSql(sql);
end
return _Person;