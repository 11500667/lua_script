--[[
#梁雪峰 2014-12-22
#描述：获取新闻列表(前台)
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

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

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
--得到新闻参数和mysql新闻列表
local cjson = require "cjson"
local item_id = args["item_id"]
local menu_id = args["menu_id"]
local pageNumber = args["pageNumber"]
local pageSize = args["pageSize"]
local news_area_id = ["news_area_id"]
local pid = args["pid"]
local offset = (pageNumber - 1) * pageSize

--数据库分页操作
local res1 = mysql_db:read_result()
local _,s_str = string.find(res1[1]["Status"],"found: ")
local e_str = string.find(res1[1]["Status"],", time:")
local totalRow = string.sub(res1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)
--如果列表为空，则返回相关参数以及一个空的list。


local res = mysql_db:query("select SQL_NO_CACHE id from t_news_info_sphinxse where query='filter=menu_id,"..menu_id..";filter=news_column_id,"..item_id..";filter=news_area_id,"..news_area_id..";filter=pid,"..pid..";filter=b_delete,0;maxmatches=50000;offset="..offset..";limit="..pageSize..";sort=attr_desc:news_create_time';SHOW ENGINE SPHINX  STATUS;")

local news_info = {}



if pageNumber > totalPage then
	pageNumber = totalPage
	offset = (pageNumber - 1) * pageSize
	res = mysql_db:query("select SQL_NO_CACHE id from t_news_info_sphinxse where query='filter=menu_id,"..menu_id..";filter=news_column_id,"..item_id..";filter=news_area_id,"..news_area_id..";filter=pid,"..pid..";filter=b_delete,0;maxmatches=50000;offset="..offset..";limit="..pageSize..";sort=attr_desc:news_create_time';SHOW ENGINE SPHINX  STATUS;")
elseif totalPage == 0 then 
	news_info.success = true
	news_info.totalRow = totalRow
	news_info.totalPage = totalPage + 1
	news_info.pageNumber = pageNumber
	news_info.pageSize = pageSize
	news_info.list = ""
	local jsonStr = cjson.encode(news_info);
	ngx.say(jsonStr)
	return 
end

news_info.success = true
news_info.totalRow = totalRow
news_info.totalPage = totalPage
news_info.pageNumber = pageNumber
news_info.pageSize = pageSize

local rlist = {}
for i=1,#res do
	local list = {}
	local str_id = res[i]["id"]
	local sdb = ssdb_db:multi_hget("news_"..str_id, "title","create_time","image")

	list.news_id = str_id
	list.title = sdb[2]
	list.create_time = sdb[4]
	list.create_time = os.date("%Y-%m-%d %H:%M:%S")
	list.image = sdb[6]
	
	table.insert(rlist,list)
end
news_info.list = rlist

local jsonStr = cjson.encode(news_info);
ngx.say(jsonStr)
-- 将mysql连接归还到连接池
ok, err = mysql_db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end
--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)

