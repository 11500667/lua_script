
local dbUtil = require "yxx.tool.DbUtil";
local cjson = require "cjson";
local mysql_db = dbUtil:getMysqlDb();
local ssdb_db = dbUtil:getSSDb();
local res =  mysql_db:query("select topic_type_id,subject_id,topic_type_name from t_topic_type");
for i=1,#res do
    ssdb_db:multi_hset("topic_type_"..res[i].topic_type_id,"subject_id",res[i].subject_id,"topic_type_name",cjson.encode(res[i].topic_type_name));
end
mysql_db:set_keepalive(0,v_pool_size);
ssdb_db:set_keepalive(0,v_pool_size);