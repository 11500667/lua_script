--[[
功能：根据ID获取群组信息
作者：吴缤
时间：2015-08-28
]]

local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--1：群聊  2:我的学校  3：班级
if args["id"] == nil or args["id"] == "" then
    ngx.print("{\"success\":false,\"info\":\"id参数不允许为空！\"}")
    return
end
local id = args["id"]

if args["app_type"] == nil or args["app_type"] == "" then
    ngx.print("{\"success\":false,\"info\":\"app_type参数不允许为空！\"}")
    return
end
local app_type = args["app_type"]

local host = ngx.req.get_headers()["Host"]

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

local cjson = require "cjson"
cjson.encode_empty_table_as_object(false);
local result = {}

if string.sub(id,0,1) == "c" then
	local class_id = string.sub(id,7,#id)
	
	local class_res = ngx.location.capture("/dsideal_yy/class/getClassInfoById?class_id="..class_id)
	local class_info = cjson.decode(class_res.body).list
	
	result["id"] = id
	result["name"] = class_info[1]["class_name"]
	result["img"] = "../../image/person/class.png"
	
else
	local group_res = ngx.location.capture("/dsideal_yy/group/queryGroupById?groupId="..id.."&app_type="..app_type)
	local group_info = cjson.decode(group_res.body)	
	local head_img = group_info["APP_AVATER_URL"]	
	
	result["id"] = id
	result["name"] = group_info["GROUP_NAME"]	
	result["img"] = "http://"..host..head_img

end

result["success"] = true
ngx.print(cjson.encode(result))
