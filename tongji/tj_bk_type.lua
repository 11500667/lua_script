local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

local cjson = require "cjson"

if args["stage_name"] == nil or args["stage_name"] == "" then
    ngx.say("{\"success\":false,\"info\":\"stage_name参数错误！\"}")
    return
end
local stage_name = args["stage_name"]

if args["subject_name"] == nil or args["subject_name"] == "" then
    ngx.say("{\"success\":false,\"info\":\"subject_name参数错误！\"}")
    return
end
local subject_name = args["subject_name"]

if args["school_id"] == nil or args["school_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"school_id参数错误！\"}")
    return
end
local school_id = args["school_id"]

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

local subject_id_res = mysql_db:query("select t1.subject_id from t_dm_subject t1 INNER JOIN t_dm_stage t2 on t1.stage_id = t2.stage_id where t2.stage_name='"..stage_name.."' and t1.SUBJECT_NAME='"..subject_name.."'")

local subject_id = subject_id_res[1]["subject_id"]


local res_1 = mysql_db:query("SELECT t1.id,t1.type_name,COUNT(1) as count,SUM(resource_size_int) as size FROM t_base_type t1  inner JOIN t_resource_info t2 on t1.id=t2.bk_type where SYSTEM_ID = 4 and b_use = 1 and RES_TYPE =2 AND GROUP_ID =2 AND RELEASE_STATUS IN (1,3) AND SUBJECT_ID="..subject_id.." AND PERSON_ID IN (SELECT PERSON_ID FROM t_base_person WHERE BUREAU_ID = "..school_id..") GROUP BY t2.bk_type UNION select 1 as id,'资源包',COUNT(1),ifnull(SUM(resource_size_int),0) from t_resource_info where RES_TYPE =2 AND GROUP_ID =2 AND RELEASE_STATUS IN (1,3) AND SUBJECT_ID="..subject_id.." AND PERSON_ID IN (SELECT PERSON_ID FROM t_base_person WHERE BUREAU_ID = "..school_id..")  and bk_type =1")

local ids = "0"
local bk_tab = {}
for i=1,#res_1 do
	local bk_info = {} 
	bk_info["bk_type"] = res_1[i]["type_name"]
	bk_info["count"] = res_1[i]["count"]
	bk_info["size"] = "100"
	if tostring(res_1[i]["size"]) ~= "-1"  then
		bk_info["size"] = res_1[i]["size"]
	end
	ids = ids..","..res_1[i]["id"]
	table.insert(bk_tab, bk_info)
end

local res_2 = mysql_db:query("SELECT id,type_name,0 as count,0 as size FROM t_base_type where SYSTEM_ID = 4 and b_use = 1 and id not in ("..ids..")")
for i=1,#res_2 do
	local bk_info = {} 
	bk_info["bk_type"] = res_2[i]["type_name"]
	bk_info["count"] = res_2[i]["count"]
	bk_info["size"] = res_2[i]["size"]	
	table.insert(bk_tab, bk_info)
end

local result = {}
result["bk_list"] = bk_tab
result["success"] = true

cjson.encode_empty_table_as_object(false)
ngx.print(tostring(cjson.encode(result)))

