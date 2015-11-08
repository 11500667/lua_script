--[[
@Author cuijinlong
@date 2015-5-22
--]]
local _Game = {};
--[[
	局部函数:游戏DAO类
]]
--------------------------------------------------------------------------------------------------------------------------------------------------------
--[[
	局部函数：添加游戏分类
	参数：
	subject_id：学科ID
	game_type_name：分类名称
]]
function _Game:add_type(subject_id,game_type_name)
	local dbUtil = require "yxx.tool.DbUtil";
	local mysql_db = dbUtil:getMysqlDb();
	local res, err, errno, sqlstate =  mysql_db:query("INSERT INTO t_game_type("..
												 "subject_id,"..			
												 "game_type_name".. 		
												 ")"..
												 " VALUES ( ".. subject_id..","..ngx.quote_sql_str(game_type_name)..");");
	if not res then
		ngx.say("添加游戏分类出错：", err, ": ", errno, ": ", sqlstate, ".");
		return
    else
        ngx.say("{\"success\":true,\"info\":\"保存成功\"}");
	end
	mysql_db:set_keepalive(0,v_pool_size);
end
--[[
	局部函数：游戏分类列表
	按学科查询方式：
	subject_id：学科ID
]]
function _Game:type_list(subject_id)
	local dbUtil = require "yxx.tool.DbUtil";
	local mysql_db = dbUtil:getMysqlDb();
	local rows = mysql_db:query("select id,game_type_name from t_game_type where subject_id = "..subject_id);
	if not rows then
		ngx.print("{\"success\":\"false\",\"info\":\"查询数据出错。\"}");
		return;
	end
	local gameArray = {};
	for i=1,#rows do
		local ssdb_info = {};
		ssdb_info["game_type_id"] = rows[i]["id"];
		ssdb_info["game_type_name"] = rows[i]["game_type_name"];
		table.insert(gameArray, ssdb_info);
	end
	local gameListJson = {};
	gameListJson.success = true;
	gameListJson.list = gameArray;
	mysql_db:set_keepalive(0,v_pool_size);
	return gameListJson;
end
--[[
	局部函数：编辑游戏分类
	参数：
	game_type_id：游戏分类ID
	game_type_name：分类名称
]]
function _Game:edit_type(game_type_id,game_type_name)
    local dbUtil = require "yxx.tool.DbUtil";
    local mysql_db = dbUtil:getMysqlDb();
    local res =  mysql_db:query("update t_game_type set game_type_name="..ngx.quote_sql_str(game_type_name).." where id="..game_type_id);
    if not res then
        ngx.say("{\"success\":false,\"info\":\"修改失败\"}");
        return
    else
        ngx.say("{\"success\":true,\"info\":\"修改成功\"}");
    end
    mysql_db:set_keepalive(0,v_pool_size);
end
--[[
	局部函数：删除游戏分类
	参数：
	game_type_id：游戏分类ID
]]
function _Game:delete_type(game_type_id)
    local dbUtil = require "yxx.tool.DbUtil";
    local mysql_db = dbUtil:getMysqlDb();
    local res =  mysql_db:query("delete from t_game_type where id="..game_type_id);
    if not res then
        ngx.say("{\"success\":false,\"info\":\"删除失败\"}");
        return
    else
        ngx.say("{\"success\":true,\"info\":\"删除成功\"}");
    end
    mysql_db:set_keepalive(0,v_pool_size);
end

--[[
	局部函数：游戏添加
]]
function _Game:upload_game(table)
    local dbUtil = require "yxx.tool.DbUtil";
    local tableUtil = require "yxx.tool.TableUtil";
    local ssdb_db = dbUtil:getSSDb();
    local mysql_db = dbUtil:getMysqlDb();
    local game_id = ssdb_db:incr("yxx_game_pk",1);
    table["game_id"] = game_id[1];
    local result, err = ssdb_db:multi_hset("yxx_game_"..game_id[1],table);
    if not result then
        ngx.say("{\"success\":false,\"info\":\""..err.."\"}");
        return;
    end
    local k_v_table = tableUtil:convert_sql(table);
    local res, err =  mysql_db:query("insert into t_yxx_game("..k_v_table["k_str"]..") value("..k_v_table["v_str"]..")");
    if not res then
        ngx.say("{\"success\":false,\"info\":\""..err.."\"}");
        return
    end
    ssdb_db:set_keepalive(0,v_pool_size);
    mysql_db:set_keepalive(0,v_pool_size);
