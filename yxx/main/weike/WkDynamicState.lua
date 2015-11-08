local dbUtil = require "yxx.tool.DbUtil";
local PersonInfoModel = require "base.person.model.PersonInfoModel";
local SchoolModel = require "base.org.model.School";
local cjson = require "cjson";
local mysql_db = dbUtil:getMysqlDb();
local ssdb_db = dbUtil:getSSDb();
local cache = dbUtil:getRedis();
local query_sql = "SELECT id FROM t_wkds_info WHERE type=2 and type_id=6 and identity_id=5 and b_delete=0 and isdraft=0 order by create_time desc limit 12";
local rows,err = mysql_db:query(query_sql);
if not rows or not rows then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end
local wkArray = {};
for i=1,#rows do
    local wk_info = {};
    local wkds_value = cache:hmget("wkds_"..rows[i]["id"],"wkds_name","person_id","teacher_name","create_time");
    local personDetail = PersonInfoModel:getPersonDetail(wkds_value[2],5);
    local SchoolDetail = SchoolModel:getById(personDetail.school_id);
    wk_info.school_name = SchoolDetail and  SchoolDetail.ORG_NAME or "";
    wk_info.id = rows[i]["id"];
    wk_info.wkds_name = wkds_value[1];
    wk_info.teacher_name = wkds_value[3];
    wk_info.create_time = wkds_value[4];
    table.insert(wkArray, wk_info);
end
local result={};
result["success"] = "true";
result["list"] = wkArray;
cjson.encode_empty_table_as_object(false);
local resultjson = cjson.encode(result);
ngx.say(resultjson)