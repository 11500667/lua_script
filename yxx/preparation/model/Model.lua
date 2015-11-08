--[[
@Author cuijinlong
@date 2015-7-23
--]]
local _PreparationModel = {};
--[[
	局部函数：带事务的保持预习信息（发布）
]]
function _PreparationModel:saveYxToMysqlForUnpublic(yx_insert_sql,tain_insert_sql_table,material_insert_sql_table,material_cp_insert_sql_table)
    local MysqlUtil = require "yxx.tool.MysqlUtil";
    local tableUtil = require "yxx.tool.TableUtil";
    local sqlTable = {};
    sqlTable[1] = yx_insert_sql;
    sqlTable = tableUtil:concat(sqlTable,tain_insert_sql_table);
    sqlTable = tableUtil:concat(sqlTable,material_insert_sql_table);
    if material_cp_insert_sql_table then
        for i=1,#material_cp_insert_sql_table do
            sqlTable = tableUtil:concat(sqlTable,material_cp_insert_sql_table[i]);
        end
    end
    local db = MysqlUtil:getDb();
--    local cjson = require "cjson";
--    local success = "true";
--    cjson.encode_empty_table_as_object(false);
--    local responseJson = cjson.encode(sqlTable);
--    ngx.say(responseJson);
    local success = MysqlUtil:batch(sqlTable,#sqlTable);
    MysqlUtil:close(db);
    return success;
end
--[[
	局部函数：带事务的保持预习信息（发布）
]]
function _PreparationModel:saveYxToMysqlForPublic(yx_insert_sql,tain_insert_sql_table,material_insert_sql_table,material_cp_insert_sql_table,cp_person_insert_sql_table,yx_person_insert_sql_table)
    local MysqlUtil = require "yxx.tool.MysqlUtil";
    local tableUtil = require "yxx.tool.TableUtil";
    local sqlTable = {};
    sqlTable[1] = yx_insert_sql;
    sqlTable = tableUtil:concat(sqlTable,tain_insert_sql_table);
    sqlTable = tableUtil:concat(sqlTable,material_insert_sql_table);
    if material_cp_insert_sql_table then
        for i=1,#material_cp_insert_sql_table do
            sqlTable = tableUtil:concat(sqlTable,material_cp_insert_sql_table[i]);
        end
    end
    if cp_person_insert_sql_table then
        for i=1,#cp_person_insert_sql_table do
            sqlTable = tableUtil:concat(sqlTable,cp_person_insert_sql_table[i]);
        end
    end
    sqlTable = tableUtil:concat(sqlTable,yx_person_insert_sql_table);
    local db = MysqlUtil:getDb();
    local success = MysqlUtil:batch(sqlTable,#sqlTable);
    MysqlUtil:close(db);
--    local cjson = require "cjson"
--    local success = "true";
--    cjson.encode_empty_table_as_object(false);
--    local responseJson = cjson.encode(sqlTable);
--    ngx.say(responseJson);

    return success;
end
--[[
	局部函数：发布测评
]]
function _PreparationModel:YxPublic(cp_person_insert_sql,yx_person_insert_sql)
    local MysqlUtil = require "yxx.tool.MysqlUtil";
    local tableUtil = require "yxx.tool.TableUtil";
    local sqlTable  = {};
    local db = MysqlUtil:getDb();
    if cp_person_insert_sql and string.len(cp_person_insert_sql) > 0 then
        sqlTable[1] = cp_person_insert_sql;
    end
    if yx_person_insert_sql and string.len(yx_person_insert_sql)>0 then
        sqlTable[#sqlTable+1] = yx_person_insert_sql;
    end
    --sqlTable = tableUtil:concat(sqlTable,yx_person_insert_sql_table);
    local db = MysqlUtil:getDb();
    local success = MysqlUtil:batch(sqlTable,#sqlTable);
    MysqlUtil:close(db);
--        local cjson = require "cjson"
--       local success = "true";
--       cjson.encode_empty_table_as_object(false);
--       local responseJson = cjson.encode(sqlTable);
--       ngx.say(responseJson);
    return success;
end

--[[
	局部函数：创建预习列表
	subject_id：学科ID
	structure_id：章节ID
	sort_type：排序类型
	sort_order：排序方式
	page_size：每页总记录数
	page_number：当前页码
]]
function _PreparationModel:yxList(subject_id,prson_id,identity_id,yx_name,structure_id,sort_type,sort_order,page_size,page_number)
    local MysqlUtil = require "yxx.tool.MysqlUtil";
    local ssdbUtil = require "yxx.tool.SSDBUtil";
    local mysql_db = MysqlUtil:getDb();
    local query_order_model = "";
    local query_order = "";
    local query_condition = "";
    if sort_order then
        if sort_order == "1" then
            query_order_model = "asc";
        else
            query_order_model = "desc";
        end
    end

    if sort_type then
        if sort_type == "1" then
            query_order = " ORDER BY create_time "..query_order_model
        end
    end

    if prson_id ~= "-1" then
        query_condition = query_condition.." AND prson_id="..prson_id;
    end

    if identity_id ~= "-1" then
        query_condition = query_condition.." AND identity_id="..identity_id;
    end

    if subject_id ~= "-1" then
        query_condition = query_condition.." AND subject_id="..subject_id;
    end

    if structure_id ~= "-1" then
        query_condition = query_condition.." AND structure_id="..structure_id;
    end

    if yx_name and string.len(yx_name) > 0 then
        query_condition = query_condition.." AND yx_name like '%"..yx_name.."%'";
    end

    local total_rows_sql = "SELECT count(1) as TOTAL_ROW from t_yx_info where is_delete=0 "..query_condition..";";
    local total_query = mysql_db:query(total_rows_sql);
    if not total_query then
        return {success=false, info="查询数据出错。"};
    end
    local total_row  = total_query[1]["TOTAL_ROW"];
    local total_page = math.floor((total_row+page_size-1)/page_size);
    local offset     = page_size*page_number-page_size;
    local limit      = page_size;
    local query_sql  = "select yx_id from t_yx_info where is_delete=0 "..query_condition.. query_order .." limit " .. offset .. "," .. limit .. ";";
    local rows = mysql_db:query(query_sql);
    local yxVoArray  = {};
    for i=1,#rows do
        local yx_vo  = ssdbUtil:multi_hget_hash("yx_moudel_info_"..rows[i].yx_id,{"yx_id","yx_name","person_id","identity_id","scheme_id","structure_id","subject_id","is_public"});
        table.insert(yxVoArray,yx_vo);
    end
    local yxListJson = {success=true,total_row=total_row,total_page=total_page,page_number=page_number,page_size=page_size,list=yxVoArray};
    MysqlUtil:close(mysql_db);
    return yxListJson;
end
--[[
	局部函数：修改预习主表信息，yx_table是要修改字段的键值对表.
]]
function _PreparationModel:updateYx(yx_id,yx_table)
   local tableUtil = require "yxx.tool.TableUtil";
   local MysqlUtil = require "yxx.tool.MysqlUtil";
   local db = MysqlUtil:getDb();
   local k_v_str = tableUtil:convert_update_sql(yx_table);
   local update_sql = "update t_yx_info set "..k_v_str.." where yx_id="..yx_id;
   MysqlUtil:query(update_sql);
   MysqlUtil:close(db)
end
--[[
	局部函数：删除预习
	参数：yx_id 预习ID cp_type_id 预习在测评模块中属于分类“2”
]]
function _PreparationModel:delYxInfo(yx_id,cp_type_id)
    local DBUtil = require "common.DBUtil";
    local db = DBUtil:getDb();
    local SSDDB = require "yxx.tool.DbUtil";
    local ssdb_db = SSDDB:getSSDb();
    local rows = db:query("SELECT SQL_NO_CACHE id FROM t_yx_person_sphinxse WHERE query=\'filter=yx_id,"..yx_id.."\';SHOW ENGINE SPHINX  STATUS;");
    -- todo 删除预习发布给学生 start
    for i=1,#rows do
        ssdb_db:hclear("yxx_yxtoperson_"..rows[i].id);
    end
    -- todo 删除预习发布给学生 end
    local sql = "START TRANSACTION;delete FROM t_yx_info where yx_id="..yx_id..
                ";delete from t_cp_info where bus_id="..yx_id.." and cp_type_id="..cp_type_id..
                ";COMMIT;";
    ssdb_db:hdel("preparation_yx_info",yx_id);
    ssdb_db:hclear("yx_moudel_info_"..yx_id);
    ssdb_db:del("yx_student_submit_count_"..yx_id);
    ssdb_db:set_keepalive(0,v_pool_size);
    return DBUtil:querySingleSql(sql);
end
--[[
	局部函数：统计预习中每个环节中素材的浏览/讨论总数
	参数：yx_id：预习ID
]]
function _PreparationModel:getYxMaterialStat(yx_id)
    local cjson = require "cjson";
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local materialModel = require "yxx.preparation.material.model.MaterialModel";
    local ssdb_db = SSDBUtil:getDb();
    local yx_detail_encode = ssdb_db:hget("preparation_yx_info",yx_id);
    local yx_detail_table = {};
    if yx_detail_encode ~= "ok" and yx_detail_encode[1] and string.len(yx_detail_encode[1])>0 then
        yx_detail_table = cjson.decode(yx_detail_encode[1]);
        if yx_detail_table then
            local train_list = yx_detail_table.train_list;
            if #train_list>0 then
                for i=1,#train_list do
                    local material_list = train_list[i].material_list;
                    for j=1,#material_list do
                        local material_id = material_list[j].material_id;
                        material_list[j].view_count = materialModel:getStatMaterialOperate(material_id,1);
                        material_list[j].discuss_count = materialModel:getStatMaterialOperate(material_id,2);
                        material_list[j].download_count = materialModel:getStatMaterialOperate(material_id,3);
                    end
                end
            else
                yx_detail_table = {"success",false,"info","该预习中不包含预习环节"};
            end
        end
    end
    SSDBUtil:keepAlive();
    return yx_detail_table;
end
return _PreparationModel;