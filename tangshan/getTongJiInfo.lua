local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--地区
if args["area_id"] == nil or args["area_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"area_id参数错误！\"}")
    return
end
local area_id = args["area_id"]

local cjson = require "cjson"

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
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

local zy = {}
local zy_tj_info = ssdb_db:multi_hget("tj_zy_all","total_count","total_size","view_count","down_count")
local zy_tj_info_tab = {total_count="0",total_size="0",view_count="0",down_count="0"}
for i=1,#zy_tj_info,2 do
    zy_tj_info_tab[zy_tj_info[i]]=zy_tj_info[i+1]
end

local total_size= db:query("SELECT SUM(RESOURCE_SIZE_INT) as total_size FROM t_resource_info WHERE res_type=1 AND release_status IN (1,3) AND GROUP_ID IN (1,"..area_id..")")
zy_tj_info_tab["total_size"] = total_size[1]["total_size"]

local down_count= db:query("SELECT SUM(down_count) as down_count FROM t_resource_info WHERE res_type=1 AND release_status IN (1,3) AND GROUP_ID IN (1,"..area_id..")")
zy_tj_info_tab["down_count"] = down_count[1]["down_count"]

local resource_count = db:query("SELECT SQL_NO_CACHE id FROM t_resource_info_sphinxse  WHERE query='filter=res_type=1;filter=release_status,1,3;filter=group_id,1,"..area_id.."';SHOW ENGINE SPHINX  STATUS;")
local res1 = db:read_result()
local _,s_str = string.find(res1[1]["Status"],"found: ")
local e_str = string.find(res1[1]["Status"],", time:")
local totalRow = string.sub(res1[1]["Status"],s_str+1,e_str-1)
zy_tj_info_tab["total_count"] = totalRow


local person_count= db:query("SELECT COUNT(1) as pcount FROM t_base_person where IDENTITY_ID=5 AND CITY_ID="..area_id)
zy_tj_info_tab["teacher_count"] = person_count[1]["pcount"]

zy_tj_info_tab["success"] = true

ngx.print(cjson.encode(zy_tj_info_tab))