end
--[[
	局部函数：游戏编辑
]]
function _Game:edit_game(table)
    local dbUtil = require "yxx.tool.DbUtil";
    local ssdb_db = dbUtil:getSSDb();
    local mysql_db = dbUtil:getMysqlDb();
    local result, err = ssdb_db:multi_hset("yxx_game_"..table["game_id"],table);
    if not result then
        ngx.say("{\"success\":false,\"info\":\""..err.."\"}");
        return;
    end
    local sql = "UPDATE t_yxx_game SET game_name="
                ..ngx.quote_sql_str(table["game_name"])
                ..",stage_id="..table["stage_id"]
                ..",subject_id="..table["subject_id"]
                ..",type_id="..table["type_id"]
                ..",sort_type="..table["sort_type"];
    if table["url_web"] then
        sql = sql..",url_web="..ngx.quote_sql_str(table["url_web"]);
    end
    if table["url_android"] then
        sql = sql..",url_android="..ngx.quote_sql_str(table["url_android"]);
    end
    if table["android_version"] then
        sql = sql..",android_version="..ngx.quote_sql_str(table["android_version"]);
    end
    if table["url_ios"] then
        sql = sql..",url_ios="..ngx.quote_sql_str(table["url_ios"]);
    end
    if table["ios_version"] then
        sql = sql..",ios_version="..ngx.quote_sql_str(table["ios_version"]);
    end
    if table["thumb_url"] then
        sql = sql..",thumb_url="..ngx.quote_sql_str(table["thumb_url"]);
    end
    sql = sql.." where game_id = "..table["game_id"];
    local res, err =  mysql_db:query(sql);
    if not res then
        ngx.say("{\"success\":false,\"info\":\""..err.."\"}");
        return
    end
    ssdb_db:set_keepalive(0,v_pool_size);
    mysql_db:set_keepalive(0,v_pool_size);
end


--[[
	局部函数：游戏删除
]]
function _Game:del_game(game_id)
    local dbUtil = require "yxx.tool.DbUtil";
    local ssdb_db = dbUtil:getSSDb();
    local mysql_db = dbUtil:getMysqlDb();
    local res1, err =  mysql_db:query("delete from t_yxx_game_user where game_id="..game_id);
    if not res1 then
        ngx.say("{\"success\":false,\"info\":\""..err.."\"}");
        return
    end
    local student_id_rows, err =  mysql_db:query("select student_id from t_yxx_game_user where game_id="..game_id.." group by student_id");
    for i=1,#student_id_rows do
        ssdb_db:hclear("game_student_"..game_id.."_"..student_id_rows[i]["student_id"]);
    end
    local res, err =  mysql_db:query("delete from t_yxx_game where game_id="..game_id);
    if not res then
        ngx.say("{\"success\":false,\"info\":\""..err.."\"}");
        return
    end
    ssdb_db:hclear("yxx_game_"..game_id);
    ssdb_db:set_keepalive(0,v_pool_size);
    mysql_db:set_keepalive(0,v_pool_size);
end

