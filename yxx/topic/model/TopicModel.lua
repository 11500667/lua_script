--[[
@Author cuijinlong
@date 2015-5-22
--]]
local _Topic = {};
--[[
	局部函数:专题DAO类
]]
--------------------------------------------------------------------------------------------------------------------------------------------------------
--[[
	局部函数：添加专题分类
	参数：
	subject_id：学科ID
	topic_type_name：分类名称
]]
function _Topic:add_type(subject_id,topic_type_name)
	local dbUtil = require "yxx.tool.DbUtil";
	local mysql_db = dbUtil:getMysqlDb();
    local ssdb_db = dbUtil:getSSDb();
    local type_id = ssdb_db:incr("topic_type_pk",140);--生成主键ID
    ssdb_db:multi_hset("topic_type_"..type_id[1],"subject_id",subject_id,"topic_type_name",topic_type_name);
	local res, err, errno, sqlstate =  mysql_db:query("INSERT INTO t_topic_type("..
												 "subject_id,"..
                                                 "id,"..
												 "topic_type_name".. 		
												 ")"..
												 " VALUES ("..subject_id..","..type_id[1]..","..ngx.quote_sql_str(topic_type_name)..");");
	if not res then
		ngx.say("添加专题分类出错：", err, ": ", errno, ": ", sqlstate, ".");
		return
	end
	mysql_db:set_keepalive(0,v_pool_size);
     ssdb_db:set_keepalive(0,v_pool_size);
end
--[[
	局部函数：专题分类列表
	按学科查询方式：
	subject_id：学科ID
]]
function _Topic:type_list(subject_id)
	local dbUtil = require "yxx.tool.DbUtil";
	local mysql_db = dbUtil:getMysqlDb();
	local rows = mysql_db:query("select id,topic_type_name from t_topic_type where subject_id = "..subject_id);
	if not rows then
		ngx.print("{\"success\":\"false\",\"info\":\"查询数据出错。\"}");
		return;
	end
	local topicArray = {};
	for i=1,#rows do
		local ssdb_info = {};
		ssdb_info["topic_type_id"] = rows[i]["id"];
		ssdb_info["topic_type_name"] = rows[i]["topic_type_name"];
		table.insert(topicArray, ssdb_info);
	end
	local topicListJson = {};
	topicListJson.success = true;
	topicListJson.list = topicArray;
	mysql_db:set_keepalive(0,v_pool_size);
	return topicListJson;
end
--[[
	局部函数：编辑专题分类
	参数：
	topic_type_id：专题分类ID
	topic_type_name：分类名称
]]
function _Topic:edit_type(topic_type_id,topic_type_name)
    local dbUtil = require "yxx.tool.DbUtil";
    local mysql_db = dbUtil:getMysqlDb();
    local res =  mysql_db:query("update t_topic_type set topic_type_name="..ngx.quote_sql_str(topic_type_name).." where id="..topic_type_id);
    if not res then
        ngx.say("{\"success\":false,\"info\":\"修改失败\"}");
        return
    else
        ngx.say("{\"success\":true,\"info\":\"修改成功\"}");
    end
    mysql_db:set_keepalive(0,v_pool_size);
end
--[[
	局部函数：删除专题分类
	参数：
	topic_type_id：专题分类ID
]]
function _Topic:delete_type(topic_type_id)
    local dbUtil = require "yxx.tool.DbUtil";
    local mysql_db = dbUtil:getMysqlDb();
    local res =  mysql_db:query("delete from t_topic_type where id="..topic_type_id);
    if not res then
        ngx.say("{\"success\":false,\"info\":\"删除失败\"}");
        return
    else
        ngx.say("{\"success\":true,\"info\":\"删除成功\"}");
    end
    mysql_db:set_keepalive(0,v_pool_size);
end

