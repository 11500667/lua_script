local DBUtil = require "common.DBUtil";
local cjson = require "cjson"
local CacheUtil = require "common.CacheUtil";
local quote = ngx.quote_sql_str;
local cache = CacheUtil:getRedisConn();



local sql = "select id,paper_id_char,paper_name,json_content from t_sjk_paper_info where paper_type = 1;";

local result = DBUtil:querySingleSql(sql);
if not next(result) then
    ngx.say("{\"success\":false,\"info\":\"数据查询错误\"}");
    return;
end

local sqlTable = {};
for i = 1, #result do
    local id = result[i].id;
    local paper_name = result[i].paper_name;
    local json_content = result[i].json_content;
    local paper_id_char = result[i].paper_id_char;

    local status, err = pcall(function()
            local paper_table = cjson.decode(ngx.decode_base64(json_content));
            paper_table.h1_text = paper_name;
            local new_json = ngx.encode_base64(cjson.encode(paper_table));
            local updateSql = "update t_sjk_paper_info set json_content=" .. quote(new_json) .. " where id=" .. id .. ";";
            local paper_info = {};
            paper_info.json_content = new_json;
            --修改缓存
           cache:hmset("paper_" .. id, paper_info);
           cache:hmset("paperinfo_" .. paper_id_char, paper_info);

            local res = DBUtil:querySingleSql(updateSql);
    end)

    while true do
        if not status then
            break;
        end
        break;
    end
end


ngx.say("======================================================================");



local sql = "select paper_id_int,paper_name,json_content from t_sjk_paper_base where paper_type = 1;";


local result = DBUtil:querySingleSql(sql);
if not next(result) then
    ngx.say("{\"success\":false,\"info\":\"数据查询错误\"}");
    return;
end

local sqlTable = {};
for i = 1, #result do
    local paper_id_int = result[i].paper_id_int;
    local paper_name = result[i].paper_name;
    local json_content = result[i].json_content;

    local status, err = pcall(function()
        local paper_table = cjson.decode(ngx.decode_base64(json_content));
        paper_table.h1_text = paper_name;
        local new_json = ngx.encode_base64(cjson.encode(paper_table));
        local updateSql = "update t_sjk_paper_base set json_content=" .. quote(new_json) .. " where paper_id_int=" .. paper_id_int .. ";";

        local res = DBUtil:querySingleSql(updateSql);
    end)

    while true do
        if not status then
            break;
        end
        break;
    end

end


local responseObj = {};
responseObj.success = true;
responseObj.info = "操作成功";
local responseJson = cjson.encode(responseObj);

CacheUtil:keepConnAlive(cache);

ngx.say(responseJson);


