--[[
	局部函数：游戏列表
	按学科查询方式：
	subject_id：学科ID
	sort_type：排序类型(1、录入时间 2:错题率)
	sort_num：升/降序
	pageSize:每页记录数
	pageNumber：页数
]]
function _Game:game_list(subject_id,game_name,type_id,android_ios,sort_type,sort_order,page_size,page_number)
	--------------------------------------------------------------------------------------------------------------------------------------------------------
	--初始化变量
	local dbUtil = require "yxx.tool.DbUtil";
	local ssdb_db = dbUtil:getSSDb();
	local mysql_db = dbUtil:getMysqlDb();
	local query_order = "";
    local query_order_model = "";
    if sort_order then
        if sort_order == "1" then
            query_order_model = "ASC";
        else
            query_order_model = "DESC";
        end
    end
    if sort_type then
        if sort_type == "1" then
            --参与人数
            query_order =  " ORDER BY t1.user_count "..query_order_model
        elseif sort_type == "2" then
            --按上限时间
            query_order =  " ORDER BY t1.create_time "..query_order_model
        end
    else
        --默认
        query_order =  " ORDER BY t1.create_time DESC"
    end
	local query_condition = "";
	if subject_id ~= "-1" then
		query_condition = query_condition.." AND t1.subject_id="..subject_id;
    end
    if android_ios then
        if android_ios == "1" then
            query_condition = query_condition.." AND ((t1.url_android is not null And t1.url_android <> '') OR t1.url_web like '%.swf%')";
        elseif android_ios == "2" then
            query_condition = query_condition.." AND ((t1.url_ios is not null And t1.url_ios <> '')  OR t1.url_web like '%.swf%')";
        else
            --query_condition = query_condition.." AND t1.url_web is not null And t1.url_web <> ''";
        end
    else
        query_condition = query_condition.." AND t1.url_web is not null And t1.url_web <> ''";
    end
	if type_id and type_id ~= "-1" then
		query_condition = query_condition.." AND t1.type_id="..type_id;
	end
	if not game_name or string.len(game_name)==0 then
		game_name = ""
	else
	    --如果搜索关键字不为空就把传过来的base64进行编码转成真实的内容
		if game_name and #game_name>0 then
			query_condition = query_condition.." AND t1.game_name like '%"..game_name.."%' ";
		end
    end
	--------------------------------------------------------------------------------------------------------------------------------------------------------
	--获得我的错题总数
	local total_rows_sql = "SELECT count(1) as TOTAL_ROW from t_yxx_game t1 where 1=1 "..query_condition..";";
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
	local query_sql = "SELECT t1.game_id,t2.game_type_name from t_yxx_game t1 left join t_game_type t2 on t1.type_id=t2.id where 1=1"..query_condition.. query_order .." limit " .. offset .. "," .. limit .. ";";
	--ngx.log(ngx.ERR, "----------------------"..query_sql.."----------------------");
	local rows = mysql_db:query(query_sql);
	if not rows then
		ngx.print("{\"success\":\"false\",\"info\":\"查询数据出错。\"}");
		return;
	end
    local app_query_sql = "SELECT url_apk,apk_version,url_ios,ios_version from t_yxx_topic_game_app where topic_game=1 order by create_time desc limit 1;";
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
	local gameArray = {};
	for i=1,#rows do
        local game_info = ssdb_db:multi_hget("yxx_game_"..rows[i]["game_id"],"game_id","game_name","subject_id","type_id","user_count","create_time","url_web","thumb_url","quality_goods","stage_id","sort_type","web_version","ios_version","android_version","url_ios","url_android");
        local class_play_count = ssdb_db:zcount("game_class_play_count"..rows[i]["game_id"], 0, 100000);
        local ssdb_info = {};
        ssdb_info["game_id"] = game_info[2];
		ssdb_info["game_name"] = game_info[4];
		ssdb_info["subject_id"]= game_info[6];
        ssdb_info["type_id"]= game_info[8];
        ssdb_info["type_name"]= rows[i]["game_type_name"];
        ssdb_info["user_count"] = game_info[10];
        ssdb_info["class_play_count"] = class_play_count[1] and class_play_count[1] or 0;
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
    --------------------------------------------------------------------------------------------------------------------------------------------------------
	local gameListJson = {};
	gameListJson.success    = true;
	gameListJson.total_row   = total_row;
	gameListJson.total_page  = total_page;
	gameListJson.page_number = page_number;
	gameListJson.page_size   = page_size;
    gameListJson.app_info =app_info;
	gameListJson.list = gameArray;
	ssdb_db:set_keepalive(0,v_pool_size);
	mysql_db:set_keepalive(0,v_pool_size);
	return gameListJson;
end

