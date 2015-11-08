--[[
@Author cuijinlong
@date 2015-6-17
--]]
local say = ngx.say;
local cjson = require "cjson";
local StringUtil = require "yxx.tool.StringUtil";
local DbUtil = require "yxx.tool.DbUtil";
local ZyModel = require "yxx.fz_zy_transfer.model.zyModel";
local PersonInfoModel = require "base.person.model.PersonInfoModel";
local ssdb = DbUtil:getSSDb();
local db = DbUtil:getMysqlDb();
local cache = DbUtil:getRedis();
--获取前台传过来的参数
local all_zy_record_query = "SELECT id as paper_id,id as zy_id,ownerID as teacher_id,subjectId as subject_id,paperName as zy_name,upLoadTime as create_time FROM t_zy_paper_new"
local rows = db:query(all_zy_record_query);
for i=1,#rows do
    local param = {};
    local zy_id = rows[i]["zy_id"];
    local paper_id = rows[i]["paper_id"];
    local subject_id = rows[i]["subject_id"];
    local teacher_id = rows[i]["teacher_id"];
    local zy_name = rows[i]["zy_name"];
    local create_time = rows[i]["create_time"];
    local is_public = 1;
    local scheme_id = 0;
    local structure_id = 0;
    local char_id = cache:hmget("t_resource_structure_"..structure_id,"structure_id_char","scheme_id_char");
    local structure_id_char = char_id[1];
    local scheme_id_char = char_id[2];
    param.zy_id = zy_id;
    param.subject_id = subject_id;
    param.teacher_id = teacher_id;
    param.zy_name = zy_name;
    param.create_time = create_time;
    param.is_public = is_public;
    param.scheme_id = scheme_id;
    param.structure_id = structure_id;
    param.structure_id_char = structure_id_char;
    param.scheme_id_char = scheme_id_char;
    local paper_info = ZyModel:save_zy_parse_paper(paper_id);
    param.zg = paper_info.zg;--格式化试卷主观题信息
    param.kg = paper_info.kg;--格式化试卷客观题信息
    param.zy_content = "";
    param.is_look_answer = "1";
    param.is_download = "1";
    param.group_id_arrs = "";
    param.create_or_update = "";
    param.zy_fj_list = {};
    local personDetail = PersonInfoModel.getPersonDetail(self,teacher_id, 5);
    param["teacher_name"] = personDetail.person_name;
    ZyModel:save_student_zy_relate(zy_id,subject_id,teacher_id,param.class_id_arrs,"");--获取作业班级对象
    local timestamp = StringUtil:getTimestamp();--获取时间戳ts
    cjson.encode_empty_table_as_object(false);--保存整个作业信息到ssab中(false);--保存整个作业信息到ssab中
    ssdb:hset("homework_zy_content",zy_id,cjson.encode(param));
    db:query("insert into t_zy_info (ID,ZY_NAME,CREATE_TIME,TS,UPDATE_TS,SCHEME_ID,SCHEME_ID_CHAR,STRUCTURE_ID,"
            .."STRUCTURE_ID_CHAR,SUBJECT_ID,TEACHER_ID,IS_PUBLIC) values ("
            ..zy_id..","..ngx.quote_sql_str(zy_name)..","..ngx.quote_sql_str(os.date("%Y-%m-%d %H:%M:%S"))..","
            ..ngx.quote_sql_str(timestamp)..","..ngx.quote_sql_str(timestamp)..","
            ..scheme_id..","..ngx.quote_sql_str(scheme_id_char)..","..structure_id..","
            ..ngx.quote_sql_str(structure_id_char)..","..subject_id..","..teacher_id..","..is_public..")");
end
ssdb:set_keepalive(0,v_pool_size);
cache:set_keepalive(0,v_pool_size);
db:set_keepalive(0,v_pool_size);

