local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end
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

local query_sql = "SELECT APK_NAME,VERSION_CODE,FILE_PATH FROM T_BAG_UPDATEAPK where FILE_TYPE!=5"
local apk_list = db:query(query_sql);
local apk_list2 = apk_list
local render_json = {}
local num = 0;
for i=1,#apk_list2 do
	-- local file_type = apk_list2[i]["FILE_TYPE"]
	-- if file_type == 3 then
		-- local temp_json = {}
		-- local version_str = apk_list2[i]["VERSION_CODE"]
		-- local version_info = Split(version_str,",");
		-- --饰品库
		-- num = num + 1
		-- local shipin_version = version_info[1]
		-- --temp_json["file_type"] = file_type
		-- --temp_json["file_type_name"] = "饰品库"
		-- temp_json["apk_name"] = apk_list2[i]["APK_NAME"]
		-- temp_json["version"] = shipin_version
		-- temp_json["file_path"] = ngx.encode_base64(apk_list2[i]["FILE_PATH"])
		-- render_json[num] = temp_json
		-- --字体库
		-- num = num + 1
		-- local ziti_version = version_info[2]
		-- local temp_json2 = {}
		-- --temp_json2["file_type"] = file_type
		-- --temp_json2["file_type_name"] = "字体库"
		-- temp_json2["apk_name"] = apk_list2[i]["APK_NAME"]
		-- temp_json2["version"] = ziti_version
		-- temp_json2["file_path"] = ngx.encode_base64(apk_list2[i]["FILE_PATH"])
		-- render_json[num] = temp_json2
	-- else
		num = num + 1
		local temp_json3 = {}
		--temp_json3["file_type"] = file_type
		--temp_json3["file_type_name"] = apk_list2[i]["FILE_TYPE_NAME"]
		temp_json3["apk_name"] = apk_list2[i]["APK_NAME"]
		temp_json3["version"] = apk_list2[i]["VERSION_CODE"]
		temp_json3["file_path"] = ngx.encode_base64(apk_list2[i]["FILE_PATH"])
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