--[[
	局部函数：最近玩过游戏的记录
	按最近玩过游戏的记录查询方式：
	student_id：学生ID
	class_id:班级ID
	game_id:游戏ID
]]
--function _Game:add_game_student_new(student_id,class_id,game_id)
--    local dbUtil = require "student.tool.DbUtil";
--    local ssdb_db = dbUtil:getSSDb();
--    local mysql_db = dbUtil:getMysqlDb();
--    local pass_test = ssdb_db:zget("student_game_"..class_id.."_"..game_id,student_id);--学生玩游戏过关数
--    local pass_test_temp =(pass_test and pass_test[1]) and tonumber(pass_test[1]) or 0;
--    local query_count =  mysql_db:query("select count(1) as TOTAL_ROW from t_yxx_game_user where game_id="..game_id.." and student_id=".. student_id);
--    local sql = "";
--    if tonumber(query_count[1]["TOTAL_ROW"]) > 0 then
--        sql = "update t_yxx_game_user set toll_gate = "..pass_test_temp..",last_game_time=now() where game_id=".. game_id .. " and student_id=".. student_id;
--    else
--        sql = "insert into t_yxx_game_user(game_id,student_id,class_id,toll_gate,favorite,recommend,last_game_time) values(";
--        sql = table.concat({sql,game_id..","..student_id..","});
--        sql = table.concat({sql,class_id..","..pass_test_temp..",null,null,now());"});
--    end
--    local res, err =  mysql_db:query(sql);
--    if not res then
--        ngx.say("{\"success\":false,\"info\":\""..err.."\"}");
--        return
--    end
--    local result, err = ssdb_db:multi_hset("game_student_"..game_id.."_"..student_id,
--        "class_id",class_id,"toll_gate",pass_test_temp,
--        "favorite","","recommend","",
--        "last_game_time",ngx.localtime());
--    if not result then
--        ngx.say("{\"success\":false,\"info\":\""..err.."\"}");
--        return;
--    end
--    ssdb_db:set_keepalive(0,v_pool_size);
--    mysql_db:set_keepalive(0,v_pool_size);
--end
--[[
	局部函数：最近玩过游戏的记录
	按最近玩过游戏的记录查询方式：
	table：学生玩游戏的详情
]]
function _Game:add_game_student(table)
    local dbUtil = require "yxx.tool.DbUtil";
    local tableUtil = require "yxx.tool.TableUtil";
    local ssdb_db = dbUtil:getSSDb();
    local mysql_db = dbUtil:getMysqlDb();
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    _Game:set_game_play_count(table.game_id,table.student_id,table.class_id);
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    local query_count =  mysql_db:query("select count(1) as TOTAL_ROW from t_yxx_game_user where game_id="..table.game_id.." and student_id="..table.student_id);
    local sql = "";
    if tonumber(query_count[1]["TOTAL_ROW"]) > 0 then
        if not table.last_game_result then
            --情况1：点击游戏还没有玩
            local last_pass_result_time = ssdb_db:multi_hget("game_student_"..table.game_id.."_"..table.student_id,"last_pass_result_time");
            table["last_pass_result_time"] = last_pass_result_time[2];
            sql = "update t_yxx_game_user set last_game_time=now() "..
                    " where game_id="..table.game_id.." and student_id="..table.student_id;
        else
            --情况2：玩过关的时候
            table["last_pass_result_time"] = ngx.localtime();
            sql = "update t_yxx_game_user set game_result=".. table.game_result..
                    ",last_game_result="..table.last_game_result..
                    ",last_pass_result_time=now(),last_game_time=now()"..
                    " where game_id="..table.game_id.." and student_id="..table.student_id;
        end
    else
        local k_v_table = tableUtil:convert_sql(table);
        sql = "insert into t_yxx_game_user("..k_v_table["k_str"]..") value("..k_v_table["v_str"]..")";
    end
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    local res, err =  mysql_db:query(sql);
    if not res then
        ngx.say("{\"success\":false,\"info\":\""..err.."\"}");
        return
    end
    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    local result, err = ssdb_db:multi_hset("game_student_"..table.game_id.."_"..table.student_id,table);
    if not result then
        ngx.say("{\"success\":false,\"info\":\""..err.."\"}");
        return;
    end

    -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    ssdb_db:set_keepalive(0,v_pool_size);
    mysql_db:set_keepalive(0,v_pool_size);
