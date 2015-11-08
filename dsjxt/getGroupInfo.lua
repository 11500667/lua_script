--[[
功能：根据通讯录ID和类型获取详细信息
作者：吴缤
时间：2015-08-25
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
if args["t"] == nil or args["t"] == "" then
    ngx.print("{\"success\":false,\"info\":\"t参数不允许为空！\"}")
    return
end
local t = args["t"]

if args["id"] == nil or args["id"] == "" then
    ngx.print("{\"success\":false,\"info\":\"id参数不允许为空！\"}")
    return
end
local id = args["id"]

if args["user_id"] == nil or args["user_id"] == "" then
    ngx.print("{\"success\":false,\"info\":\"user_id参数不允许为空！\"}")
    return
end
local user_id = args["user_id"]

if args["user_identity"] == nil or args["user_identity"] == "" then
    ngx.print("{\"success\":false,\"info\":\"user_identity参数不允许为空！\"}")
    return
end
local user_identity = args["user_identity"]

if args["app_type"] == nil or args["app_type"] == "" then
    ngx.print("{\"success\":false,\"info\":\"app_type参数不允许为空！\"}")
    return
end
local app_type = args["app_type"]

--头像路径
local thumb_path = "thumb/Material/"
if app_type == "1" then
	thumb_path  = "down/Material/"
end

--连接redis服务器
local redis = require "resty.redis"
local redis_db = redis:new()
local ok,err = redis_db:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local cjson = require "cjson"

local host = ngx.req.get_headers()["Host"]

local result = {}

if t == "1" then --群聊	
	local common_tab = {}
	local group_res = ngx.location.capture("/dsideal_yy/group/queryMyGroupForApp?person_id="..user_id.."&identity_id="..user_identity.."&ip_addr="..host.."&app_type="..app_type)
	local group_info = cjson.decode(group_res.body).groups
	for i=1,#group_info do
		local head_img = group_info[i]["portraitUri"]
		local group_id = group_info[i]["groupId"]
		local group_name = group_info[i]["groupName"]
		
		local group_info_tab = {}
		group_info_tab["placeholderImg"] = head_img
		group_info_tab["img"] = head_img
		group_info_tab["title"] = group_name
		group_info_tab["id"] = tonumber(group_id)
		group_info_tab["titleSize"] = 16
		group_info_tab["titleColor"] = "#000000"		
		group_info_tab["conver_type"] = "GROUP"
		
		table.insert(common_tab,group_info_tab)
	end
	
	local class_res = ngx.location.capture("/dsideal_yy/class/getClassByPersonIDIdentityID?person_id="..user_id.."&identity_id="..user_identity)
	local class_info = cjson.decode(class_res.body).list
	for i=1,#class_info do		
		local class_info_tab = {}
		class_info_tab["placeholderImg"] = "widget://image/person/class.png"
		class_info_tab["img"] = "widget://image/person/class.png"
		class_info_tab["title"] = class_info[i]["class_name"]
		class_info_tab["id"] = "class_"..class_info[i]["class_id"]
		class_info_tab["titleSize"] = 16
		class_info_tab["titleColor"] = "#000000"		
		class_info_tab["conver_type"] = "GROUP"
		
		table.insert(common_tab,class_info_tab)
		
	end
	
	result["common"] = common_tab	
elseif t == "2" then  --我的学校
	local school_person_res = ngx.location.capture("/dsideal_yy/person/getTeachersBySchId?school_id="..id)
	local school_person_info = cjson.decode(school_person_res.body).table_List
	for i=1,#school_person_info do
		local person_id = school_person_info[i]["person_id"]
		local person_name = school_person_info[i]["person_name"]
		local identity_id = "5"
		local head_img = school_person_info[i]["file_id"].."."..school_person_info[i]["extension"]
		local placeholderImg = "http://"..host.."/dsideal_yy/html/"..thumb_path..string.sub(head_img,0,2).."/"..head_img.."@50w_50h_100Q_1x.jpg"		
		local person_info = redis_db:hmget("person_"..person_id.."_"..identity_id,"jp","login_name")
		ngx.log(ngx.ERR,"@@@@@".."person_"..person_id.."_"..identity_id.."@@@@@")
		local first = string.upper(string.sub(person_info[1],0,1))
		
		local school_person_tab = {}	
		school_person_tab["placeholderImg"] = placeholderImg
		school_person_tab["img"] = placeholderImg
		school_person_tab["title"] = person_name
		school_person_tab["id"] = person_id
		school_person_tab["titleSize"] = 16
		school_person_tab["titleColor"] = "#000000"		
		school_person_tab["login_name"] = person_info[2]
		school_person_tab["conver_type"] = "PRIVATE"
		
		if result[first] == nil then
			result[first] = {}
		end	
		table.insert(result[first],school_person_tab)			
	end	
else  --班级
	local class_res = ngx.location.capture("/dsideal_yy/base/getStudentByClassId?class_id="..id)
	local class_info = cjson.decode(class_res.body).list
	for i=1,#class_info do
		local student_id = class_info[i]["student_id"]
		local student_name = class_info[i]["student_name"]
		local identity_id = "6"
		local placeholderImg = ""
		local head_img = class_info[i]["avatar_fileid"]
		if head_img == "" then
			placeholderImg = "http://"..host.."/dsideal_yy/images/space/person.png"
		else
			placeholderImg = "http://"..host.."/dsideal_yy/html/thumb/Material/"..string.sub(head_img,0,2).."/"..head_img.."@50w_50h_100Q_1x.jpg"
		end
		
		local person_info = redis_db:hmget("person_"..student_id.."_"..identity_id,"jp","login_name")
		local first = string.upper(string.sub(person_info[1],0,1))
		
		local class_tab = {}	
		class_tab["placeholderImg"] = placeholderImg
		class_tab["img"] = placeholderImg
		class_tab["title"] = student_name
		class_tab["id"] = person_id
		class_tab["titleSize"] = 16
		class_tab["titleColor"] = "#000000"		
		class_tab["login_name"] = person_info[2]
		class_tab["conver_type"] = "PRIVATE"
		
		if result[first] == nil then
			result[first] = {}
		end	
		table.insert(result[first],class_tab)
	end
end

ngx.print(cjson.encode(result))
