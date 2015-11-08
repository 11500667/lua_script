--[[
@Author cuijinlong
@date 2015-5-22
--]]
local _CP = {};
--[[
 局部函数：学生测评提交
]]
function _CP:cpSubmit(cptoperson_id)
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local TS = require "resty.TS";
    local cjson = require "cjson";
    local DBUtil = require "common.DBUtil";
    local db = DBUtil:getDb();
    local person_vo = SSDBUtil:multi_hget_hash("yxx_cptoperson_"..cptoperson_id,"bureau_id","bus_id","class_id","cp_id","cp_type_id","id","identity_id","person_id","submit_state","sum_score","update_ts");
    --ngx.log(ngx.ERR,"##########"..cjson.encode(person_vo).."########");
    if person_vo and person_vo[1] ~= "ok" then
        local localtime = ngx.localtime();
        local update_ts = TS.getTs();
        person_vo.update_ts = update_ts;
        person_vo.submit_time = localtime;
        person_vo.submit_state = 1;
        SSDBUtil:multi_hset("yxx_cptoperson_"..cptoperson_id,person_vo);--测评的人员表
        local sql_update = "update t_cp_person set submit_state=1,submit_time='"..localtime.."',update_ts="..update_ts.." where id="..cptoperson_id..";";
        DBUtil:querySingleSql(sql_update);
        SSDBUtil:hset("cp_student_submit_"..person_vo.bus_id.."_"..person_vo.cp_type_id,cptoperson_id,tostring(localtime));--统计那些人提交了测评
    end
    DBUtil:keepDbAlive(db);
    SSDBUtil:keepAlive();
    return true;
end
return _CP;