end
--[[
	局部函数：记录学生的玩游戏的结果，判断本次玩游戏是不是最好成绩，如果是那么更新数据库的game_result
	按最近玩过游戏的记录查询方式：
	table：学生玩游戏的详情
]]
function _Game:get_game_reslut(table)
    local dbUtil = require "yxx.tool.DbUtil";
    local ssdb_db = dbUtil:getSSDb();
    local game_result_arr = ssdb_db:multi_hget("game_student_"..table.game_id.."_"..table.student_id,"game_result")
    if game_result_arr and game_result_arr[2] then
        if table.game_result and tonumber(table.game_result) < tonumber(game_result_arr[2]) then
            table.game_result = game_result_arr[2];
        end
    end
    ssdb_db:set_keepalive(0,v_pool_size);
    return table;
end
--[[
	局部函数：记录学生的玩游戏的结果，判断本次玩游戏是不是最好成绩，如果是那么更新数据库的game_result
	按最近玩过游戏的记录查询方式：
	table：学生玩游戏的详情
]]
function _Game:get_stu_game_dynamic(game_id,class_id)
    local dbUtil = require "yxx.tool.DbUtil";
    local PersonInfoModel = require "base.person.model.PersonInfoModel";
    local ssdb_db = dbUtil:getSSDb();
    local mysql_db = dbUtil:getMysqlDb();
    local return_table={}
    local game_info = ssdb_db:multi_hget("yxx_game_"..game_id,"sort_type");
    if game_info[2] then
        local sort_type = game_info[2];
        local query_sql = "SELECT student_id from t_yxx_game_user where game_result is not null and class_id="..class_id.." and game_id="..game_id.." order by last_game_time desc limit 20";
        local rows = mysql_db:query(query_sql);
        if not rows then
            ngx.say("{\"success\":\"false\",\"info\":\"查询学生游戏记录出错。\"}");
            return;
        end
        local stu_game_dynamic = {};
        for i=1,#rows do
            local game_student_info = ssdb_db:multi_hget("game_student_"..game_id.."_"..rows[i].student_id,"last_game_result","last_pass_result_time");
            local table_info = {};
            table_info.student_id = rows[i].student_id;
            table_info.student_name = PersonInfoModel:getPersonName(rows[i].student_id,6);
            table_info.sort_type = sort_type;
            table_info.last_game_result = game_student_info[2];
            table_info.last_pass_result_time = game_student_info[4];
            table_info.server_current_time = ngx.localtime();
            table.insert(stu_game_dynamic, table_info);
        end
        return_table["success"] = true;
        return_table["list"] = stu_game_dynamic;
    end
    ssdb_db:set_keepalive(0,v_pool_size);
    mysql_db:set_keepalive(0,v_pool_size);
    return return_table;
