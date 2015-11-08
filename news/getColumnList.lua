--[[
#李政言 2015-2-9
#描述：获得栏目列表(后台)
]]
ngx.header.content_type = "text/plain;charset=utf-8"

-- 1.获取参数
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

--获得注册号
--regist_id参数
if args["regist_id"] == nil or args["regist_id"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"regist_id参数错误！\"}")
	return
end
local regist_id = args["regist_id"]

--获得当前页数
--pageNumber参数
if args["pageNumber"] == nil or args["pageNumber"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"pageNumber参数错误！\"}")
	return
end
local pageNumber = args["pageNumber"]


--获得每页显示多少个
--pageSize参数
if args["pageSize"] == nil or args["pageSize"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"pageSize参数错误！\"}")
	return
end
local pageSize = args["pageSize"]

--连接mysql数据库
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

--获得栏目列表
local sql_column_list = "select column_id,column_name,create_time from t_news_column where b_delete = 0 and regist_id ="..regist_id.." order by create_time desc";
local sql_column_count = "select count(*) as count from t_news_column where b_delete = 0 and  regist_id ="..regist_id;
local column_count = mysql_db:query(sql_column_count);

local totalRow = column_count[1]["count"];
local totalPage = math.floor((totalRow+pageSize-1)/pageSize);
local offset = pageSize*pageNumber-pageSize
local limit = pageSize
local str_maxmatches = pageNumber*pageSize
local sql_limit = " limit "..offset..","..str_maxmatches;


local results, err, errno, sqlstate = mysql_db:query(sql_column_list..sql_limit);
if not results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据出错！\"}");
    return
end

local responseObj = {};
local res_tab = {};
 responseObj.success = true;
 
 for i=1,#results do
    local tab = {};
	tab.column_name = results[i]["column_name"];
	tab.column_id =  results[i]["column_id"];
	tab.create_time =  results[i]["create_time"];
    res_tab[i]=tab
end
responseObj.list= res_tab;
responseObj.totalPage = totalPage;
responseObj.totalRow =  tonumber(totalRow);
responseObj.pageNumber =tonumber(pageNumber);
responseObj.pageSize =tonumber(pageSize);
-- 5.将table对象转换成json
local cjson = require "cjson";
cjson.encode_empty_table_as_object(false);
local responseJson = cjson.encode(responseObj);

ngx.say(responseJson);
-- 将mysql连接归还到连接池
ok, err = mysql_db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end