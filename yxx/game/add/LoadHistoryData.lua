--[[
@Author cuijinlong
@date 2015-4-24
--]]
local dbUtil = require "yxx.tool.DbUtil";
local ssdb_db = dbUtil:getSSDb();
local mysql_db = dbUtil:getMysqlDb();
local query_sql = "select game_id,game_name,stage_id,subject_id,quality_goods,type_id,sort_type,user_count,create_time,url_web,web_version,url_android,android_version,url_ios,ios_version,thumb_url from t_yxx_game";
local rows = mysql_db:query(query_sql);
for i=1,#rows do
    local ssdb_info = {};
    ssdb_info["game_id"] = rows[i].game_id;
    ssdb_info["game_name"] = rows[i].game_name;
    ssdb_info["subject_id"]= rows[i].subject_id;
    ssdb_info["type_id"]= rows[i].type_id;
    ssdb_info["user_count"] = rows[i].user_count;
    ssdb_info["create_time"] = rows[i].create_time;
    ssdb_info["url_web"] = rows[i].url_web;
    ssdb_info["thumb_url"] = rows[i].thumb_url;
    ssdb_info["quality_goods"] = rows[i].quality_goods;
    ssdb_info["stage_id"] = rows[i].stage_id;
    ssdb_info["sort_type"] = rows[i].sort_type;
    ssdb_info["web_version"] = rows[i].web_version;
    ssdb_info["ios_version"] = rows[i].ios_version;
    ssdb_info["android_version"] = rows[i].android_version;
    ssdb_info["url_ios"] = rows[i].url_ios;
    ssdb_info["url_android"] = rows[i].url_android;
    ssdb_db:multi_hset("yxx_game_"..rows[i]["game_id"],ssdb_info);
end
ssdb_db:set_keepalive(0,v_pool_size);
mysql_db:set_keepalive(0,v_pool_size);