--[[
	局部函数：专题添加
	参数：
	ssdb_info：主题VO
]]
function _Topic:upload_topic(table)
	local dbUtil = require "yxx.tool.DbUtil";
    local tableUtil = require "yxx.tool.TableUtil";
	local ssdb_db = dbUtil:getSSDb();
	local mysql_db = dbUtil:getMysqlDb();
	local topic_id = ssdb_db:incr("yxx_topic_pk",1);
    table["topic_id"] = tonumber(topic_id[1]);
	local result, err = ssdb_db:multi_hset("yxx_topic_"..topic_id[1],table);
	if not result then
		ngx.say("{\"success\":false,\"info\":\""..err.."\"}");
		return;
    end
    local k_v_table = tableUtil:convert_sql(table);
	local res, err =  mysql_db:query("insert into t_yxx_topic("..k_v_table["k_str"]..") value("..k_v_table["v_str"]..")");
    if not res then
		ngx.say("{\"success\":false,\"info\":\""..err.."\"}");
		return
    end
    mysql_db:set_keepalive(0,v_pool_size);
    ssdb_db:set_keepalive(0,v_pool_size);
end

--[[
	局部函数：专题编辑
]]
function _Topic:edit_topic(table)
    local dbUtil = require "yxx.tool.DbUtil";
    local ssdb_db = dbUtil:getSSDb();
    local mysql_db = dbUtil:getMysqlDb();
    local result, err = ssdb_db:multi_hset("yxx_topic_"..table["topic_id"],table);
    if not result then
        ngx.say("{\"success\":false,\"info\":\""..err.."\"}");
        return;
    end
    local sql = "UPDATE t_yxx_topic SET topic_name="
            ..ngx.quote_sql_str(table["topic_name"])
            ..",stage_id="..table["stage_id"]
            ..",subject_id="..table["subject_id"]
            ..",type_id="..table["type_id"];
    if table["swf_url"] then
        sql = sql..",swf_url="..ngx.quote_sql_str(table["swf_url"]);
    end
    if table["android_url"] then
        sql = sql..",android_url="..ngx.quote_sql_str(table["android_url"]);
    end
    if table["ios_url"] then
        sql = sql..",ios_url="..ngx.quote_sql_str(table["ios_url"]);
    end
    if table["thumb_url"] then
        sql = sql..",thumb_url="..ngx.quote_sql_str(table["thumb_url"]);
    end
    if table["swf_version"] then
        sql = sql..",swf_version="..ngx.quote_sql_str(table["swf_version"]);
    end
    if table["android_version"] then
        sql = sql..",android_version="..ngx.quote_sql_str(table["android_version"]);
    end
    if table["ios_version"] then
        sql = sql..",ios_version="..ngx.quote_sql_str(table["ios_version"]);
    end
    sql = sql.." where topic_id = "..table["topic_id"]
    local res, err =  mysql_db:query(sql);
    if not res then
        ngx.say("{\"success\":false,\"info\":\""..err.."\"}");
        return
    end
    ssdb_db:set_keepalive(0,v_pool_size);
    mysql_db:set_keepalive(0,v_pool_size);
end

--[[
	局部函数：专题编辑
]]
function _Topic:del_topic(topic_id)
    local dbUtil = require "yxx.tool.DbUtil";
    local ssdb_db = dbUtil:getSSDb();
    local mysql_db = dbUtil:getMysqlDb();
    ssdb_db:hclear("yxx_topic_"..topic_id);
    local res1, err =  mysql_db:query("delete from t_yxx_topic_user where topic_id="..topic_id);
    if not res1 then
        ngx.say("{\"success\":false,\"info\":\""..err.."\"}");
        return
    end
    local student_id_rows =  mysql_db:query("select student_id from t_yxx_topic_user where topic_id="..topic_id.." group by student_id");
    for i=1,#student_id_rows do
        ssdb_db:hclear("topic_student_"..topic_id.."_"..student_id_rows[i]["student_id"]);
    end
    local res, err =  mysql_db:query("delete from t_yxx_topic where topic_id="..topic_id);
    if not res then
        ngx.say("{\"success\":false,\"info\":\""..err.."\"}");
        return
    end
    ssdb_db:hclear("yxx_topic_"..topic_id);
    ssdb_db:set_keepalive(0,v_pool_size);
    mysql_db:set_keepalive(0,v_pool_size);
end

