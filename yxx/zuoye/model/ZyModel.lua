--[[
	局部函数：作业的DAO类
]]
local _ZyModel= {};

function _ZyModel:getClassZuoye(class_id,subject_id,pageSize,pageNumber)
    local MysqlUtil = require "yxx.tool.MysqlUtil";
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local cjson = require "cjson";
    local db = MysqlUtil:getDb();
    local ssdb = SSDBUtil:getDb();
    local offset = pageSize*pageNumber-pageSize;
    local limit = pageSize;
    local str_maxmatches = pageNumber*100;
    local condition_sql = "";
    if class_id and string.len(class_id) == 0 then
       condition_sql = condition_sql .. "filter=class_id,"..class_id..";";
    end
    if subject_id and string.len(subject_id) == 0 then
        condition_sql =  condition_sql .. "filter=subject_id,"..subject_id..";";
    end
    local query_sql = "SELECT SQL_NO_CACHE id FROM t_zy_info_sphinxse where query=\'"..condition_sql.."filter=is_public,1;filter=type_id,0;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit..";groupby=attr:ZY_ID;sort=attr_desc:ZY_ID;\';SHOW ENGINE SPHINX STATUS;";
    local zy = db:query(query_sql);
    local zy1 = db:read_result();
    local _,s_str = string.find(zy1[1]["Status"],"found: ");
    local e_str = string.find(zy1[1]["Status"],", time:");
    local totalRow = string.sub(zy1[1]["Status"],s_str+1,e_str-1);
    local totalPage = math.floor((totalRow+pageSize-1)/pageSize);
    local pages={}
    for i=1,#zy do
        local page={};
        local relate = ssdb:multi_hget("homework_zy_student_relate_"..zy[i]["id"],"zy_id");
        local zylist =ssdb:hget("homework_zy_content",relate[2]);
        if  not zylist then
            return {}
        end
        if string.len(zylist[1])>0 then
            local zycontent=zylist[1];
            local zycon=cjson.decode(zycontent);
            page["zy_id"]=relate[2];
            page["zy_name"]=zycon.zy_name;
            page["public_time"]=zycon.create_time;
            page["is_public"]=zycon.is_public;
            page["is_download"]=zycon.is_download;
            page["is_look_answer"]=zycon.is_look_answer;
            if table.getn(zycon.zy_fj_list)==0 then
                page["is_have_res"]=0;
            else
                page["is_have_res"]=1;
            end
            page["fj"]=table.getn(zycon.zy_fj_list);
            if zycon.paper_list and (zycon.paper_list)[1] then
                page["paper_source"]=(zycon.paper_list)[1].paper_source;
            else
                page["paper_source"]="";
            end
            --加入试卷信息
            if zycon.zg and (zycon.zg)[1] then
                page["is_have_zg"]="1";
            else
                page["is_have_zg"]="0";
            end
            if zycon.kg and (zycon.kg)[1] then
                page["is_have_kg"]="1";
            else
                page["is_have_kg"]="0";
            end
            -- 提交情况
            local counts = db:query("SELECT SQL_NO_CACHE id FROM t_zy_info_sphinxse  WHERE query=\'filter=ZY_ID,"..relate[2].."\';SHOW ENGINE SPHINX  STATUS;")
            local count1 = db:read_result();
            local _,s_str = string.find(count1[1]["Status"],"found: ");
            local e_str = string.find(count1[1]["Status"],", time:");
            local total = string.sub(count1[1]["Status"],s_str+1,e_str-1);
            local submissiontotal=ssdb:get("homework_answer_submissionhomework_"..relate[2]);
            if string.len(submissiontotal[1])==0 then
                page["submission"]=ngx.encode_base64("0/"..(tonumber(total)-1));
            else
                page["submission"]=ngx.encode_base64(submissiontotal[1].."/"..(tonumber(total)-1));
            end
            local subjectivepy=ssdb:get("homework_subjectivepy_"..relate[2]);
            local subjective=ssdb:get("home_answersubjective_"..relate[2]);
            if string.len(subjective[1])==0 then
                page["subjective"]=ngx.encode_base64("0/0");
            else
                if string.len(subjectivepy[1])==0 then
                    page["subjective"]=ngx.encode_base64("0/"..subjective[1]);
                else
                    page["subjective"]=ngx.encode_base64(subjectivepy[1].."/"..subjective[1]);
                end
            end
        end
        pages[i]=page;
    end
    local result={};
    result["success"]="true";
    result["totalRow"]=totalRow;
    result["totalPage"]=totalPage;
    result["pageNumber"]=pageNumber;
    result["pageSize"]=pageSize;
    result["list"]=pages;
    SSDBUtil:keepAlive();
    MysqlUtil:close(db);
    return result;
end
-- 返回_ZyModel对象
return _ZyModel;
