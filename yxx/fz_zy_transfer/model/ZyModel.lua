--[[
	局部函数：作业的DAO
]]
local _ZyModel= {};
--[[
	局部函数：获得所有错题的试题ID
	student_id：学生ID
	zy_id：作业ID
]]
function _ZyModel:save_zy_parse_paper(paper_id)
    local cjson = require "cjson"
    local paper_info = {};
    local zgs={};--格式化试卷中主观题信息
    local zg_flag=1;
    local kgs={};--格式化试卷中客观题信息
    local kg_flag=1;
    local papers = ngx.location.capture("/dsideal_yy/ypt/zy/papertitlelist",{
        body="paper_id_char="..paper_id
    });--改之后的获取格式化试卷信息
    local paper;
    if papers.status == 200 then
        paper = cjson.decode(papers.body).table_List;
    else
        say("{\"success\":false,\"info\":\"查询试卷信息错误！\"}")
        return
    end
    if paper then
        for i=1,#paper do
            --判断是客观题还是主观题
            if paper[i].kg_zg=="1" and tonumber(paper[i].question_type_id) ~= 14 then
                local kg={};
                kg["file_id"]=paper[i].file_id;
                kg["question_answer"]=paper[i].question_answer;
                kg["question_type_id"]=paper[i].question_type_id;
                kg["kg_zg"]=1;
                kg["question_id_char"]=paper[i].question_id_char;
                kg["option_count"]=paper[i].option_count;
                kgs[kg_flag]=kg;
                kg_flag=kg_flag+1;
            else
                local zg={};
                zg["file_id"]=paper[i].file_id;
                zg["question_answer"]=paper[i].question_answer;
                zg["question_type_id"]=paper[i].question_type_id;
                zg["kg_zg"]=2;
                zg["question_id_char"]=paper[i].question_id_char;
                zg["option_count"]=paper[i].option_count;
                zgs[zg_flag]=zg;
                zg_flag=zg_flag+1;
            end
        end
    end
    paper_info.zg = zgs;
    paper_info.kg = kgs;
    return paper_info;
