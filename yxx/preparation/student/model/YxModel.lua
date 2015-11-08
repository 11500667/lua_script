--[[
@Author cuijinlong
@date 2015-5-22
--]]
local _YX = {};
--[[
 局部函数：学生预习列表
]]
function _YX:yxList(yx_name,person_id, person_identity, subject_id, is_root, scheme_id, structure_id, sort_type, sort_mode, cnode, page_size, page_number)
    local DbUtil = require "yxx.tool.DbUtil";
    local MysqlUtil = require "yxx.tool.MysqlUtil";
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local offset = page_size * page_number - page_size;
    local limit = page_size;
    local str_maxmatches = page_number * 100;
    --升序还是降序
    local asc_desc = "";
    if sort_mode == "1" then
        asc_desc = "asc";
    else
        asc_desc = "desc";
    end
    --排序
    local sort_filed = "";
    if sort_type == "1" then
        sort_filed = "sort=attr_" .. asc_desc .. ":update_ts;";
    end
    local query_condition = "";
    if yx_name ~= "" then
        query_condition = query_condition..yx_name..";";--关键字搜索
    end
    if person_id ~= "" then
        query_condition = query_condition .. "filter=participantor_id," .. person_id .. ";"; --预习创建人ID
    end
    if person_identity ~= "" then
        query_condition = query_condition .. "filter=participantor_identity," .. person_identity .. ";"; --预习创建人身份
    end
    if subject_id ~= "" then
        query_condition = query_condition .. "filter=subject_id," .. subject_id .. ";";
    end

    local structure_scheme = ""
    if is_root == "1" then
        if cnode == "1" then
            structure_scheme = "filter=scheme_id," .. scheme_id .. ";"
        else
            structure_scheme = "filter=structure_id," .. structure_id .. ";"
        end
    else
        if cnode == "0" then
            structure_scheme = "filter=structure_id," .. structure_id .. ";"
        else
            local cache = DbUtil:getRedis();
            local sid = cache:get("node_" .. structure_id)
            local sids = Split(sid, ",")
            for i = 1, #sids do
                structure_scheme = structure_scheme .. sids[i] .. ","
            end
            structure_scheme = "filter=structure_id," .. string.sub(structure_scheme, 0, #structure_scheme - 1) .. ";"
            cache:set_keepalive(0, v_pool_size)
        end
    end
    local db = MysqlUtil:getDb();
    local query_sql = "SELECT SQL_NO_CACHE id FROM t_yx_person_sphinxse where QUERY=\'" .. query_condition .. structure_scheme .. sort_filed .. "filter=is_delete,0;filter=is_public,1;maxmatches=" .. str_maxmatches .. ";offset=" .. offset .. ";limit=" .. limit .. "\';SHOW ENGINE SPHINX  STATUS;";
    local rows = MysqlUtil:query(query_sql);
    local read_result = db:read_result();
    local _, s_str = string.find(read_result[1]["Status"], "found: ");
    local e_str = string.find(read_result[1]["Status"], ", time:");
    local total_row = string.sub(read_result[1]["Status"], s_str + 1, e_str - 1);
    local total_page = math.floor((total_row + page_size - 1) / page_size);
    local return_table = {};
    for i=1,#rows do
        local yxtoperson_tab = SSDBUtil:multi_hget_hash("yxx_yxtoperson_"..rows[i].id,"yx_id","submit_state"); --rows[i].id：预习人员表的ID
        local yx_table = SSDBUtil:multi_hget_hash("yx_moudel_info_"..yxtoperson_tab.yx_id, "yx_id", "yx_name", "create_time","scheme_id", "structure_id", "subject_id", "is_public");
        if yxtoperson_tab.submit_state == nil or string.len(yxtoperson_tab.submit_state) == 0 then
            yx_table.submit_state = 0;
        else
            yx_table.submit_state = yxtoperson_tab.submit_state;
        end
        table.insert(return_table, yx_table);
    end
    local result = {};
    result["success"] = "true";
    result["total_row"] = total_row;
    result["total_page"] = total_page;
    result["page_number"] = page_number;
    result["page_size"] = page_size;
    result["list"] = return_table;
    SSDBUtil:keepAlive();
    MysqlUtil:close(db);
    return result;
end

function _YX:yxSubmit(yx_id,person_id,identity_id)
    local StudentCpModel = require "yxx.cp.student.model.StudentCpModel";
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local TS = require "resty.TS";
    local DBUtil = require "common.DBUtil";
    local db = DBUtil:getDb();
    local yx_rows = db:query("SELECT SQL_NO_CACHE id FROM t_yx_person_sphinxse WHERE query=\'filter=yx_id,"..yx_id..";filter=participantor_id,"..person_id..";filter=participantor_identity,"..identity_id..";\';SHOW ENGINE SPHINX  STATUS;");
    if yx_rows and yx_rows[1].id and string.len(yx_rows[1].id)>0 then
        local person_vo = SSDBUtil:multi_hget_hash("yxx_yxtoperson_"..yx_rows[1].id,"id","yx_id","person_id","identity_id","bureau_id","class_id","group_id","submit_state","update_ts");
        if person_vo and person_vo[1] ~= "ok" then
            local localtime = ngx.localtime();
            local update_ts = TS.getTs();
            person_vo.update_ts = update_ts;
            person_vo.submit_time = localtime;
            person_vo.submit_state = 1;
            SSDBUtil:multi_hset("yxx_yxtoperson_"..yx_rows[1].id,person_vo);--预习的参与人员表
            local sql_update = "update t_yx_person set submit_state=1,submit_time='"..localtime.."',update_ts="..update_ts.." where id="..yx_rows[1].id..";";
            DBUtil:querySingleSql(sql_update);
            SSDBUtil:hset("yx_student_submit_"..yx_id,yx_rows[1].id,tostring(localtime));--统计那些人提交了预习。
        end
        -- todo 如果预习中包含测评 那么需要将测评进行提交。start
        local cp_rows = DBUtil:querySingleSql("SELECT SQL_NO_CACHE id FROM t_cp_person_sphinxse WHERE query=\'filter=bus_id,"..yx_id..";filter=cp_type_id,2;filter=participantor_id,"..person_id..";filter=participantor_identity,"..identity_id..";\';SHOW ENGINE SPHINX  STATUS;");
        for i=1,#cp_rows do
            StudentCpModel:cpSubmit(cp_rows[i].id);
        end
        -- todo 如果预习中包含测评 那么需要将测评进行提交。end
    else
        return false;
    end

    DBUtil:keepDbAlive(db);
    SSDBUtil:keepAlive();
    return true;
end
return _YX;