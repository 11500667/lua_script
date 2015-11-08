#ngx.header.content_type = "text/plain;charset=utf-8"

--[[
#caohn 2015-09-06
#描述：上传课件信息到teach_info表中 更新时也调用此接口所以在插入之前要先查询 如果存在就更新 不存在就插入
#参数 资源id：resource_id 更新标识 update_logo 备课类型 bk_type 简介 is_summary
]]

--1.获得参数方法
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

--2.获取参数
--获得资源id
if args["resource_id"] == nil or args["resource_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"resource_id参数错误！\"}")
    return
end

local resource_id = tostring(args["resource_id"]);

--获得更新标识 
if args["update_logo"] == nil or args["update_logo"] == "" then
    ngx.say("{\"success\":false,\"info\":\"update_logo参数错误！\"}")
    return
end

local update_logo = args["update_logo"]

--获取备课类型
if args["bk_type"] == nil or args["bk_type"] == "" then
    ngx.say("{\"success\":false,\"info\":\"bk_type参数错误！\"}")
    return
end

local bk_type = args["bk_type"]

--获得TS
local TS = require "resty.TS";
local ts = TS.getTs();

--如果是电子书类型  获取简介 不是电子书类型的话 简介为-1
if (bk_type == "104") then

	if args["is_summary"] == nil or args["is_summary"] == "" then
		ngx.say("{\"success\":false,\"info\":\"is_summary参数错误！\"}")
		return
	end

	local is_summary = ngx.quote_sql_str(tostring(args["is_summary"]));
else
	is_summary = "-1";
end

--3.连接数据库
local mysql = require "resty.mysql";
local db, err = mysql : new();
	if not db then 
		ngx.log(ngx.ERR, err);
		return;
	end

db:set_timeout(1000) -- 1 sec

local ok, err, errno, sqlstate = db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024 * 1024 }

if not ok then
		ngx.print("{\"success\":false,\"info\":\"连接数据库失败！\"}")
		ngx.log(ngx.ERR, "[sj_log]->[DBUtil]-> 连接数据库失败!");
		return false;
	end
	
--4.连接SSDB 
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end	
	
--5.查询数据  把t_resource_id_char从t_resource_base里获取回来
local sql = "SELECT resource_id_char FROM t_resource_base WHERE RESOURCE_ID_INT ="..resource_id

local list, err, errno, sqlstate = db:query(sql);
if not list
then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"查询resource_id_char数据出错！\"}");
    return;
end

local resource_id_char = list[1]["resource_id_char"];

--6.把数据插入t_resource_teach_info表中
-- 先查询 如果有数据就更新 没数据就插入
local sql2 = "SELECT resource_id_int FROM t_resource_teach_info WHERE resource_id_int = "..resource_id

local list2, err, errno, sqlstate = db:query(sql2);
if not list2
then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"查询resource_id_int数据出错！\"}");
    return;
end

-- 返回显示信息
local responseObj = {};

if (#list2 == 0) then

-- 表示没有数据 插入操作
local sql1 = "INSERT INTO t_resource_teach_info (resource_id_int,resource_id_char,updatelogo,is_summary) VALUES ("..resource_id..",'"..resource_id_char.."','"..update_logo.."','"..is_summary.."')";

ngx.log(ngx.ERR,"#################",sql1);
local list1, err, errno, sqlstate = db:query(sql1);
if not list1
then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"插入teach_info数据出错！\"}");
    return;
end

--插入SSDB
local resource_tab = {};
resource_tab.resource_id_char = resource_id_char;
resource_tab.update_logo = update_logo;
resource_tab.is_summary = is_summary;

local value = ssdb_db:multi_hset("teach_resource_"..resource_id,resource_tab)

-- ngx.say("ssdb数据：主键：".."teach_resource_"..resource_id);

responseObj.success = true;
responseObj.info = "上传课件成功";

else
-- 表示有数据 更新操作

--改base表必须改info表，myinfo表也得改
--更改base表 的ts
local sql3 = "UPDATE t_resource_base SET ts = '"..ts.."' where RESOURCE_ID_INT = '"..resource_id.."'";
ngx.log(ngx.ERR,"##################"..sql3)
local list3, err, errno, sqlstate = db:query(sql3);
if not list3
then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"更新t_resource_base数据出错！\"}");
    return;
end

--改info和myinfo的update_ts
--修改info表的数据
local sel_info = "SELECT SQL_NO_CACHE id FROM t_resource_info_sphinxse WHERE query = 'filter=resource_id_int,"..resource_id..",filter=release_STATUS,1,3'";

local result_info, err, errno, sqlstate = db:query(sel_info);
if not result_info
then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"查询info表出错！\"}");
    return;
end

	for i=1,#result_info do
		local up_info = "update t_resource_info set update_ts = "..ts.." where id = ";
		up_info = up_info..result_info[i]["id"];
		local result_upinfo, err, errno, sqlstate = db:query(up_info)
		if not result_upinfo then
			ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
			ngx.say("{\"success\":false,\"info\":\"修改资源的info表失败！\"}")
			return
			end
	end
	
--修改myinfo表的数据
local sel_my_info = "SELECT SQL_NO_CACHE id FROM t_resource_my_info_sphinxse WHERE query='filter=resource_id_int,"..resource_id..",filter=release_STATUS,1,3'";

local result_my_info, err, errno, sqlstate = db:query(sel_my_info);
if not result_my_info
then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"查询myinfo表出错！\"}");
    return;
end
		
	for i=1,#result_my_info do
	local up_myinfo = "update t_resource_my_info set update_ts = "..ts.." where id = ";
    up_myinfo = up_myinfo..result_my_info[i]["id"];
	local result_upmyinfo, err, errno, sqlstate = db:query(up_myinfo)
			
	if not result_upmyinfo then
		 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
		 ngx.say("{\"success\":false,\"info\":\"修改资源的myinfo表失败！\"}")
		return
		end
	end
	
-- 修改teach_info表的数据
local sel_teach_info = "SELECT resource_id_int FROM t_resource_teach_info WHERE resource_id_int = '"..resource_id.."'";

local result_teach_info, err, errno, sqlstate = db:query(sel_teach_info);
if not result_teach_info
then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    ngx.say("{\"success\":\"false\",\"info\":\"查询teach_info表出错！\"}");
    return;
end

	for i=1,#result_teach_info do
	local up_teachinfo = "update t_resource_teach_info set updatelogo = '"..update_logo.."' where resource_id_int = ";
    up_teachinfo = up_teachinfo..result_teach_info[i]["resource_id_int"];
	ngx.log(ngx.ERR,"#######################",up_teachinfo);
	local result_upteachinfo, err, errno, sqlstate = db:query(up_teachinfo)
			
	if not result_upteachinfo then
		 ngx.log(ngx.ERR,"bad result: ", err, ": ", errno, ": ", sqlstate, ".")
		 ngx.say("{\"success\":false,\"info\":\"修改资源的teach_info表失败！\"}")
		return
		end
	end
	
-- 更改SSDB
local resource_tab = {};
resource_tab.update_logo = update_logo;
ssdb_db:multi_hset("teach_resource_"..resource_id,resource_tab)

responseObj.success = true;
responseObj.info = "更新成功";

end

-- 7.将table对象转换成json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(responseObj);

-- 8.输出json串到页面
ngx.say(responseJson);

-- 9.将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

--10.放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size);