end
--------------------------------------------------------------------------------------------------------------------------------------------------------
--[[
	局部函数：查询学生最近玩的游戏列表
	按学生查询最近玩游戏列表方式：
	student_id：学生ID
	record_count：记录数
]]
function _Game:game_student_list(student_id,record_count,android_ios)
    --------------------------------------------------------------------------------------------------------------------------------------------------------
    --初始化变量
    local cjson = require "cjson"
    local dbUtil = require "yxx.tool.DbUtil";
    local MysqlUtil = require "common.MysqlUtil";
    local ssdb_db = dbUtil:getSSDb();
    local mysql_db = MysqlUtil:getDb();
    local query_order = " ORDER BY t1.last_game_time DESC";
    local query_condition = " AND t1.student_id="..student_id;
    if android_ios then
        if android_ios == "1" then
            --Android平台
            query_condition = query_condition.." AND ((t2.url_android is not null And t2.url_android <> '') OR t2.url_web like '%.swf%')";
        elseif android_ios == "2" then
            --Ios平台
            query_condition = query_condition.." AND ((t2.url_ios is not null And t2.url_ios <> '')  OR t2.url_web like '%.swf%')";
        else
            --Web平台
            --query_condition = query_condition.." AND t2.url_web is not null And t2.url_web <> ''";
        end
    else
        query_condition = query_condition.." AND t2.url_web is not null And t2.url_web <> ''";
    end
    --获得我的错题总数
    local query_sql = "SELECT t1.game_id,t3.game_type_name from t_yxx_game_user t1 left join t_yxx_game t2 on t1.game_id=t2.game_id left join t_game_type t3 on t2.type_id=t3.id where 1=1"..query_condition.. query_order .." limit " .. record_count.. ";";
    --ngx.log(ngx.ERR, "----------------------"..query_sql.."----------------------");
    local rows = mysql_db:query(query_sql);
    if not rows then
        ngx.print("{\"success\":\"false\",\"info\":\"查询数据出错。\"}");
        return;
    end

    local app_query_sql = "SELECT url_apk,apk_version,url_ios,ios_version from t_yxx_topic_game_app where topic_game=1 order by create_time desc limit 1;";
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
    local gameArray = {};
    local game_id_record = "";
    for i=1,#rows do
        local game_info = ssdb_db:multi_hget("yxx_game_"..rows[i]["game_id"],"game_id","game_name","subject_id","type_id","user_count","create_time","url_web","thumb_url","quality_goods","stage_id","sort_type","web_version","ios_version","android_version","url_ios","url_android");
        local class_play_count = ssdb_db:zcount("game_class_play_count"..rows[i]["game_id"], 0, 100000);
        local ssdb_info = {};
        ssdb_info["game_id"] = game_info[2];
        ssdb_info["game_name"] = game_info[4];
        ssdb_info["subject_id"]= game_info[6];
        ssdb_info["type_id"]= game_info[8];
        ssdb_info["type_name"]= rows[i]["game_type_name"];
        ssdb_info["user_count"] = game_info[10];
        ssdb_info["class_play_count"] = class_play_count[1] and class_play_count[1] or 0;
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
        if game_info[2] then
            game_id_record = game_id_record..game_info[2]..","
        end
    end
    --如果学生没看游戏，那么就显示12个默认的游戏。
    gameArray = _Game:fill_game_student_list(student_id,rows,record_count,game_id_record,gameArray,android_ios,ssdb_db);
    --------------------------------------------------------------------------------------------------------------------------------------------------------
    local gameListJson = {};
    gameListJson.success = true;
    gameListJson.list = gameArray;
    gameListJson.app_info = app_info;
    MysqlUtil:close(mysql_db);
    ssdb_db:set_keepalive(0,v_pool_size);
    return gameListJson;
