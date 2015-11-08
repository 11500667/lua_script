local cjson = require "cjson"
cjson.encode_empty_table_as_object(false);
local request_method = ngx.var.request_method
local quote = ngx.quote_sql_str
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

if tostring(args["apk_name"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"apk_name参数错误\"}")    
    return
end

if tostring(args["file_id"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"file_id参数错误\"}")    
    return
end
if tostring(args["file_type"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"file_type参数错误\"}")    
    return
end
if tostring(args["version_code"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"version_code参数错误\"}")    
    return
end
if tostring(args["file_name"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"file_name参数错误\"}")    
    return
end
if tostring(args["extension"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"extension参数错误\"}")    
    return
end
if tostring(args["upload_path"])=="nil" then
    ngx.say("{\"success\":false,\"info\":\"upload_path参数错误\"}")    
    return
end
--参数
local apk_name = tostring(args["apk_name"])
local file_id = tostring(args["file_id"])
local file_type = tostring(args["file_type"])
local version_code = tostring(args["version_code"])
local file_name = tostring(args["file_name"])
local extension = tostring(args["extension"])
local upload_path = tostring(args["upload_path"])
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
if file_type ~= "5" then
	local del_sql = "DELETE FROM T_BAG_UPDATEAPK WHERE FILE_TYPE = "..file_type
	db:query(del_sql);
end
local is_insert = true
if file_type == "5" then
	-- 判断是否有高版本的apk存在
	--[[local sel_sql = "select apk_id FROM T_BAG_UPDATEAPK WHERE statu=1 and APK_NAME = "..quote(file_name).." and VERSION_CODE >="..quote(version_code)
	local res = db:query(sel_sql);
	if #res > 0 then
		is_insert = false
	else
		local update_sql = "update T_BAG_UPDATEAPK set statu=2 WHERE APK_NAME = "..quote(file_name).." and statu = 1"
		db:query(update_sql);
	end
	--将以前卸载的apk置为被替换状态，保留最后的操作记录
	local update_sql2 = "update T_BAG_UPDATEAPK set statu=2 WHERE APK_NAME = "..quote(file_name).." and statu = 0"
	db:query(update_sql2);]]

end

local upload_time = os.date("%Y-%m-%d %H:%M:%S");
if is_insert then
	local add_sql = "INSERT INTO T_BAG_UPDATEAPK(APK_NAME,FILE_ID,UPLOAD_TIME,FILE_TYPE,VERSION_CODE,FILE_TYPE_NAME,EXTENSION,FILE_PATH) VALUES ("..quote(file_name)..",'"..file_id.."','"..upload_time.."',"..file_type..",'"..version_code.."','"..ngx.decode_base64(apk_name).."','"..extension.."','"..upload_path.."')"
	db:query(add_sql);
end
--
ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end
local returnjson = {}
if is_insert then
	--ngx.say("{\"success\":true,\"info\":\"上传成功！\"}")
	returnjson.success = true
	returnjson.info = "上传成功"
	ngx.say(cjson.encode(returnjson))

else
	--ngx.print("<script type='text/javascript'>self.parent.reloadError()</script>")
	--ngx.say("{\"success\":false,\"info\":\"有高版本的APK存在！\"}")
	returnjson.success = false
	returnjson.info = "有高版本的APK存在！"
	ngx.say(cjson.encode(returnjson))
end
	ngx.print("<script>self.parent.a_callback()</script>")