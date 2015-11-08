--[[
@Author cuijinlong
@date 2015-6-18
--]]
local _WK = {};
--[[
	局部函数:微课APP更新日志
	参数：
	subject_id：学科ID
]]
function _WK:app_update_record_add(table)
    local dbUtil = require "yxx.tool.DbUtil";
    local tableUtil = require "yxx.tool.TableUtil";
    local ssdb_db = dbUtil:getSSDb();
    local mysql_db = dbUtil:getMysqlDb();
    local apk_version_id = ssdb_db:incr("apk_version_pk");--生成主键ID
    table["id"]= tonumber(apk_version_id[1]);-- ID
    ssdb_db:multi_hset("apk_version_info_"..apk_version_id[1],table);--微课app（ssdb）
    local k_v_table = tableUtil:convert_sql(table);
    local rows = mysql_db:query("INSERT INTO t_wklm_app_version("..k_v_table["k_str"]..") value("..k_v_table["v_str"]..")");
    if not rows then
        ngx.print("{\"success\":\"false\",\"info\":\"添加失败。\"}");
        return;
    end
    ssdb_db:set_keepalive(0,v_pool_size);
    mysql_db:set_keepalive(0,v_pool_size);
end

--[[
	局部函数:微课APP更新日志列表
	参数：
	subject_id：学科ID
]]
function _WK:app_update_record_list(page_size,page_number)
    local dbUtil = require "yxx.tool.DbUtil";
    local ssdb_db = dbUtil:getSSDb();
    local mysql_db = dbUtil:getMysqlDb();
    local total_row	= 0;
    local total_page = 0;
    local total_rows_sql = "SELECT count(1) as TOTAL_ROW from t_wklm_app_version where 1=1;";
    local total_query = mysql_db:query(total_rows_sql);
    if not total_query then
        return {success=false, info="查询数据出错。"};
    end
    total_row = total_query[1]["TOTAL_ROW"];
    total_page = math.floor((total_row+page_size-1)/page_size);
    local offset = page_size*page_number-page_size;
    local limit  = page_size;
    local query_sql = "select id from t_wklm_app_version where 1=1 order by create_time desc limit " .. offset .. "," .. limit .. ";";
    local rows, err = mysql_db:query(query_sql);
    if not rows then
        return {success=false, info="查询数据出错。"};
    end
    local appArray = {};
    for i=1,#rows do
        local app_info = ssdb_db:multi_hget("apk_version_info_"..rows[i]["id"],"app_name","app_version","remark","apk_url","create_time")
        local ssdb_info = {};
        ssdb_info["id"]= rows[i]["id"];
        ssdb_info["app_name"]= app_info[2];
        ssdb_info["app_version"] = app_info[4];
        ssdb_info["remark"] = app_info[6];
        ssdb_info["apk_url"] = app_info[8];
        ssdb_info["create_time"] = app_info[10];
        table.insert(appArray, ssdb_info);
    end
    --------------------------------------------------------------------------------------------------------------------------------------------------------
    local appListJson = {};
    appListJson.success = true;
    appListJson.total_row   = total_row;
    appListJson.total_page  = total_page;
    appListJson.page_number = page_number;
    appListJson.page_size   = page_size;
    appListJson.list = appArray;
    ssdb_db:set_keepalive(0,v_pool_size);
    mysql_db:set_keepalive(0,v_pool_size);
    return appListJson;
end

--[[
	局部函数:获得最新微课APP路径
]]
function _WK:app_last_info()
    local dbUtil = require "yxx.tool.DbUtil";
    local ssdb_db = dbUtil:getSSDb();
    local mysql_db = dbUtil:getMysqlDb();
    local query_sql = "select id from t_wklm_app_version where 1=1 order by create_time desc limit 1;";
    local rows, err = mysql_db:query(query_sql);
    if not rows then
        return {success=false, info="查询数据出错。"};
    end
    local app_info = ssdb_db:multi_hget("apk_version_info_"..rows[1]["id"],"app_name","app_version","remark","apk_url","create_time")
    local ssdb_info = {};
    ssdb_info["id"]= rows[1]["id"];
    ssdb_info["app_name"]= app_info[2];
    ssdb_info["app_version"] = app_info[4];
    ssdb_info["remark"] = app_info[6];
    ssdb_info["apk_url"] = app_info[8];
    ssdb_info["create_time"] = app_info[10];
    ssdb_db:set_keepalive(0,v_pool_size);
    mysql_db:set_keepalive(0,v_pool_size);
    return ssdb_info;
end

--[[
	局部函数:微课APP更新日志
	参数：
	subject_id：学科ID
]]
function _WK:app_update_record_delete(id)
    local dbUtil = require "yxx.tool.DbUtil";
    local ssdb_db = dbUtil:getSSDb();
    local mysql_db = dbUtil:getMysqlDb();
    local query_sql = "delete from t_wklm_app_version where id="..id;
    local rows = mysql_db:query(query_sql);
    if not rows then
        return {success=false, info="删除失败。"};
    end
    ssdb_db:multi_hdel("apk_version_info_"..id,"id","app_name","app_version","remark","apk_url","create_time")
    ssdb_db:set_keepalive(0,v_pool_size);
    mysql_db:set_keepalive(0,v_pool_size);
