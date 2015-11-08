--[[
@Author chuzheng
@date 2014-12-18
@测试数据
功能：创建预习
--]]
local say = ngx.say;
local cjson = require "cjson";
local yxPersonModel = require "yxx.preparation.person.model.PersonModel"; --预习的人员表
local cpPersonModel = require "yxx.cp.person.model.PersonModel"; --测评的表
local cpModel = require "yxx.cp.model.CpModel"; --测评的表
local studentModel = require "yxx.student.model.StudentModel";
local preparetionModel = require "yxx.preparation.model.Model";
local parameterUtil = require "yxx.tool.ParameterUtil";
local answerUtil = require "yxx.cp.answer.model.AnswerModel"
local SSDBUtil = require "yxx.tool.SSDBUtil"
local is_public = parameterUtil:getNumParam("is_public",0);--0：取消发布  1：发布
local class_ids = parameterUtil:getStrParam("class_ids",'');--发布的班级
local group_ids = parameterUtil:getStrParam("group_ids",'');--按组发布
local yx_id = parameterUtil:getStrParam("yx_id",'');--预习ID
if string.len(class_ids)==0 then
    say("{\"success\":false,\"info\":\"class_ids参数错误！\"}")
    return
else
    class_ids = ngx.decode_base64(class_ids);
end
if string.len(yx_id)==0 then
    say("{\"success\":false,\"info\":\"yx_id参数错误！\"}")
    return
end
--ngx.log(ngx.ERR,"###############"..class_ids.."##############");
if tonumber(is_public) == 0 then
    local isCanCancel = answerUtil:isExistAnswerQuestion(yx_id,2);
    if tonumber(isCanCancel) == 0 then
        yxPersonModel:delYxPerson(yx_id,2);--todo删除 cp_person yx_person
    else
        say("{\"success\":false,\"info\":\"已经有学生作答不能取消发布.\"}");
        return;
    end

    -- todo 更新数据库 start
    local yx_update_table = {};
    yx_update_table.is_public = 0;
    preparetionModel:updateYx(yx_id,yx_update_table);
    -- todo 更新数据库 end

    -- todo 更新缓存 start
    local yx_table = SSDBUtil:multi_hget_hash("yx_moudel_info_"..yx_id,"yx_id","yx_name","create_time","person_id","identity_id","scheme_id","structure_id","subject_id","is_public","class_ids","group_ids");
    yx_table.is_public = 0;
    SSDBUtil:multi_hset("yx_moudel_info_"..yx_id,yx_table);
    -- todo 更新缓存 end
    say("{\"success\":true,\"info\":\"预习取消发布成功！\"}");
elseif tonumber(is_public) == 1 then
    --第三步：组装预习对象的Vo-----------------------------------------------------------------------------------------------------------------------------------------------------------
    local person_table_arrs = studentModel:getPersonTableArrs(class_ids,group_ids); --通过班级和组查询基础数据
    --表名：t_yx_person（预习参与人）
    local yx_person_insert_sql = yxPersonModel:getPersonInsertSqlTable(yx_id, person_table_arrs); --组装预习参与人的insert语句
    local cp_id_arrs = cpModel:getCpIdByBusIdAndCpTypeId(yx_id,2);--通过bus_id，cp_type_id获得cp_id数组
    local cp_person_insert_sql = "";--组装预习中测评的参与人的insert语句
    for i = 1,#cp_id_arrs do
        --表名：t_cp_person（测评参与人）
        cp_person_insert_sql = cp_person_insert_sql..cpPersonModel:getPersonInsertSqlTable(tonumber(cp_id_arrs[i]),yx_id,2, person_table_arrs)
    end
    --第四步：保存到数据库（方式：1、发布；2、不发布）-----------------------------------------------------------------------------------------------------------------------------------------------------------
    local success = preparetionModel:YxPublic(
        cp_person_insert_sql, --组装预习中测评的参与人的insert语句
        yx_person_insert_sql --表名：t_yx_person（预习参与人）
    );
    if tostring(success) == "true" then
        -- todo 更新数据库 start
        local yx_update_table = {};
        yx_update_table.is_public = 1;
        preparetionModel:updateYx(yx_id,yx_update_table);
        -- todo 更新数据库 end

        -- todo 更新缓存 start
        local yx_table = SSDBUtil:multi_hget_hash("yx_moudel_info_"..yx_id,"yx_id","yx_name","create_time","person_id","identity_id","scheme_id","structure_id","subject_id","is_public","class_ids","group_ids");
        yx_table.is_public = 1;
        SSDBUtil:multi_hset("yx_moudel_info_"..yx_id,yx_table);
        -- todo 更新缓存 end
        say("{\"success\":" .. tostring(success) .. ",\"info\":\"预习发布成功！\"}");
    else
        say("{\"success\":false,\"info\":\"预习保存失败！\"}");
    end
end
SSDBUtil.keepAlive();