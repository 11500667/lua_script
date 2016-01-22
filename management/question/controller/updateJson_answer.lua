
local DBUtil   = require "common.DBUtil";
local db = DBUtil: getDb();
local quote = ngx.quote_sql_str;
local cjson = require "cjson"


local countSql = "select count(1) as row_count from t_tk_question_info i where i.json_answer is null and i.question_type_id in (2,8,26)";

local countRes  = db:query(countSql);
if not countRes then
    return false;
end

local totalRow  = countRes[1]["row_count"];

local pageSize = 5000;

local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

local count = 0;

local db = DBUtil: getDb();

local resultSqlStr = "";


for i=1, totalPage do
	local sql = "select i.id,i.question_id_char,b.question_answer from t_tk_question_info i left join  t_tk_question_base b on i.question_id_char=b.question_id_char where  i.json_answer is null and i.question_type_id in (2,8,26) order by i.id limit " .. (i-1) * pageSize .. "," .. pageSize;

    local res, err, errno, sqlstate = db:query(sql);

    local sqlTable = {};

    for s=1, #res do
        count = count +1;
        local json_answer_table = {};
        local id = res[s]["id"];
        json_answer_table.question_id_char = res[s]["question_id_char"];
        json_answer_table.answer = res[s]["question_answer"];
        local json_answer 			= ngx.encode_base64(cjson.encode(json_answer_table));
        local updateSql = "update t_tk_question_info set json_answer="..quote(json_answer).." where id="..id;
        resultSqlStr = resultSqlStr..updateSql..";";
        table.insert(sqlTable, updateSql);
    end

--    if #sqlTable>0 then
--    local boolResult = DBUtil: batchExecuteSqlInTx(sqlTable, pageSize);
--    if boolResult then
--        ngx.log(ngx.ERR, ">>>>>>>>>>>>>>> 批量更新[成功] <<<<<<<<<<<<<<<<<<<<");
--    else
--        ngx.log(ngx.ERR, ">>>>>>>>>>>>>>> 批量更新[失败] <<<<<<<<<<<<<<<<<<<<");
--    end
--    end

end

DBUtil: keepDbAlive(db);

local resultTable = {};
resultTable.success = true;
resultTable.sqlStr=resultSqlStr;
resultTable.totalRow=totalRow;
resultTable.totalPage=totalPage;


ngx.say(cjson.encode(resultTable));
