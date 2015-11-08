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
local query_sql = "SELECT topic_id from t_yxx_topic where swf_url is not null and swf_url <> ''  AND MONTH(create_time)=MONTH(NOW()) - 1"..condition_str.." ORDER BY create_time DESC limit " .. limit .. ";";
local rows = mysql_db:query(query_sql);
if not rows then
    ngx.print("{\"success\":\"false\",\"info\":\"查询数据出错。\"}");
    return;
end
--------------------------------------------------------------------------------------------------------------------------------------------------------
local topicArray = {}
for i=1,#rows do
    local topic_info = ssdb_db:multi_hget("yxx_topic_"..rows[i]["topic_id"],"topic_id","topic_name","subject_id","create_time","swf_url","html_url","thumb_url","quality_goods","stage_id","type_id","swf_version","ios_url","ios_version","android_url","android_version","view_count","down_count");
    if not topic_info then
        ngx.say("{\"success\":false}");
        return;
    end
    local ssdb_info = {};
    ssdb_info["topic_id"] = topic_info[2];
    ssdb_info["topic_name"] = topic_info[4];									--试题ID
    ssdb_info["subject_id"]= topic_info[6];									    --学科
    ssdb_info["create_time"] = topic_info[8];								    --试题类型名称
    ssdb_info["swf_url"] = topic_info[10];  									--专题文件名称路径
    ssdb_info["html_url"] = topic_info[12];  									--html结构的路径
    ssdb_info["thumb_url"] = topic_info[14];									--缩略图文件路径
    ssdb_info["quality_goods"] = topic_info[16];                                --是否是精品
    ssdb_info["stage_id"] = topic_info[18];
    ssdb_info["type_id"] = topic_info[20];
    ssdb_info["swf_version"] = topic_info[22];
    ssdb_info["ios_url"] = topic_info[24];
    ssdb_info["ios_version"] = topic_info[26];
    ssdb_info["android_url"] = topic_info[28];
    ssdb_info["android_version"] = topic_info[30];
    ssdb_info["view_count"] = topic_info[32] and topic_info[32] or 0;
    ssdb_info["down_count"] = topic_info[34] and topic_info[34] or 0;
    table.insert(topicArray, ssdb_info);
end

if #rows < limit then
    local query_sql = "SELECT topic_id from t_yxx_topic where swf_url is not null and swf_url <> '' "..condition_str.." ORDER BY view_count DESC limit " .. limit -#rows .. ";";
    local rows = mysql_db:query(query_sql);
    if not rows then
        ngx.print("{\"success\":\"false\",\"info\":\"查询数据出错。\"}");
        return;
    end
    for i=1,#rows do
        local topic_info = ssdb_db:multi_hget("yxx_topic_"..rows[i]["topic_id"],"topic_id","topic_name","subject_id","create_time","swf_url","html_url","thumb_url","quality_goods","stage_id","type_id","swf_version","ios_url","ios_version","android_url","android_version","view_count","down_count");
        if not topic_info then
            ngx.say("{\"success\":false}");
            return;
        end
        local ssdb_info = {};
        ssdb_info["topic_id"] = topic_info[2];
        ssdb_info["topic_name"] = topic_info[4];									--试题ID
        ssdb_info["subject_id"]= topic_info[6];									    --学科
        ssdb_info["create_time"] = topic_info[8];								    --试题类型名称
        ssdb_info["swf_url"] = topic_info[10];  									--专题文件名称路径
        ssdb_info["html_url"] = topic_info[12];  									--html结构的路径
        ssdb_info["thumb_url"] = topic_info[14];									--缩略图文件路径
        ssdb_info["quality_goods"] = topic_info[16];                                --是否是精品
        ssdb_info["stage_id"] = topic_info[18];
        ssdb_info["type_id"] = topic_info[20];
        ssdb_info["swf_version"] = topic_info[22];
        ssdb_info["ios_url"] = topic_info[24];
        ssdb_info["ios_version"] = topic_info[26];
        ssdb_info["android_url"] = topic_info[28];
        ssdb_info["android_version"] = topic_info[30];
        ssdb_info["view_count"] = topic_info[32] and topic_info[32] or 0;
        ssdb_info["down_count"] = topic_info[34] and topic_info[34] or 0;
        table.insert(topicArray, ssdb_info);
    end
end
local topicListJson = {};
topicListJson.success = true;
topicListJson.list = topicArray;
ssdb_db:set_keepalive(0,v_pool_size);
mysql_db:set_keepalive(0,v_pool_size);
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(topicListJson);
ngx.say(responseJson);