end

function _WK:getClassWkds(class_id,subject_id,pageSize,pageNumber)
    local MysqlUtil = require "yxx.tool.MysqlUtil";
    local SSDBUtil = require "yxx.tool.SSDBUtil";
    local redis = require "resty.redis"
    local cache = redis:new()
    local ok,err = cache:connect(v_redis_ip,v_redis_port)
    if not ok then
        return {};
    end
    local cjson = require "cjson";
    local db = MysqlUtil:getDb();
    local ssdb_db = SSDBUtil:getDb();
    local offset = pageSize*pageNumber-pageSize;
    local limit = pageSize;
    local str_maxmatches = pageNumber*100;
    local condition_sql = "";
    if class_id and string.len(class_id) == 0 then
        condition_sql = condition_sql.."filter=class_id,"..class_id..";";
    end
    if subject_id and string.len(subject_id) == 0 then
        condition_sql = condition_sql.."filter=subject_id,"..subject_id..";";
    end
    local query_sql = "SELECT SQL_NO_CACHE id FROM t_wkds_wktostudent_sphinxse where query=\'"..condition_sql.."maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit..";groupby=attr:WK_ID;sort=attr_desc:WK_ID;\';SHOW ENGINE SPHINX STATUS;";
    local wkds = db:query(query_sql);
    local wkds1 = db:read_result()
    local _,s_str = string.find(wkds1[1]["Status"],"found: ")
    local e_str = string.find(wkds1[1]["Status"],", time:")
    local totalRow = string.sub(wkds1[1]["Status"],s_str+1,e_str-1)
    local totalPage = math.floor((totalRow+pageSize-1)/pageSize)
    local responseObj = {};
    local wkds_tab = {};
    for j=1,#wkds do
        local tab = {};
        --去ssdb中获得微课id
        local wktostudent_info = ssdb_db:multi_hget("wktostudent_"..wkds[j]["id"],"wkds_id","create_time");
        local wkds_value = cache:hmget("wkds_"..wktostudent_info[2],"wkds_id_int","wkds_id_char","scheme_id",
            "structure_id","wkds_name","study_instr","teacher_name","play_count","score_average","create_time","download_count","downloadable","person_id","group_id","content_json","wk_type","wk_type_name","subject_id");
        tab.id = wktostudent_info[2];
        tab.wkds_id_int = wkds_value[1];
        tab.wkds_id_char = wkds_value[2];
        tab.scheme_id_int = wkds_value[3];
        tab.structure_id = wkds_value[4];
        tab.wkds_name = wkds_value[5];
        tab.study_instr = wkds_value[6];
        tab.teacher_name = wkds_value[7];
        tab.play_count = wkds_value[8];
        tab.score_average = wkds_value[9];
        tab.create_time = wktostudent_info[4];
        tab.download_count = wkds_value[11];
        --获得thumb_id
        local thumb_id = "";
        local content_json = wkds_value[15];
        local aa = ngx.decode_base64(content_json)
        local data = cjson.decode(aa)
        if #data.sp_list~=0 then
            local resource_info_id = data.sp_list[1].id
            if resource_info_id ~= ngx.null then
                local thumbid = ssdb_db:multi_hget("resource_"..resource_info_id,"thumb_id")
                if tostring(thumbid[2]) ~= "userdata: NULL" then
                    thumb_id = thumbid[2]
                end
            end
        else
            thumb_id = "E6648460-4FFD-E626-1C14-6FBF9F94A23C"
        end
        if not thumb_id or string.len(thumb_id) == 0 then
            thumb_id = "E6648460-4FFD-E626-1C14-6FBF9F94A23C"
        end
        tab.thumb_id = thumb_id;
        tab.downloadable = wkds_value[12];
        tab.person_id = wkds_value[13];
        tab.group_id = wkds_value[14];
        tab.content_json = wkds_value[15];
        tab.wk_type = wkds_value[16];
        tab.wk_type_name = wkds_value[17];
        tab.subject_id = wkds_value[18];
        --根据subject_id获得subject_name
        local subject_info = ssdb_db:multi_hget("subject_"..wkds_value[18],"subject_name");
        tab.subject_name = subject_info[2];
        wkds_tab[j] = tab;
    end
    responseObj.success = true;
    responseObj.list= wkds_tab;
    responseObj.totalPage = totalPage;
    responseObj.totalRow = totalRow;
    responseObj.pageNumber =pageNumber;
    responseObj.pageSize =pageSize;
    --放回到SSDB连接池
    ssdb_db:set_keepalive(0,v_pool_size)
    --redis放回连接池
    cache:set_keepalive(0,v_pool_size)
    --mysql放回连接池
    db:set_keepalive(0,v_pool_size)
    return responseObj;
end
return _WK
