
local quote = ngx.quote_sql_str;
local cjson = require "cjson"

--连接mysql数据库
local mysql = require "resty.mysql"
local mysql_db = mysql:new()
mysql_db:connect{
    host = "10.10.100.106",
    port = "22066",
    database = "dsideal_db",
    user = "root",
    password = "DsideaL147258369",
    max_packet_size = 1024*1024
}

local countSql = "select count(1) as row_count from t_tk_question_base i where i.question_answer is null and i.json_answer is not null and i.question_type_id in (2,8,26);";

local countRes  = mysql_db:query(countSql);
if not countRes then
    return false;
end

local totalRow  = countRes[1]["row_count"];

local pageSize = 5000;

local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

local count = 0;



local resultSqlStr = "";


for i=1, totalPage do
	local sql = "select question_id_char,json_answer from t_tk_question_base  where question_answer is null and json_answer is not null and question_type_id in (2,8,26) limit " .. (i-1) * pageSize .. "," .. pageSize;

    local res, err, errno, sqlstate = mysql_db:query(sql);

    local sqlTable = {};

    for s=1, #res do
        count = count +1;
        local json_answer_table = {};
        local question_id_char = res[s]["question_id_char"];

        json_answer_table = cjson.decode(ngx.decode_base64(res[s]["json_answer"]));

        local question_answer = json_answer_table.answer;
        local updateSql = "update t_tk_question_base set question_answer="..quote(question_answer).." where question_id_char="..quote(question_id_char);
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

--mysql放回连接池
mysql_db:set_keepalive(0,100);

local resultTable = {};
resultTable.success = true;
resultTable.sqlStr=resultSqlStr;
resultTable.totalRow=totalRow;
resultTable.totalPage=totalPage;


ngx.say(cjson.encode(resultTable));
