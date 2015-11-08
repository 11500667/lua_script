--[[
@Author cuijinlong
@date 2015-5-22
--]]
local _Group = {};
--[[
	局部函数：创建分组
]]
function _Group:create_group(table)
    local MysqlUtil = require "yxx.tool.MysqlUtil";
    local tableUtil = require "yxx.tool.TableUtil";
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local db = MysqlUtil:getDb();
    local group_id = SSDBUtil:incr("cp_group_pk");
    table["group_id"] = group_id;
    SSDBUtil:multi_hset("cp_group_"..group_id,table);
    local k_v_table = tableUtil:convert_sql(table);
    ngx.log(ngx.ERR,"insert into t_cp_group("..k_v_table["k_str"]..") value("..k_v_table["v_str"]..")");
    MysqlUtil:query("insert into t_cp_group("..k_v_table["k_str"]..") value("..k_v_table["v_str"]..")");
    MysqlUtil:close(db);
end
--[[
	局部函数：获得分组
]]
function _Group:get_group_list(class_id,teacher_id,subject_id)
    local MysqlUtil = require "yxx.tool.MysqlUtil";
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local db = MysqlUtil:getDb();
    local rows = MysqlUtil:query("select group_id from t_cp_group where class_id="..class_id.." and teacher_id="..teacher_id .. " and subject_id="..subject_id);
    local gameArray = {};
    for i=1,#rows do
        table.insert(gameArray,SSDBUtil:multi_hget_hash("cp_group"..rows[i]["group_id"],"group_id","class_id","teacher_id","group_name"));
    end
    MysqlUtil:close(db);
    return gameArray;
end
--[[
	局部函数：编辑分组
]]
function _Group:edit_group(group_id,group_name)
    local MysqlUtil = require "yxx.tool.MysqlUtil";
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local db = MysqlUtil:getDb();
    --修改分组缓存
    local group_vo_tab = SSDBUtil:multi_hget_hash("cp_group"..group_id,"group_id","class_id","teacher_id","group_name");
    group_vo_tab.group_name=group_name;
    SSDBUtil:multi_hset("cp_group_"..group_id,group_vo_tab);
    --修改数据库中的记录
    MysqlUtil:query("update t_cp_group set group_name="..ngx.quote_sql_str(group_name).." where group_id="..group_id);
    MysqlUtil:close(db);
end
--[[
	局部函数：删除分组
]]
function _Group:del_group(group_id,group_name)
    local MysqlUtil = require "yxx.tool.MysqlUtil";
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local db = MysqlUtil:getDb();
    local ssdb = SSDBUtil:getDb();
    ssdb:hclear("cp_group_"..group_id);
    MysqlUtil:query("delete from t_cp_group where group_id="..group_id);
    MysqlUtil:query("insert into t_cp_group_history(group_id,group_name) value("..group_id..","..ngx.quote_sql_str(group_name)..");");
    ssdb:set("t_cp_group_history_"..group_id,group_name);--为已经删除的记录保留历史。
    MysqlUtil:close(db);
    SSDBUtil:_keepAlive();
end

--[[
	局部函数：为学生进行分组
]]
function _Group:stu_to_group(student_id_array,class_id,group_id)
    local MysqlUtil = require "yxx.tool.MysqlUtil";
    local db = MysqlUtil:getDb();
    local sql_array = {};
    for i=1,#student_id_array do
        sql_array[i] = "delete from t_cp_group_student where class_id="..class_id.." and group_id="..group_id.." and student_id="..student_id_array[i]..";"..
                       "insert into t_cp_group_student(class_id,group_id,student_id) value("..class_id..","..group_id..","..student_id_array[i]..");";
    end
    MysqlUtil:batch(sql_array,#student_id_array);
    MysqlUtil:close(db);
end
-- 返回_Game对象
return _Group;
