local dbUtil = require "yxx.tool.DbUtil";
local PersonInfoModel = require "base.person.model.PersonInfoModel";
local SchoolModel = require "base.org.model.School";
local cjson = require "cjson";
local mysql_db = dbUtil:getMysqlDb();
local ssdb_db = dbUtil:getSSDb();
local query_sql = "SELECT SQL_NO_CACHE id FROM t_zy_info_sphinxse  WHERE query='sort=attr_desc:TS;filter=TYPE_ID,0;groupby=attr:zy_id;limit=6;'";
local rows,err = mysql_db:query(query_sql);
if not rows or not rows then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end
local zyArray = {};
for i=1,#rows do
    local zy_id = ssdb_db:multi_hget("homework_zy_student_relate_"..rows[i]["id"],"zy_id")
    if zy_id[2] then
        local zy_content = ssdb_db:hget("homework_zy_content",zy_id[2])
        if string.len(zy_content[1])>0 then
            local zy_info = {};
            if zy_content[1] then
                local zycon = cjson.decode(zy_content[1]);
                local personDetail = PersonInfoModel.getPersonDetail(self,zycon.teacher_id, 5);
                local SchoolDetail = SchoolModel.getById(self,personDetail.school_id);
                zy_info["zy_id"] = zy_id[2];
                zy_info["zy_name"] = zycon.zy_name;
                zy_info["create_time"] = zycon.create_time;
                zy_info["teacher_name"] = personDetail.person_name;
                zy_info["school_name"] = SchoolDetail.ORG_NAME;
                table.insert(zyArray, zy_info);
            end
        end
    end

end
local result={};
result["success"] = "true";
result["list"] = zyArray;
cjson.encode_empty_table_as_object(false);
local resultjson = cjson.encode(result);
ngx.say(resultjson)