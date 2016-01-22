
-- -----------------------------------------------------------------------------------
-- 描述：试卷后台管理 -> 试卷编辑
-- 作者：刘全锋
-- 日期：2016年01月13日
-- -----------------------------------------------------------------------------------

local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

local DBUtil   = require "common.DBUtil";
local cjson = require "cjson"
local CacheUtil = require "common.CacheUtil";
local quote = ngx.quote_sql_str;

local cache = CacheUtil: getRedisConn();
local p_myTs      = require "resty.TS";
local currentTS = p_myTs.getTs();


local ids = tostring(args["ids"])
if ids == "nil" then
    ngx.say("{\"success\":false,\"info\":\"ids参数错误！\"}")
    return
end

if string.sub(ids,#ids) == "," then
    ids = string.sub(ids,1,#ids-1);
end

local optype = tostring(args["optype"])
if optype == "nil" then
    ngx.say("{\"success\":false,\"info\":\"optype参数错误！\"}")
    return
end

local paper_id = tostring(args["paper_id"])
if paper_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"paper_id参数错误！\"}")
    return
end

--获取试卷json串信息
local paper = cache:hmget("paper_"..tostring(paper_id),"paper_id_char","json_content","subject_id");
local paper_id_char = paper[1];
local paper_table = cjson.decode(ngx.decode_base64(paper[2]));
local subject_id =  paper[3];


--查询当前学科题型
local txSql = "select t1.id,t2.qt_id,t2.qt_name,t2.qt_type,t1.sort_id,t2.b_use from t_tk_qt_subject t1 inner join t_tk_question_type t2 on t1.qt_id = t2.qt_id where t1.subject_id = "..subject_id.." order by t1.sort_id";

local result = DBUtil:querySingleSql(txSql);
if not next(result) then
    ngx.say("{\"success\":false,\"info\":\"题型查询错误\"}");
    return;
end

local tx_list_table = {};
for i=1,#result do
    local tx_table = {};
    tx_table.pfl_visible="0";
    tx_table.oneortwo="1";
    tx_table.qt_id=result[i].qt_id;
    tx_table.visible="0";
    tx_table.tx_zhu="注释";
    tx_table.tx_name=result[i].qt_name;
    tx_table.sort_id= 0;
    table.insert(tx_list_table,tx_table);
end

paper_table.tx = tx_list_table; --修改原试卷题型与当前题型一致

local ti_table = paper_table.ti;--试卷中题的table

local ids_table = Split(ids,",");
local tem_table = Split(ids,",");


for i=1,#ids_table-1 do
    for s=i+1,#ids_table do
        if ids_table[i] == ids_table[s] then
            ngx.say("{\"success\":false,\"info\":\"试题编号有重复请仔细核对\"}");
            return;
        end
    end
end

local not_question_str = "";
local not_subject_str = "";
for i=1,#ids_table do
    local question_id = ids_table[i];
    local scheme_id_int = cache:hget("question_"..question_id,"scheme_id_int");
    if tostring(scheme_id_int) == "userdata: NULL" then
        not_question_str = not_question_str..question_id..",";
    else
        local sql = "select subject_id from  t_resource_scheme where scheme_id = "..scheme_id_int;
        local result = DBUtil:querySingleSql(sql);
        if not next(result) then
            ngx.say("{\"success\":false,\"info\":\"数据查询错误\"}");
            return;
        end

        if tonumber(result[1].subject_id) ~= tonumber(subject_id) then
            not_subject_str = not_subject_str..question_id..",";
        end
    end
end

if #not_question_str>0 then
    not_question_str = string.sub(not_question_str,1,#not_question_str-1);
    ngx.say("{\"success\":false,\"info\":\"试题编号"..not_question_str.."的试题不存在\"}");
    return;
end


if #not_subject_str>0 then
    not_subject_str = string.sub(not_subject_str,1,#not_subject_str-1);
    ngx.say("{\"success\":false,\"info\":\"试题编号"..not_subject_str.."的试题与试卷学科不一致\"}");
    return;
end


--添加试题时，验证试卷中是否有重复的试题，根据id判断，如果其它节点下question_id_char相同的题，可以插入
local tem_str = "";
if tonumber(optype) == 1 then
    for i=1,#ids_table do
        local question_id = ids_table[i];
        for s=1,#ti_table do
            if tonumber(question_id) == tonumber(ti_table[s].id) then
                tem_str = tem_str .. question_id..",";
            end
        end
    end

    if #tem_str>0 then
        tem_str = string.sub(tem_str,1,#tem_str-1);
        ngx.say("{\"success\":false,\"info\":\"试题编号"..tem_str.."在试卷中已存在，不允许加入\"}");
        return;
    end
else

    for s=1,#ti_table do
        for i=1,#tem_table do
            if tonumber(ti_table[s].id) == tonumber(tem_table[i]) then
                table.remove(tem_table,i);
            end
        end
    end

    if #tem_table>0 then
        ngx.say("{\"success\":false,\"info\":\"试题编号"..table.concat(tem_table,",").."在试卷中不存在\"}");
        return;
    end
end
--结束


local max_sort_id = 0;
for i=1,#ti_table do
    if max_sort_id < ti_table[i].sort_id then
        max_sort_id = ti_table[i].sort_id;
    end
end

for i=1,#ids_table do

    local question_id = ids_table[i];

    if tonumber(optype) == 1 then
        local sql = "select b.question_id_char,b.question_tips,b.height,b.question_difficult_id,b.question_type_id,b.file_id,i.structure_id_int from t_tk_question_info i inner join t_tk_question_base b on i.question_id_char=b.question_id_char where i.id="..question_id;

        local result = DBUtil:querySingleSql(sql);
        if not next(result) then
            ngx.say("{\"success\":false,\"info\":\"数据查询错误\"}");
            return;
        end


        local question_id_char = result[1].question_id_char;
        local structure_id_int = result[1].structure_id_int;

        local tem_ti = {};
        tem_ti.height = result[1].height;
        tem_ti.id = question_id;
        tem_ti.nd_id = result[1].question_difficult_id;
        tem_ti.qt_id = result[1].question_type_id;
        tem_ti.sort_id = max_sort_id+i;
        tem_ti.source_type = 1;
        tem_ti.structure_id = result[1].structure_id_int;
        tem_ti.t_id = result[1].file_id;
        tem_ti.t_title = result[1].question_tips;
        table.insert(ti_table,tem_ti);

        local newPK = cache:incr("t_tk_question_info_pk");
        local insertSql = "insert into t_tk_question_info (id, question_id_char, question_title, question_tips, question_type_id, question_difficult_id, create_person, group_id, down_count, ts, kg_zg, scheme_id_int, structure_id_int, json_question, json_answer, update_ts, structure_path, b_in_paper, paper_id_int, b_delete, oper_type, check_status, check_msg, use_count, sort_id) select " .. newPK .. ", question_id_char, question_title, question_tips, question_type_id, question_difficult_id, create_person, 1 as group_id, down_count, "..currentTS.." as ts, kg_zg, scheme_id_int, structure_id_int, json_question, json_answer, " .. currentTS .. " as update_ts, structure_path, 1 as b_in_paper, "..paper_id.." as paper_id_int, 0 as b_delete, oper_type, 0 as check_status, check_msg, use_count, sort_id from t_tk_question_info where id=" .. question_id;

        local insertResult = DBUtil:querySingleSql(insertSql);

        if not insertResult then
            ngx.say("{\"success\":false,\"info\":\"数据处理错误\"}");
            return;
        end

    else
        for s=1,#ti_table do
            if ti_table[s] ~= nil then
                if tonumber(question_id) == tonumber(ti_table[s].id) then

                    table.remove(ti_table,s);

                    local qrySql = "select question_id_char,structure_id_int from t_tk_question_info where id="..question_id;

                    local queryResult = DBUtil:querySingleSql(qrySql);

                    if not queryResult then
                        ngx.say("{\"success\":false,\"info\":\"数据查询错误\"}");
                        return;
                    end

                    local question_id_char = queryResult[1].question_id_char;
                    local structure_id_int = queryResult[1].structure_id_int;

                    local updateSql = "update t_tk_question_info set b_delete=1, update_ts="..currentTS.." where question_id_char="..quote(question_id_char).." and structure_id_int="..structure_id_int.." and b_in_paper=1 and group_id=1 and paper_id_int="..paper_id;
                    local updateResult = DBUtil:querySingleSql(updateSql);
                    if not updateResult then
                        ngx.say("{\"success\":false,\"info\":\"数据处理错误\"}");
                        return;
                    end
                end
            end
        end
    end
end

paper_table.ti = ti_table;

local new_json = ngx.encode_base64(cjson.encode(paper_table));
local paper_info = {};
paper_info.json_content = new_json;
--修改缓存
cache:hmset("paper_"..paper_id,paper_info);
cache:hmset("paperinfo_"..paper_id_char,paper_info);

local updateSql = "update t_sjk_paper_info set json_content="..quote(new_json)..", update_ts="..currentTS.." where id="..paper_id;

local result = DBUtil:querySingleSql(updateSql);
if not result then
    ngx.say("{\"success\":false,\"info\":\"数据更新错误\"}");
    return;
end


local responseObj = {};
responseObj.success = true;
responseObj.info = "操作成功";
local responseJson = cjson.encode(responseObj);

CacheUtil:keepConnAlive(cache);

ngx.say(responseJson);


