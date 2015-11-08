--[[
@Author cuijinlong
@date 2015-6-22
--]]
local _App = {};
--[[
	局部函数：上传APP
	table
]]
function _App:upload_app(table)
    local dbUtil = require "yxx.tool.DbUtil";
    local tableUtil = require "yxx.tool.TableUtil";
    local mysql_db = dbUtil:getMysqlDb();
    local k_v_table = tableUtil:convert_sql(table);
    local rows = mysql_db:query("INSERT INTO t_yxx_topic_game_app("..k_v_table["k_str"]..") value("..k_v_table["v_str"]..")");
    if not rows then
        ngx.print("{\"success\":\"false\",\"info\":\"添加失败。\"}");
        return;
    end
    mysql_db:set_keepalive(0,v_pool_size);
end
--[[
	局部函数：查询APP
	topic_game：专题名
	subject_id：学科ID
]]
function _App:app_list(topic_game,subject_id)
    local dbUtil = require "yxx.tool.DbUtil";
    local mysql_db = dbUtil:getMysqlDb();
    local condition_str = "";
    if subject_id ~= nil and subject_id ~= "" then
        condition_str = condition_str.." and subject_id like '%,"..subject_id..",%'";
    end
    local rows = mysql_db:query("select id,topic_game,subject_id,url_apk,apk_version,url_ios,ios_version,create_time from t_yxx_topic_game_app where topic_game = "..topic_game..condition_str.." order by create_time desc limit 1");
    if not rows then
        ngx.print("{\"success\":\"false\",\"info\":\"查询数据出错。\"}");
        return;
    end
    local appArray = {};
    for i=1,#rows do
        local ssdb_info = {};
        ssdb_info["id"] = rows[i]["id"];
        ssdb_info["topic_game"] = rows[i]["topic_game"];
        ssdb_info["subject_id"] = rows[i]["subject_id"];
        ssdb_info["url_apk"] = rows[i]["url_apk"];
        ssdb_info["apk_version"] = rows[i]["apk_version"];
        ssdb_info["url_ios"] = rows[i]["url_ios"];
        ssdb_info["ios_version"] = rows[i]["ios_version"];
        ssdb_info["create_time"] = rows[i]["create_time"];
        table.insert(appArray, ssdb_info);
    end
    local appListJson = {};
    appListJson.success = true;
    appListJson.list = appArray;
    mysql_db:set_keepalive(0,v_pool_size);
    return appListJson;
end
--[[
	局部函数：查询APP
	topic_game：专题名
	subject_id：学科ID
]]
function _App:app_list_by_subject(subject_id_arr)
    local dbUtil = require "yxx.tool.DbUtil";
    local cjson = require "cjson";
    local ArrayUtil = require "yxx.tool.ArrayUtil";
    local mysql_db = dbUtil:getMysqlDb();

    local appArray = {};
    local array = {};
    for j=1,#subject_id_arr do
        local condition_str = "";
        if subject_id_arr[j] ~= nil and subject_id_arr[j] ~= "" then
            condition_str = condition_str.." and subject_id like '%,"..subject_id_arr[j]..",%'";
        end
        --ngx.log(ngx.ERR,"#####################".."select id,topic_game,subject_id,url_apk,apk_version,url_ios,ios_version,create_time from t_yxx_topic_game_app where topic_game = 2"..condition_str.." order by create_time desc limit 1");
        local rows = mysql_db:query("select id,topic_game,subject_id,url_apk,apk_version,url_ios,ios_version,create_time from t_yxx_topic_game_app where topic_game = 2"..condition_str.." order by create_time desc limit 1");
        if not rows then
            ngx.print("{\"success\":\"false\",\"info\":\"查询数据出错。\"}");
            return;
        end
        local j = 0;
        for i=1,#rows do
            j=j+1;
            if not ArrayUtil:arrayContain(array,tonumber(rows[i]["id"])) then
                local ssdb_info = {};
                ssdb_info["id"] = rows[i]["id"];
                ssdb_info["subject_id"] = rows[i]["subject_id"];
                ssdb_info["url_apk"] = rows[i]["url_apk"];
                ssdb_info["apk_version"] = rows[i]["apk_version"];
                table.insert(appArray, ssdb_info);
                array[j] = tonumber(rows[i]["id"]);
            end
        end
    end
    --把游戏的APP的更新信息也告诉给电子书包
    local rows = mysql_db:query("select id,id,subject_id,url_apk,apk_version from t_yxx_topic_game_app where topic_game = 1 and subject_id=-1 order by create_time desc limit 1");
    if rows and rows[1] then
        table.insert(appArray,rows[1]);
    end
    local appListJson = {};
    appListJson.success = true;
    appListJson.list = appArray;
    mysql_db:set_keepalive(0,v_pool_size);
    return appListJson;
end
--[[
	局部函数：删除APP
	id：ID
]]
function _App:app_del(id)
    local dbUtil = require "yxx.tool.DbUtil";
    local mysql_db = dbUtil:getMysqlDb();
    mysql_db:query("delete from t_yxx_topic_game_app where id="..id);
    mysql_db:set_keepalive(0,v_pool_size);
end
return _App;