end
--[[
	局部函数：保存学生和作业对应关系
	class_id_arrs：作业所发布的班级
	group_id_arrs：作业所发布的组
]]
function _ZyModel:save_student_zy_relate(zy_id,subject_id,teacher_id,class_id_arrs,group_id_arrs)
    local StringUtil = require "yxx.tool.StringUtil";
    local cjson = require "cjson";
    local DbUtil = require "yxx.tool.DbUtil";
    local db = DbUtil:getMysqlDb();
    local ssdb = DbUtil:getSSDb();
    if string.len(class_id_arrs)>0  then
        local classs = StringUtil:split(class_id_arrs,",");
        local sql_str = "";
        for m=1,#classs do
            local studentes = ngx.location.capture("/dsideal_yy/base/getStudentByClassId",{ body="class_id="..classs[m]; });
            local student;
            if studentes.status == 200 then
                student = cjson.decode(studentes.body).list
            else
                say("{\"success\":false,\"info\":\"查询班级下学生失败！\"}")
                return
            end
            --查询组信息
            for i=1,#student do
                --关系表id
                local zy_relate_id=ssdb:incr("homework_relate_id")
                --保存作业学生对应关系
                --ssdb:multi_hset("homework_zy_student_relate_"..zy_relate_id[1],"zy_id",zy_id,"student_id",student[i].id,"flat","0")
                --用于学生作业id查找关联表id
                ssdb:hset("homework_zy_relateidbystudentidzyid",zy_id.."_"..student[i].student_id,zy_relate_id[1]);
                local groupid,err = ssdb:hget("homework_groupbystudent_"..classs[m].."_"..student[i].student_id,teacher_id.."_"..subject_id);
                if not groupid then
                    say("{\"success\":false,\"info\":\"组查询失败！\"}");
                    return
                end
                --判断这个学生是否有组，没有组则在存入0
                local groupstudentid = 0;
                if string.len(groupid[1])>0 then
                    groupstudentid = groupid[1];
                end
                if string.len(sql_str)>0 then
                    sql_str = sql_str..",("..zy_relate_id[1]..","..zy_id..","..student[i].student_id..",0,"..classs[m]..","..groupstudentid..")";
                else
                    sql_str = "("..zy_relate_id[1]..","..zy_id..","..student[i].student_id..",0,"..classs[m]..","..groupstudentid..")";
                end
                --保存作业学生对应关系
                ssdb:multi_hset("homework_zy_student_relate_"..zy_relate_id[1],"zy_id",zy_id,"student_id",student[i].student_id,"flat","0","class_id",classs[m],"group_id",groupstudentid);
                --保存zset里用于以后导数据
                ssdb:zset("homework_zy_student_relate",zy_relate_id[1],zy_relate_id[1])
            end
        end
        if string.len(sql_str)>0 then
            local res, err, errno, sqlstate=db:query("insert into t_zy_zytostudent (id,zy_id,student_id,flat,class_id,group_id) values "..sql_str)
            if not res then
                ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".");
                return
            end
        end
    end
    if string.len(group_id_arrs)>0  then
        local groups = StringUtil:split(group_id_arrs,",")
        local sql_str=""
        for m=1,#groups do
            local groupids = StringUtil:split(groups[m],"_")
            local students,err = ssdb:hscan("homework_studentbygroup_"..groupids[1].."_"..teacher_id.."_"..subject_id.."_"..groupids[2],"","",200)
            if  not  students then
                say("{\"success\":false,\"info\":\"组下学生查询失败！\"}")
                return
            end
            if students[1]~="ok" then
                for j=1,#students,2 do
                    --关系表id
                    local zy_relate_id=ssdb:incr("homework_relate_id")
                    if string.len(sql_str)>0 then
                        sql_str = sql_str..",("..zy_relate_id[1]..","..zy_id..","..students[j]..",0,"..groupids[1]..","..groupids[2]..")"
                    else
                        sql_str = "("..zy_relate_id[1]..","..zy_id..","..students[j]..",0,"..groupids[1]..","..groupids[2]..")"
                    end
                    --保存作业学生对应关系
                    ssdb:multi_hset("homework_zy_student_relate_"..zy_relate_id[1],"zy_id",zy_id,"student_id",students[j],"flat","0","class_id",groupids[1],"group_id",groupids[2])
                    --保存zset里用于以后导数据
                    ssdb:zset("homework_zy_student_relate",zy_relate_id[1],zy_relate_id[1])
                    --用于学生作业id查找关联表id
                    ssdb:hset("homework_zy_relateidbystudentidzyid",zy_id.."_"..students[j],zy_relate_id[1])
                end
            end
        end
        if string.len(sql_str)>0 then
            local res, err, errno, sqlstate=db:query("insert into t_zy_zytostudent (id,zy_id,student_id,flat,CLASS_ID,GROUP_ID) values "..sql_str)
            if not res then
                ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
                return
            end
        end
    end
end
--[[
	局部函数：获得所有错题的试题ID
	student_id：学生ID
	zy_id：作业ID
]]
function _ZyModel:get_zy_answer_question_info(student_id,zy_id)
    local dbUtil = require "zy.util.DbUtil";
    local ssdb_db = dbUtil:getSSDb();
    local answer_question_array = {};
    local wrong_question_infos = "";
    local right_question_ids = "";
    local answer_info,err = ssdb_db:hscan("homework_answer_"..student_id.."_"..zy_id,'','',200);
    if answer_info[1] ~="ok" then
        for j=1,#answer_info,2 do
            local question_id=answer_info[j];
            local answer_array = Split(answer_info[j+1],"_");
            local stu_answer = answer_array[1];
            local question_answer = answer_array[2];
            if stu_answer ~= question_answer then
                wrong_question_infos = wrong_question_infos..question_id.."_"..stu_answer..","; --"格式：2323_A,2234_B,2356_C   错题id_学生答案"
            else
                right_question_ids = right_question_ids..question_id..",";--"格式：2323,2234,2356   正确题id"
            end
        end
        if string.len(wrong_question_infos)>0 then
            wrong_question_infos = string.sub(wrong_question_infos, 0, string.len(wrong_question_infos)-1)
        end
        if string.len(right_question_ids)>0 then
            right_question_ids = string.sub(right_question_ids, 0, string.len(right_question_ids)-1)
        end
    end
    answer_question_array["wrong_question_infos"] = wrong_question_infos;
    answer_question_array["right_question_ids"] = right_question_ids;
    ssdb_db:set_keepalive(0,v_pool_size);
    return answer_question_array;
end
--------------------------------------------------------------------------------------------------------------------------------------------------------
return _ZyModel;
