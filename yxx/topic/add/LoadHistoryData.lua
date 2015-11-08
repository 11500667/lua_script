--[[
@Author cuijinlong
@date 2015-4-24
--]]
local dbUtil = require "yxx.tool.DbUtil";
local ssdb_db = dbUtil:getSSDb();
local mysql_db = dbUtil:getMysqlDb();
local query_sql = "SELECT topic_id,topic_name,stage_id,subject_id,quality_goods,type_id,view_count,down_count,score,create_time,IFNULL(swf_url,'') AS swf_url,IFNULL(swf_version,'') AS swf_version,IFNULL(android_url,'') AS android_url,IFNULL(android_version,'') AS android_version,IFNULL(ios_url,'') AS ios_url,IFNULL(ios_version,'') AS ios_version,IFNULL(html_url,'') AS html_url,IFNULL(thumb_url,'') AS thumb_url  from t_yxx_topic;";
local rows = mysql_db:query(query_sql);
for i=1,#rows do
    ssdb_db:multi_hset("yxx_topic_"..rows[i]["topic_id"],
        "topic_id",rows[i]["topic_id"],
        "topic_name",rows[i]["topic_name"],
        "stage_id",rows[i]["stage_id"],
        "subject_id",rows[i]["subject_id"],
        "quality_goods",rows[i]["quality_goods"],
        "type_id",rows[i]["type_id"],
        "view_count",rows[i]["view_count"],
        "down_count",rows[i]["down_count"],
        "score",rows[i]["score"],
        "create_time",rows[i]["create_time"],
        "quality_goods",rows[i]["quality_goods"],
        "swf_url",rows[i]["swf_url"],
        "swf_version",rows[i]["swf_version"],
        "android_url",rows[i]["android_url"],
        "android_version",rows[i]["android_version"],
        "ios_url",rows[i]["ios_url"],
        "ios_version",rows[i]["ios_version"],
        "html_url",rows[i]["html_url"],
        "thumb_url",rows[i]["thumb_url"]);
end


ssdb_db:set_keepalive(0,v_pool_size);
mysql_db:set_keepalive(0,v_pool_size);