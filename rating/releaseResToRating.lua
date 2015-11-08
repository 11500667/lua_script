local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

local myTs = require "resty.TS"
local cjson = require "cjson"

--评比ID
if args["rating_id"] == nil or args["rating_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"rating_id参数错误！\"}")
    return
end
local rating_id = args["rating_id"]

--资源resource_id_int
if args["resource_id_int"] == nil or args["resource_id_int"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"resource_id_int参数错误！\"}")
    return
end
local resource_id_int = args["resource_id_int"]

--资源说明
local resource_memo = ""
if args["resource_memo"] ~= nil and args["resource_memo"] ~= "" then
    resource_memo = args["resource_memo"]
end

local w_type
if args["w_type"] == nil or args["w_type"] == "" then
  w_type = 0
else
  w_type = args["w_type"]
end



--人员ID
local person_id = tostring(ngx.var.cookie_person_id)

--人员姓名
local person_name = tostring(ngx.var.cookie_person_name)

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

--连接redis服务器
local redis = require "resty.redis"
local redis_db = redis:new()
local ok,err = redis_db:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--url加码
function decodeURI(s)
    s = string.gsub(s, '%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
    return s
end

local result = {} 

local rating_info = mysql_db:query("SELECT rating_title,rating_sub_title,rating_type FROM t_rating_info WHERE id="..rating_id)

local rating_title = rating_info[1]["rating_title"]
local rating_sub_title = rating_info[1]["rating_sub_title"]
local rating_type = rating_info[1]["rating_type"]
local resource_info=""
local exist_res =""
local resource_info_id=""

if(rating_type==1) then

	resource_info = mysql_db:query("SELECT id,person_id,stage_id,subject_id,scheme_id_int as scheme_id,structure_id FROM t_resource_info WHERE RESOURCE_ID_INT = "..resource_id_int.." AND GROUP_ID = 2 ORDER BY TS DESC LIMIT 1")
	resource_info_id = resource_info[1]["id"]
	exist_res = mysql_db:query("SELECT count(1) as count FROM t_rating_resource WHERE resource_info_id = "..resource_info_id.." AND rating_id="..rating_id)

else
	resource_info = mysql_db:query("SELECT id,person_id,stage_id,subject_id,scheme_id,structure_id FROM t_wkds_info WHERE id = "..resource_id_int.."  ORDER BY TS DESC LIMIT 1")
	ngx.log(ngx.ERR,"SELECT id,person_id,stage_id,subject_id,scheme_id,structure_id FROM t_wkds_info WHERE id = "..resource_id_int.."  ORDER BY TS DESC LIMIT 1")
	if resource_info ~= nil then
	resource_info_id = resource_info[1]["id"]
	exist_res = mysql_db:query("SELECT count(1) as count FROM t_rating_resource WHERE resource_info_id = "..resource_info_id.." AND rating_id="..rating_id)
	else
	ngx.say("{\"success\":\"false\",\"info\":\"处理程序上传微课失败！\"}")
	return
	end
end

local resource_info_id = resource_info[1]["id"]
local person_id = resource_info[1]["person_id"]
local stage_id = resource_info[1]["stage_id"]
local subject_id = resource_info[1]["subject_id"]

local scheme_id = resource_info[1]["scheme_id"]
local structure_id = resource_info[1]["structure_id"]

if tostring(exist_res[1]["count"]) == "0" then

	local bureau_id = redis_db:hget("person_"..person_id.."_5","xiao")

	local bureau_name = redis_db:hget("t_base_organization_"..bureau_id,"org_name")

	local ts = myTs.getTs()
	local view_count = "0"
	local vote_count = "0"
	local scorce = "0"
	local expert_rec = "0"
	local award_id = "0"
	local resource_status = "1"

	
	mysql_db:query("INSERT INTO t_rating_resource (w_type,israting,scheme_id,structure_id,rating_id,rating_title,rating_sub_title,resource_info_id,resource_memo,person_id,person_name,bureau_id,bureau_name,stage_id,subject_id,ts,view_count,vote_count,scorce,expert_rec,award_id,resource_status) VALUES ("..w_type..",1,'"..scheme_id.."','"..structure_id.."','"..rating_id.."','"..rating_title.."','"..rating_sub_title.."','"..resource_info_id.."','"..resource_memo.."','"..person_id.."','"..decodeURI(person_name).."','"..bureau_id.."','"..bureau_name.."','"..stage_id.."','"..subject_id.."','"..ts.."','"..view_count.."','"..vote_count.."','"..scorce.."','"..expert_rec.."','"..award_id.."','"..resource_status.."')")

	
	
	mysql_db:set_keepalive(0,v_pool_size)
	redis_db:set_keepalive(0,v_pool_size)

	result["success"] = true
else
	result["success"] = false
	result["info"] = "该资源已经参与了本次评比活动！"
end

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))

