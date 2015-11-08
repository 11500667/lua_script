local dbUtil = require "yxx.tool.DbUtil";
local cjson = require "cjson";
local ssdb_db = dbUtil:getSSDb();
local mysql_db = dbUtil:getMysqlDb();
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end
local stage_id = args["stage_id"];
local subject_id = args["subject_id"];
local limit = args["limit"];
if not limit then
    limit = 18;
end
local condition_str="";
if stage_id ~= nil and tonumber(stage_id) ~= 0 then
    condition_str=condition_str.." and stage_id="..stage_id;
end
if subject_id ~= nil and tonumber(subject_id) ~= 0  then
    condition_str=condition_str.." and subject_id="..subject_id;
end
--获得我的错题总数
local query_sql = "SELECT game_id from t_yxx_game where url_web is not null And url_web <> '' AND MONTH(create_time)=MONTH(NOW()) - 1 "..condition_str.." ORDER BY create_time DESC limit " .. limit .. ";";

local rows = mysql_db:query(query_sql);
if not rows then
    ngx.print("{\"success\":\"false\",\"info\":\"查询数据出错。\"}");
    return;
end
--------------------------------------------------------------------------------------------------------------------------------------------------------
local gameArray = {}
for i=1,#rows do
    local game_info = ssdb_db:multi_hget("yxx_game_"..rows[i]["game_id"],"game_id","game_name","subject_id","type_id","user_count","create_time","url_web","thumb_url","quality_goods","stage_id","sort_type","web_version","ios_version","android_version","url_ios","url_android");
    local ssdb_info = {};
    ssdb_info["game_id"] = game_info[2];
    ssdb_info["game_name"] = game_info[4];
    ssdb_info["subject_id"]= game_info[6];
    ssdb_info["type_id"]= game_info[8];
    ssdb_info["user_count"] = game_info[10];
    ssdb_info["create_time"] = game_info[12];
    ssdb_info["url_web"] = game_info[14];
    ssdb_info["thumb_url"] = game_info[16];
    ssdb_info["quality_goods"] = game_info[18];
    ssdb_info["stage_id"] = game_info[20];
    ssdb_info["sort_type"] = game_info[22];
    ssdb_info["web_version"] = game_info[24];
    ssdb_info["ios_version"] = game_info[26];
    ssdb_info["android_version"] = game_info[28];
    ssdb_info["url_ios"] = game_info[30];
    ssdb_info["url_android"] = game_info[32];
    table.insert(gameArray, ssdb_info);
end
if #rows < limit then
    local query_sql = "SELECT game_id from t_yxx_game where  url_web is not null And url_web <> '' "..condition_str.." ORDER BY user_count DESC limit " .. limit-#rows .. ";";
    local rows = mysql_db:query(query_sql);
    if not rows then
        ngx.print("{\"success\":\"false\",\"info\":\"查询数据出错。\"}");
        return;
    end
    for i=1,#rows do
        local game_info = ssdb_db:multi_hget("yxx_game_"..rows[i]["game_id"],"game_id","game_name","subject_id","type_id","user_count","create_time","url_web","thumb_url","quality_goods","stage_id","sort_type","web_version","ios_version","android_version","url_ios","url_android");
        local ssdb_info = {};
        ssdb_info["game_id"] = game_info[2];
        ssdb_info["game_name"] = game_info[4];
        ssdb_info["subject_id"]= game_info[6];
        ssdb_info["type_id"]= game_info[8];
        ssdb_info["user_count"] = game_info[10];
        ssdb_info["create_time"] = game_info[12];
        ssdb_info["url_web"] = game_info[14];
        ssdb_info["thumb_url"] = game_info[16];
        ssdb_info["quality_goods"] = game_info[18];
        ssdb_info["stage_id"] = game_info[20];
        ssdb_info["sort_type"] = game_info[22];
        ssdb_info["web_version"] = game_info[24];
        ssdb_info["ios_version"] = game_info[26];
        ssdb_info["android_version"] = game_info[28];
        ssdb_info["url_ios"] = game_info[30];
        ssdb_info["url_android"] = game_info[32];
        table.insert(gameArray, ssdb_info);
    end
end

local gameListJson = {};
gameListJson.success = true;
gameListJson.list = gameArray;
ssdb_db:set_keepalive(0,v_pool_size);
mysql_db:set_keepalive(0,v_pool_size);
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(gameListJson);
ngx.say(responseJson);