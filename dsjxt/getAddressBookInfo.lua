--[[
功能：根据人员ID和身份ID获取通讯录
作者：吴缤
时间：2015-08-22
]]

local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

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
cjson.encode_empty_table_as_object(false);

local host = ngx.req.get_headers()["Host"]

local result = {}

local common_tab = {}
--如果是教师就返回我的学校
if user_identity == "5" then	
	local school_res = ngx.location.capture("/dsideal_yy/person/getPersonInfo?person_id="..user_id.."&identity_id=5")	
	local school_info = cjson.decode(school_res.body).table_List
	local school_info_tab = {}
	school_info_tab["placeholderImg"] = "widget://image/person/school.png"
	school_info_tab["title"] = "我的学校"
	school_info_tab["id"] = tonumber(school_info["school_id"])
	school_info_tab["titleSize"] = 16
	school_info_tab["titleColor"] = "#000000"
	school_info_tab["t"] = 2
	table.insert(common_tab,school_info_tab)
end

--返回班级
local class_res = ngx.location.capture("/dsideal_yy/class/getClassByPersonIDIdentityID?person_id="..user_id.."&identity_id="..user_identity)
local class_info = cjson.decode(class_res.body).list
for i=1,#class_info do
	local class_info_tab = {}
	class_info_tab["placeholderImg"] = "widget://image/person/class.png"
	class_info_tab["title"] = class_info[i]["class_name"]
	class_info_tab["id"] = class_info[i]["class_id"]
	class_info_tab["titleSize"] = 16
	class_info_tab["titleColor"] = "#000000"
	class_info_tab["t"] = 3
	table.insert(common_tab,class_info_tab)	
end

--返回群聊
local group_info ={}
group_info["placeholderImg"] = "widget://image/person/group.png"
group_info["title"] = "群聊"
group_info["id"] = -1
group_info["titleSize"] = 16
group_info["titleColor"] = "#000000"
group_info["t"] = 1
table.insert(common_tab,group_info)

result["common"] = common_tab

--返回好友
local friend_res = ngx.location.capture("/dsideal_yy/friend/getFriends?person_id="..user_id.."&identity_id="..user_identity)
local friend_info = cjson.decode(friend_res.body).friends
for i=1,#friend_info do
	local person_id = friend_info[i]["fperson_id"]
	local person_name = friend_info[i]["fperson_name"]
	local identity_id = friend_info[i]["fidentity_id"]
	
	local headIcon_res = ngx.location.capture("/dsideal_yy/person/getPersonTxByYw?person_id="..person_id.."&identity_id="..identity_id.."&random_num="..math.random(1000).."&yw=ypt")
	local headIcon_info = cjson.decode(headIcon_res.body)
	local headIcon_fileid = headIcon_info["file_id"]
	local headIcon_extension = headIcon_info["extension"]	
		
	local placeholderImg = "http://"..host.."/dsideal_yy/html/"..thumb_path..string.sub(headIcon_fileid,0,2).."/"..headIcon_fileid.."."..headIcon_extension.."@50w_50h_100Q_1x."..headIcon_extension
	
	local person_info = redis_db:hmget("person_"..person_id.."_"..identity_id,"jp","login_name")
	local first = string.upper(string.sub(person_info[1],0,1))	
	
	local friend_info_tab = {}
	
	friend_info_tab["placeholderImg"] = placeholderImg
	friend_info_tab["img"] = placeholderImg
	friend_info_tab["title"] = person_name
	friend_info_tab["id"] = person_id
	friend_info_tab["titleSize"] = 16
	friend_info_tab["titleColor"] = "#000000"
	friend_info_tab["t"] = 4
	friend_info_tab["login_name"] = person_info[2]
	
	if result[first] == nil then
		result[first] = {}
	end	
	table.insert(result[first],friend_info_tab)	
end

--放回到SSDB连接池
redis_db:set_keepalive(0,v_pool_size)
ngx.print(cjson.encode(result))
