local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

local ptype = args["ptype"]
--连接数据库
local mysql = require "resty.mysql"
local db = mysql:new()
db:connect{
	host = v_mysql_ip,
	port = v_mysql_port,
	database = v_mysql_database,
	user = v_mysql_user,
	password = v_mysql_password,
	max_packet_size = 1024*1024
}
local filter = ""
if ptype and tostring(ptype) == "1" then--pc端教师获取应用类别
	filter = " and STATU=1 "
end
local query_sql = "SELECT APK_ID,APK_NAME,VERSION_CODE,FILE_PATH,STATU,apk_realversion,apk_realname,apk_pagename FROM T_BAG_UPDATEAPK where FILE_TYPE=5 and STATU !=2"..filter.." order by upload_time asc"
local apk_list = db:query(query_sql);
local apk_list2 = apk_list
local render_json = {}
local num = 0;
for i=1,#apk_list2 do
	num = num + 1
	local temp_json3 = {}
	temp_json3["id"] = apk_list2[i]["APK_ID"]
	temp_json3["name"] = apk_list2[i]["APK_NAME"]
	temp_json3["version"] = apk_list2[i]["VERSION_CODE"]
	temp_json3["downUrl"] = ngx.encode_base64(apk_list2[i]["FILE_PATH"])
	temp_json3["downUrl2"] = apk_list2[i]["FILE_PATH"]
	temp_json3["statu"] = apk_list2[i]["STATU"]
	temp_json3["apk_realversion"] = apk_list2[i]["apk_realversion"]
	temp_json3["apk_realname"] = apk_list2[i]["apk_realname"]
	temp_json3["apk_pagename"] = apk_list2[i]["apk_pagename"]
	temp_json3["apk_icon"] = apk_list2[i]["FILE_PATH"]..".png"
	render_json[num] = temp_json3
	-- end	
end

local result = {}
result["success"] = true
result["list"] = render_json

-- 将mysql连接归还到连接池
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

local cjson = require "cjson"
cjson.encode_empty_table_as_object(false)
ngx.say(tostring(cjson.encode(result)))

