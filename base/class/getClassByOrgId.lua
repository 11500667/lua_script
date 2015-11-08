--[[
@Author cuijinlong
@date 2015-4-24
--]]
local say = ngx.say
local cjson = require "cjson"
--  获取request的参数
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then 
	args = ngx.req.get_uri_args(); 
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end
if args["school_id"] == nil or args["school_id"]=="" then
	ngx.print("{\"success\":false,\"info\":\"必要的参数subject_id，class_id不能为空！\"}");
	return;
end
local mysql = require "resty.mysql"
local mysql_db = mysql:new()
mysql_db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024*1024
}
local school_id = tostring(args["school_id"]);
local page_size = tonumber(args["page_size"]);
local page_number = tonumber(args["page_number"]);
local total_row	= 0;
local total_page = 0;
--------------------------------------------------------------------------------------------------------------------------------------------------------
--获得我的错题总数SELECT CLASS_ID,CLASS_NAME,STAGE_ID FROM T_BASE_CLASS WHERE BUREAU_ID = 2000976 ORDER BY STAGE_ID
local total_rows_sql = "SELECT COUNT(1) as TOTAL_ROW FROM T_BASE_CLASS WHERE BUREAU_ID="..school_id..";";
--ngx.log(ngx.ERR, "#################!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"..total_rows_sql.."#################!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
local total_query, err, errno, sqlstate = mysql_db:query(total_rows_sql);
if not total_query then
	return {success=false, info="查询数据出错。"};
end

total_row = total_query[1]["TOTAL_ROW"];
total_page = math.floor((total_row+page_size-1)/page_size);
local offset = page_size*page_number-page_size;
local limit  = page_size;   
local query_sql = "SELECT t1.CLASS_ID,t1.CLASS_NAME,t2.STAGE_ID,t2.STAGE_NAME FROM T_BASE_CLASS t1 INNER JOIN  T_DM_STAGE t2 on t1.STAGE_ID=t2.STAGE_ID WHERE t1.BUREAU_ID ="..school_id.." ORDER BY t1.STAGE_ID limit " .. offset .. "," .. limit .. ";";
--ngx.log(ngx.ERR, "@@@@@@@@@@@@@@"..query_sql.."@@@@@@@@@");
local rows, err, errno, sqlstate = mysql_db:query(query_sql);
if not rows then
	ngx.print("{\"success\":\"false\",\"info\":\"查询数据出错。\"}");
	return;
end
--------------------------------------------------------------------------------------------------------------------------------------------------------
local classArray = {}
for i=1,#rows do
	local ssdb_info = {};
	ssdb_info["class_id"] = rows[i]["CLASS_ID"];									--班级ID
	ssdb_info["class_name"] = rows[i]["CLASS_NAME"];								--班级name
	ssdb_info["stage_id"] = rows[i]["STAGE_ID"];									--学段id
	ssdb_info["stage_name"] = rows[i]["STAGE_NAME"];								--学段name
	table.insert(classArray, ssdb_info);
end
--------------------------------------------------------------------------------------------------------------------------------------------------------
local classListJson = {};
classListJson.success    = true;
classListJson.total_row   = total_row;
classListJson.total_page  = total_page;
classListJson.page_number = page_number;
classListJson.page_size   = page_size;
classListJson.list = classArray;
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(classListJson);
say(responseJson);
mysql_db:set_keepalive(0,v_pool_size);
