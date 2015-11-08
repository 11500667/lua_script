--[[
@Author cuijinlong
@date 2015-7-23
--]]
local _Material = {};

--[[
	局部函数：组装环节中素材Vo数组
]]
function _Material:getMaterialVo(train_id,material_table)
    local material_vo = {}
    material_vo.material_id = tonumber(material_table.material_id);
    material_vo.train_id = train_id;
    material_vo.resource_type = tonumber(material_table.resource_type);
    material_vo.resource_id = tostring(material_table.resource_id);
    material_vo.view_count = 0;
    material_vo.discuss_count = 0;
    material_vo.download_count = 0;
    material_vo.is_download = 0;
    return material_vo;
end


--[[
	局部函数：组装insert sql语句
]]
function _Material:getMaterialInsertSqlArrstable(material_table_arrs)
    local tableUtil = require "yxx.tool.TableUtil";
    local sql_table = {};
    for i=1,#material_table_arrs do
        local k_v_table = tableUtil:convert_sql(material_table_arrs[i]);
        sql_table[i] = "insert into t_yx_material("..k_v_table["k_str"]..") value("..k_v_table["v_str"]..");"
    end
    return sql_table;
end

--[[
	局部函数：设置预习统计
	参数：operate_type 1:浏览   2：讨论   3：下载
]]
function _Material:setStatMaterialOperate(person_id,identity_id,material_id,operate_type)
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local MysqlUtil = require "yxx.tool.MysqlUtil";
    local ssdb_db = SSDBUtil:getDb();
    local db = MysqlUtil:getDb();
    local sql_str = "update t_yx_material set ";
    local stat_count;
    if tonumber(operate_type) == 1 then
        stat_count = ssdb_db:incr("stat_material_view_count_"..material_id,1);
        ssdb_db:hset("stat_student_material_view_"..material_id,person_id.."_"..identity_id,ngx.localtime());
        sql_str = sql_str.." view_count = "..stat_count[1];
    elseif tonumber(operate_type) == 2 then
        stat_count = ssdb_db:incr("stat_material_discuss_count_"..material_id,1);
        ssdb_db:hset("stat_student_material_discuss_"..material_id,person_id.."_"..identity_id,ngx.localtime());
        sql_str = sql_str.." discuss_count = "..stat_count[1];
    elseif tonumber(operate_type) == 3 then
        stat_count = ssdb_db:incr("stat_material_download_count_"..material_id,1);
        sql_str = sql_str.." download_count = "..stat_count[1];
        ssdb_db:hset("stat_student_material_download_"..material_id,person_id.."_"..identity_id,ngx.localtime());
    end
    sql_str = sql_str.." where material_id="..material_id;
    MysqlUtil:query(sql_str);
    MysqlUtil:close(db);
    SSDBUtil:keepAlive();
end

--[[
	局部函数：获得预习统计
]]
function _Material:getStatMaterialOperate(material_id,operate_type)
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local ssdb_db = SSDBUtil:getDb();
    local stat_count;
    if tonumber(operate_type) == 1 then
        local count = ssdb_db:get("stat_material_view_count_"..material_id);
        --ngx.log(ngx.ERR,"############"..string.len(count[1]));
        stat_count = string.len(count[1])>0 and count[1] or 0;
    elseif tonumber(operate_type) == 2 then
        local count = ssdb_db:get("stat_material_discuss_count_"..material_id);
        --ngx.log(ngx.ERR,"############"..string.len(count[1]));
        stat_count = string.len(count[1])>0 and count[1] or 0;
    elseif tonumber(operate_type) == 3 then
        local count = ssdb_db:get("stat_material_download_count_"..material_id);
        --ngx.log(ngx.ERR,"############"..string.len(count[1]));
        stat_count = string.len(count[1])>0 and count[1] or 0;
    end
    SSDBUtil:keepAlive();
    return stat_count;
end

return _Material;