--[[
	局部函数：专题列表
	按学科查询方式：
	subject_id：学科ID
	sort_type：排序类型(1、录入时间 2:错题率)
	sort_num：升/降序
	pageSize:每页记录数
	pageNumber：页数
]]
---------------------------------------------------------------------------
function _Topic:topic_list(subject_id,topic_name,topic_type_id,android_ios,page_size,page_number)

	--------------------------------------------------------------------------------------------------------------------------------------------------------
	--初始化变量
	local dbUtil = require "yxx.tool.DbUtil";
	local ssdb_db = dbUtil:getSSDb();
	local mysql_db = dbUtil:getMysqlDb();
	local query_order = " ORDER BY create_time DESC";
	local query_condition = "";
	if subject_id ~= "-1" then
		query_condition = query_condition.." AND subject_id="..subject_id;
	end
	if topic_type_id ~= "-1" then 
		query_condition = query_condition.." AND type_id="..topic_type_id;
    end
    if android_ios then
        if android_ios == "1" then
            query_condition = query_condition.." AND ((android_url is not null And android_url <> '') OR swf_url like '%.swf%')";
        elseif android_ios == "2" then
            query_condition = query_condition.." AND ((ios_url is not null And ios_url <> '') OR swf_url like '%.swf%') ";
        else
            --query_condition = query_condition.." And swf_url is not null And swf_url <> '' ";
        end
    else
        query_condition = query_condition.." And swf_url is not null And swf_url <> '' and swf_url not like '%.exe%' ";
    end
	if not topic_name or string.len(topic_name)==0 then
		topic_name = "";
	else
		if topic_name and #topic_name>0 then
			query_condition = query_condition.." AND topic_name like '%"..topic_name.."%' ";
		end
    end

	--------------------------------------------------------------------------------------------------------------------------------------------------------
	--获得我的错题总数
	local total_rows_sql = "SELECT count(1) as TOTAL_ROW from t_yxx_topic where 1=1 "..query_condition..";";

    local total_query = mysql_db:query(total_rows_sql);
	if not total_query then
		return {success=false, info="查询数据出错。"};
    end
    local total_row	= 0;
    local total_page = 0;
	total_row = total_query[1]["TOTAL_ROW"];
	total_page = math.floor((total_row+page_size-1)/page_size);
	local offset = page_size*page_number-page_size;
	local limit  = page_size;   
	local query_sql = "SELECT topic_id from t_yxx_topic where 1=1 "..query_condition.. query_order .." limit " .. offset .. "," .. limit .. ";";
    local rows = mysql_db:query(query_sql);
	if not rows then
		ngx.print("{\"success\":\"false\",\"info\":\"查询数据出错。\"}");
		return;
    end
    local app_query_sql = "SELECT url_apk,apk_version,url_ios,ios_version from t_yxx_topic_game_app where topic_game=2 and subject_id like '%,".. subject_id ..",%' order by create_time desc limit 1;";
    --ngx.log(ngx.ERR, "----------------------".."SELECT TopicName,SubjectId,CreateTime,SwfUrl,HtmlUrl,ThumbUrl from t_xx_game where 1=1"..query_condition.. query_order .." limit " .. offset .. "," .. limit .. ";".."----------------------");
    local app_query = mysql_db:query(app_query_sql);
    if not app_query then
        ngx.print("{\"success\":\"false\",\"info\":\"查询数据出错。\"}");
        return;
    end
    local app_info = {};
    if #app_query > 0 then
        app_info["url_apk"] = app_query[1].url_apk;
        app_info["apk_version"] = app_query[1].apk_version;
        app_info["url_ios"]= app_query[1].url_ios;
        app_info["ios_version"]= app_query[1].ios_version;
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
        ssdb_info["view_count"] = topic_info[32];
        ssdb_info["down_count"] = topic_info[34];
		table.insert(topicArray, ssdb_info);
    end
    --------------------------------------------------------------------------------------------------------------------------------------------------------
	local topicListJson = {};
	topicListJson.success    = true;
	topicListJson.total_row   = total_row;
	topicListJson.total_page  = total_page;
	topicListJson.page_number = page_number;
	topicListJson.page_size   = page_size;
    topicListJson.app_info   = app_info;
	topicListJson.list = topicArray;
    mysql_db:set_keepalive(0,v_pool_size);
    ssdb_db:set_keepalive(0,v_pool_size);
	return topicListJson;
end