end
--[[
	局部函数：空间要求如果学生没有玩游戏，那么也要在最近玩游戏的列表中现在12个游戏。
	student_id：学生ID
	record_count：记录数
]]
function _Game:fill_game_student_list(student_id,rows,fill_record_count,game_id_record,gameArray,android_ios,ssdb_db)
    local cjson = require "cjson";
    local MysqlUtil = require "common.MysqlUtil";
    if #rows and #rows < tonumber(fill_record_count) then
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
        local sql = "";
        local query_condition = "";
        if android_ios then
            if android_ios == "1" then
                --Android平台
                query_condition = query_condition.." AND ((t1.url_android is not null And t1.url_android <> '') OR t1.url_web like '%.swf%')";
            elseif android_ios == "2" then
                --Ios平台
                query_condition = query_condition.." AND ((t1.url_ios is not null And t1.url_ios <> '')  OR t1.url_web like '%.swf%')";
            else
                --Web平台
                --query_condition = query_condition.." AND t1.url_web is not null And t1.url_web <> ''";
            end
        else
            query_condition = query_condition.." AND t1.url_web is not null And t1.url_web <> ''";
        end
        if #rows > 0 then

            sql = "SELECT t1.game_id,t2.game_type_name from t_yxx_game t1 left join t_game_type t2 on t1.type_id=t2.id  where t1.subject_id in (".. subject_ids ..")".." and t1.game_id not in (" .. string.sub(game_id_record,0,#game_id_record-1) ..") "..query_condition.." limit " .. fill_record_count - #rows.. ";";
        else
            sql = "SELECT t1.game_id,t2.game_type_name from t_yxx_game t1 left join t_game_type t2 on t1.type_id=t2.id where t1.subject_id in (".. subject_ids ..") " ..query_condition.. " limit " .. fill_record_count - #rows.. ";";
        end
        local records = MysqlUtil:query(sql);
        if not records then
            ngx.print("{\"success\":\"false\",\"info\":\"查询数据出错。\"}");
            return;
        end
        for i=1,#records do
            local game_info = ssdb_db:multi_hget("yxx_game_"..records[i]["game_id"],"game_id","game_name","subject_id","type_id","user_count","create_time","url_web","thumb_url","quality_goods","stage_id","sort_type","web_version","ios_version","android_version","url_ios","url_android");
            local class_play_count = ssdb_db:zcount("game_class_play_count"..records[i]["game_id"], 0, 100000);
            local ssdb_info = {};
            ssdb_info["game_id"] = game_info[2];
            ssdb_info["game_name"] = game_info[4];
            ssdb_info["subject_id"]= game_info[6];
            ssdb_info["type_id"]= game_info[8];
            ssdb_info["type_name"]= records[i]["game_type_name"];
            ssdb_info["user_count"] = game_info[10];
            ssdb_info["class_play_count"] = class_play_count[1] and class_play_count[1] or 0;
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
    return gameArray;
end
--[[
	局部函数：记录学生的玩游戏的结果，判断本次玩游戏是不是最好成绩，如果是那么更新数据库的game_result
	按最近玩过游戏的记录查询方式：
	table：学生玩游戏的详情
]]
function _Game:get_last_game_result(game_id,student_id)
    local dbUtil = require "yxx.tool.DbUtil";
    local ssdb_db = dbUtil:getSSDb();
    local last_game_result = ssdb_db:multi_hget("game_student_"..game_id.."_"..student_id,"last_game_result");
    ssdb_db:set_keepalive(0,v_pool_size);
    if last_game_result then
        return last_game_result[2];--表示接着上一次开始玩
    else
        return 1;--表示重第一关开始玩
    end
end
--[[
	局部函数：系统包含的所有游戏总数
]]
function _Game:game_count()
    --初始化变量
    local dbUtil = require "yxx.tool.DbUtil";
    local mysql_db = dbUtil:getMysqlDb();
    local query_sql = "SELECT count(1) As game_count from t_yxx_game";
    local rows = mysql_db:query(query_sql);
    mysql_db:set_keepalive(0,v_pool_size);
    return rows[1]["game_count"];
end
--[[
	局部函数：学生每次玩游戏都需要记录一下，为了算出游戏的参与人总数统计
]]
function _Game:set_game_play_count(game_id,student_id,class_id)
    local dbUtil = require "yxx.tool.DbUtil";
    local ssdb_db = dbUtil:getSSDb();
    local mysql_db = dbUtil:getMysqlDb();
    local game_play_count = ssdb_db:zget("game_play_count"..game_id,student_id);
    if game_play_count and game_play_count[1] and string.len(game_play_count[1])>0 then
        ssdb_db:zset("game_play_count"..game_id,student_id,tonumber(game_play_count[1])+1);
    else
        ssdb_db:zset("game_play_count"..game_id,student_id,1);
    end
    local class_play_count = ssdb_db:zget("game_class_play_count"..game_id,class_id);
    if class_play_count and class_play_count[1] and string.len(class_play_count[1])>0 then
        ssdb_db:zset("game_class_play_count"..game_id,class_id,tonumber(class_play_count[1])+1);
    else
        ssdb_db:zset("game_class_play_count"..game_id,class_id,1);
    end
    local play_count = ssdb_db:zcount("game_play_count"..game_id, 0, 100000);
    local query_sql = "update t_yxx_game set user_count="..play_count[1].." where game_id="..game_id;
    ssdb_db:multi_hset("yxx_game_"..game_id,"user_count",play_count[1]);
    mysql_db:query(query_sql);
    mysql_db:set_keepalive(0,v_pool_size);
    ssdb_db:set_keepalive(0,v_pool_size);
end
--[[
	局部函数：获得所有的游戏的参与人总数
]]
function _Game:get_game_play_count(game_id)
    local dbUtil = require "yxx.tool.DbUtil";
    local ssdb_db = dbUtil:getSSDb();
    local play_count = ssdb_db:zcount("game_play_count"..game_id, 0, 100000);
    ssdb_db:set_keepalive(0,v_pool_size);
    return play_count[1];
end
-- 返回_Game对象
return _Game;
