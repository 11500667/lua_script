--[[
@Author chuzheng
@date 2014-12-22
--]]
local say = ngx.say;
local cjson = require "cjson";
local StringUtil = require "yxx.tool.StringUtil";
local DbUtil = require "yxx.tool.DbUtil";
local ZyModel = require "zy.model.zyModel";
local service = require "space.gzip.service.BakToolsUpdateTsService"
--获取前台传过来的参数
local request_method = ngx.var.request_method
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end
local param_json = args["param_json"];
local teacher_id = ngx.var.cookie_person_id;
if not teacher_id or string.len(teacher_id) == 0 or not param_json or string.len(param_json) == 0  then
    say("{\"success\":false,\"info\":\"参数错误！\"}");
    return
end
local ssdb = DbUtil:getSSDb();
local db = DbUtil:getMysqlDb();
local cache = DbUtil:getRedis();
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local str = ngx.decode_base64(param_json);
local param = cjson.decode(str);
local zy_name = param.zy_name;
local scheme_id = param.scheme_id;
local structure_id = param.structure_id;
local subject_id = param.subject_id;
local zy_id = param.zy_id;--留作业，作业id
local is_public = param.is_public;--是否发布
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local isedit = 1; --判断是否是编辑,1是编辑，0不是编辑
if not zy_id or string.len(zy_id)==0 then
	zy_id = ssdb:incr("homework_zy_pk")[1];
	isedit = 0;
end
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local char_id = cache:hmget("t_resource_structure_"..structure_id,"structure_id_char","scheme_id_char");
local structure_id_char = char_id[1];
local scheme_id_char = char_id[2];
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local paper_info = ZyModel:save_zy_parse_paper(param.paper_list);
param.zg = paper_info.zg;--格式化试卷主观题信息
param.kg = paper_info.kg;--格式化试卷客观题信息
param.fgsh = paper_info.fgsh; --非格式化试卷
param.create_time = os.date("%Y-%m-%d %H:%M:%S");
param.zy_id = zy_id;
param.teacher_id = teacher_id;
--判断发没发布，发布了执行建立作业学生对于关系
if is_public == "1" then
	ZyModel:save_student_zy_relate(zy_id,subject_id,teacher_id,param.class_id_arrs,param.group_id_arrs);--获取作业班级对象
end
--只有第一次时建立基础的对用关系
if isedit == 0 then
	--保存个基础的学生作业对应关系
	local zy_relate_id = ssdb:incr("homework_relate_id");
	ssdb:multi_hset("homework_zy_student_relate_"..zy_relate_id[1],"zy_id",zy_id,"student_id","0","flat","0","class_id","0","group_id","0");
	db:query("insert into t_zy_zytostudent (id,zy_id,student_id,flat,CLASS_ID,GROUP_ID) values("..zy_relate_id[1]..","..zy_id..",0,0,0,0)");
end
local timestamp = StringUtil:getTimestamp();--获取时间戳ts
cjson.encode_empty_table_as_object(false);--保存整个作业信息到ssab中(false);--保存整个作业信息到ssab中
ssdb:hset("homework_zy_content",zy_id,cjson.encode(param));
if isedit ==0 then
	db:query("insert into t_zy_info (ID,ZY_NAME,CREATE_TIME,TS,UPDATE_TS,SCHEME_ID,SCHEME_ID_CHAR,STRUCTURE_ID,STRUCTURE_ID_CHAR,SUBJECT_ID,TEACHER_ID,IS_PUBLIC) values ("..zy_id..","..ngx.quote_sql_str(zy_name)..","..ngx.quote_sql_str(os.date("%Y-%m-%d %H:%M:%S"))..","..ngx.quote_sql_str(timestamp)..","..ngx.quote_sql_str(timestamp)..","..scheme_id..","..ngx.quote_sql_str(scheme_id_char)..","..structure_id..","..ngx.quote_sql_str(structure_id_char)..","..subject_id..","..teacher_id..","..is_public..")");
else
	db:query("update t_zy_info set ZY_NAME="..ngx.quote_sql_str(zy_name)..",UPDATE_TS="..ngx.quote_sql_str(timestamp)..",IS_PUBLIC="..is_public.." where ID="..zy_id);
end
service.updateTs(teacher_id,5);
say("{\"success\":true,\"info\":\"保存成功\",\"zy_id\":\""..zy_id.."\"}");
ssdb:set_keepalive(0,v_pool_size);
cache:set_keepalive(0,v_pool_size);
db:set_keepalive(0,v_pool_size);