--[[
	局部函数：最近看过专题的记录
	student_id：学生ID
	class_id:班级ID
	topic_id:游戏ID
]]
function _Topic:add_topic_student(student_id,class_id,topic_id)
    local dbUtil = require "yxx.tool.DbUtil";
    local ssdb_db = dbUtil:getSSDb();
    local mysql_db = dbUtil:getMysqlDb();
    local query_count =  mysql_db:query("select count(1) as TOTAL_ROW from t_yxx_topic_user where topic_id="..topic_id.." and student_id=".. student_id);
    local sql = "";
    if tonumber(query_count[1]["TOTAL_ROW"]) > 0 then
        sql = "update t_yxx_topic_user set last_review_time=now() where topic_id=".. topic_id .." and student_id=".. student_id ;
    else
        sql = "insert into t_yxx_topic_user(topic_id,student_id,class_id,last_review_time) values(";
        sql = table.concat({sql,topic_id..","..student_id..","..class_id..",now());"});
    end
    local res, err =  mysql_db:query(sql);
    if not res then
        ngx.say("{\"success\":false,\"info\":\""..err.."\"}");
        return
    end
    local result, err = ssdb_db:multi_hset("topic_student_"..topic_id.."_"..student_id,"class_id",class_id,"last_review_time",ngx.localtime());
    if not result then
        ngx.say("{\"success\":false,\"info\":\""..err.."\"}");
        return;
    end
    _Topic:set_topic_view_sum(topic_id,student_id);
    mysql_db:set_keepalive(0,v_pool_size);
    ssdb_db:set_keepalive(0,v_pool_size);
end

--[[
	局部函数：查询学生最近玩的专题列表
	student_id：学生ID
	record_count：记录数
]]
function _Topic:topic_student_list(student_id,record_count,android_ios)
    --------------------------------------------------------------------------------------------------------------------------------------------------------
    --初始化变量
    local dbUtil = require "yxx.tool.DbUtil";
    local MysqlUtil = require "common.MysqlUtil";
    local ssdb_db = dbUtil:getSSDb();
    local mysql_db = MysqlUtil:getDb();
    local query_order = " ORDER BY t1.last_review_time DESC";
    local query_condition = " AND t1.student_id="..student_id;
    if android_ios then
        if android_ios == "1" then
            query_condition = query_condition.." AND ((android_url is not null And android_url <> '') OR swf_url like '%.swf%')";
        elseif android_ios == "2" then
            query_condition = query_condition.." AND ((ios_url is not null And ios_url <> '') OR swf_url like '%.swf%') ";
        else
            --query_condition = query_condition.." And swf_url is not null And swf_url <> '' ";
        end
    else
        query_condition = query_condition.." And swf_url is not null And swf_url <> '' and swf_url not like '%.exe%'  ";
    end
    --获得我的错题总数
    local query_sql = "SELECT t1.topic_id from t_yxx_topic_user t1 left join t_yxx_topic t2 on t1.topic_id=t2.topic_id where 1=1"..query_condition.. query_order .." limit " .. record_count.. ";";
    local rows = MysqlUtil:query(query_sql);
    local topicArray = {};
    local topic_id_record = "";
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
        ssdb_info["view_count"] = topic_info[32];
        ssdb_info["down_count"] = topic_info[34];
        table.insert(topicArray, ssdb_info);
        if topic_info[2] then
            topic_id_record = topic_id_record..topic_info[2]..","
        end
    end
    --如果学生没看专题，那么就显示12个默认的专题。

    topicArray = _Topic:fill_topic_student_list(student_id,rows,record_count,topic_id_record,topicArray,ssdb_db,android_ios);
    --------------------------------------------------------------------------------------------------------------------------------------------------------
    local topicListJson = {};
    topicListJson.success = true;
    topicListJson.list = topicArray;
    ssdb_db:set_keepalive(0,v_pool_size);
    MysqlUtil:close(mysql_db);
    return topicListJson;
