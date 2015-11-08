local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

--local regist_person = tostring(ngx.var.cookie_background_person_id)

--regist_id参数
if args["regist_id"] == nil or args["regist_id"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"regist_id参数错误！\"}")
	return
end
local regist_id = args["regist_id"]

--column_id参数
if args["column_id"] == nil or args["column_id"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"column_id参数错误！\"}")
	return
end
local column_id = args["column_id"]

--pageSize参数
if args["pageSize"] == nil or args["pageSize"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"pageSize参数错误！\"}")
	return
end
local pageSize = args["pageSize"]

--pageNumber参数
if args["pageNumber"] == nil or args["pageNumber"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"pageNumber参数错误！\"}")
	return
end
local pageNumber = args["pageNumber"]

local cjson = require "cjson"

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

local offset = pageSize*pageNumber-pageSize
local limit = pageSize
local str_maxmatches = "10000"

--拼栏目条件
local str_columnid = ""
if column_id ~= "-1" then
	str_columnid = "filter=column_id,"..column_id..";"
end

--拼注册号条件
local str_registid = ""
str_registid = "filter=regist_id,"..regist_id..";"

--拼创建人条件
--local str_createperson = ""
--str_createperson = "filter=create_person,"..regist_person..";"

local res = mysql_db:query("SELECT SQL_NO_CACHE id FROM t_news_info_sphinxse WHERE query='filter=b_delete,0;"..str_columnid..str_registid.."sort=attr_desc:ts;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."';SHOW ENGINE SPHINX  STATUS;")
ngx.log(ngx.ERR,"SELECT SQL_NO_CACHE id FROM t_news_info_sphinxse WHERE query='filter=b_delete,0;"..str_columnid..str_registid.."sort=attr_desc:ts;maxmatches="..str_maxmatches..";offset="..offset..";limit="..limit.."';SHOW ENGINE SPHINX  STATUS;")
--去第二个结果集中的Status中截取总个数
local res1 = mysql_db:read_result()
local _,s_str = string.find(res1[1]["Status"],"found: ")
local e_str = string.find(res1[1]["Status"],", time:")
local totalRow = string.sub(res1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

local news_tab = {}
for i=1,#res do
	local _news = {}
	local id = res[i]["id"]
	local news_info = ssdb_db:multi_hget("news_info_"..id, "title","content","create_time","create_person","create_person_name","column_id","column_name","regist_id","ts","image")	
	_news["id"] = id
	_news["title"] = news_info[2]
	--_news["content"] = news_info[4]
	_news["create_time"] = news_info[6]
	_news["create_person"] = news_info[8]
	_news["create_person_name"] = news_info[10]
	_news["column_id"] = news_info[12]
	_news["column_name"] = news_info[14]
	_news["regist_id"] = news_info[16]
	_news["ts"] = news_info[18]
	_news["image"] = news_info[20]
	
	news_tab[i] = _news	
end

local result = {}
result["success"] = true
result["totalRow"] = totalRow
result["totalPage"] = totalPage
result["pageSize"] = pageSize
result["pageNumber"] = pageNumber
result["list"] = news_tab

-- 将mysql连接归还到连接池
mysql_db: set_keepalive(0, v_pool_size);
--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false)
ngx.print(cjson.encode(result))