end
--[[
	局部函数：空间要求如果学生没有玩游戏，那么也要在最近玩游戏的列表中现在12个游戏。
	student_id：学生ID
	record_count：记录数
]]
function _Topic:fill_topic_student_list(student_id,rows,fill_record_count,topic_id_record,topicArray,ssdb_db,android_ios)
    local cjson = require "cjson";
    local MysqlUtil = require "common.MysqlUtil";
    --ngx.log(ngx.ERR,"##############"..fill_record_count.."############"..#rows);
    if fill_record_count and #rows < tonumber(fill_record_count) then
        local subject_list = ngx.location.capture("/dsideal_yy/base/getSubjectByStudentId",{
            args={student_id = student_id}
        })
        local subjects;
        local subject_ids = "";
        if subject_list.status == 200 then
            subjects = cjson.decode(subject_list.body).list
        end

        for j=1,#subjects do
            if j == #subjects then
                subject_ids = subject_ids..subjects[j].subject_id;
            else
                subject_ids = subject_ids..subjects[j].subject_id..",";
            end
        end
        local query_condition = "";
        if android_ios then
            if android_ios == "1" then
                query_condition = query_condition.." AND ((android_url is not null And android_url <> '') OR swf_url like '%.swf%')";
            elseif android_ios == "2" then
                query_condition = query_condition.." AND ((ios_url is not null And ios_url <> '') OR swf_url like '%.swf%') ";
            else
                --query_condition = query_condition.." And swf_url is not null And swf_url <> '' ";
            end
        else
            query_condition = query_condition.." And swf_url is not null And swf_url <> '' and swf_url not like '%.exe%'  ";
        end
        local sql = "";
        if #rows > 0 and topic_id_record and string.len(topic_id_record)>0 then
            sql = "SELECT topic_id from t_yxx_topic where 1=1 and subject_id in (".. subject_ids ..")"..query_condition.." and topic_id not in (" .. string.sub(topic_id_record,0,#topic_id_record-1) ..") limit " .. fill_record_count - #rows.. ";";
        else
            sql = "SELECT topic_id from t_yxx_topic where 1=1 and subject_id in (".. subject_ids ..")"..query_condition.." limit " .. fill_record_count - #rows.. ";";
        end
        local records = MysqlUtil:query(sql);
        for i=1,#records do
            local topic_info = ssdb_db:multi_hget("yxx_topic_"..records[i]["topic_id"],"topic_id","topic_name","subject_id","create_time","swf_url","html_url","thumb_url","quality_goods","stage_id","type_id","swf_version","ios_url","ios_version","android_url","android_version","view_count","down_count");
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
            ssdb_info["view_count"] = topic_info[32];
            ssdb_info["down_count"] = topic_info[34];
            table.insert(topicArray, ssdb_info);
        end
    end
    return topicArray;
end
--[[
	局部函数：系统包含的所有专题总数
]]
function _Topic:topic_count()
    --初始化变量
    local dbUtil = require "yxx.tool.DbUtil";
    local mysql_db = dbUtil:getMysqlDb();
    local query_sql = "SELECT count(1) As topic_count from t_yxx_topic";
    local rows = mysql_db:query(query_sql);
    mysql_db:set_keepalive(0,v_pool_size);
    return rows[1]["topic_count"];
end
--[[
	局部函数：学生每次查看专题都需要记录一下，为了算出游戏的参与人总数统计
]]
function _Topic:set_topic_view_sum(topic_id,student_id)
    local dbUtil = require "yxx.tool.DbUtil";
    local ssdb_db = dbUtil:getSSDb();
    local stu_view_sum = ssdb_db:zget("topic_view_sum_"..topic_id,student_id);
    if stu_view_sum and stu_view_sum[1] and string.len(stu_view_sum[1])>0 then
        ssdb_db:zset("topic_view_sum_"..topic_id,student_id,tonumber(stu_view_sum[1])+1);
    else
        ssdb_db:zset("topic_view_sum_"..topic_id,student_id,1);
    end
    local view_sum = ssdb_db:zsum("topic_view_sum_"..topic_id,0,100000);
    if view_sum then
        local mysql_db = dbUtil:getMysqlDb();
        local query_sql = "update t_yxx_topic set view_count="..view_sum[1].." where topic_id="..topic_id;
        ssdb_db:multi_hset("yxx_topic_"..topic_id,"view_count",view_sum[1]);
        mysql_db:query(query_sql);
        mysql_db:set_keepalive(0,v_pool_size);
    end
    ssdb_db:set_keepalive(0,v_pool_size);
end
--[[
	局部函数：获得所有的游戏的参与人总数
]]
function _Topic:get_topic_view_sum(topic_id)
    local dbUtil = require "yxx.tool.DbUtil";
    local ssdb_db = dbUtil:getSSDb();
    local view_sum = ssdb_db:zsum("topic_view_sum_"..topic_id,0,100000);
    ssdb_db:set_keepalive(0,v_pool_size);
    return view_sum[1];
end

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- 返回_Topic对象
return _Topic;