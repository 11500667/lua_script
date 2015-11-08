--[[
根据当前用户ID获取用户所管理的和所属于的大学区列表[mysql版]
@Author  chenxg
@Date    2015-06-02
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"
cjson.encode_empty_table_as_object(false);
--判断request类型, 获得请求参数
local request_method = ngx.var.request_method
local args,err
if request_method == "GET" then
    args,err = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args,err = ngx.req.get_post_args() 
end
if not args then 
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
--参数 
local qyjh_id = args["qyjh_id"]
local person_id = args["person_id"]

--判断参数是否为空
if not person_id or string.len(person_id) == 0
   then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

--创建ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
-- 获取redis链接
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--连接mysql数据库
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

--获取用户管理的大学区
local dxq_sql = "select d.dxq_id,d.dxq_name as name,d.person_id,d.description,d.district_id,d.city_id,d.province_id,d.createtime,d.logo_url,d.b_use,d.b_delete,d.qyjh_id,d.is_init  from t_qyjh_dxq d where b_use=1 and qyjh_id = "..qyjh_id.." and person_id = "..person_id
local has_result, err, errno, sqlstate = db:query(dxq_sql);
if not has_result then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	return;
end
--获取用户所属于的大学区开始
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)
local schID = cache:hget("person_"..person_id.."_"..cookie_identity_id,"xiao")
local dxq_org_sql = "select d.dxq_id,d.dxq_name as name,d.person_id,d.description,d.district_id,d.city_id,d.province_id,d.createtime,d.logo_url,d.b_use,d.b_delete,d.qyjh_id ,d.is_init from t_qyjh_dxq d,t_qyjh_dxq_org o where d.dxq_id = o.dxq_id and d.b_use=1 and o.b_use=1 and d.qyjh_id = "..qyjh_id.." and o.org_id = "..schID
local has_result2, err, errno, sqlstate = db:query(dxq_org_sql);
if not has_result2 then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	return;
end
local list1 = {}
for i=1,#has_result,1 do
	local temp = {}
	temp.dxq_id = has_result[1]["dxq_id"]
	temp.name = has_result[1]["name"]
	temp.person_id = has_result[1]["person_id"]
	temp.description = has_result[1]["description"]
	temp.district_id = has_result[1]["district_id"]
	temp.city_id = has_result[1]["city_id"]
	temp.province_id = has_result[1]["province_id"]
	temp.createtime = has_result[1]["createtime"]
	temp.logo_url = has_result[1]["logo_url"]
	temp.b_use = has_result[1]["b_use"]
	temp.b_delete = has_result[1]["b_delete"]
	temp.qyjh_id = has_result[1]["qyjh_id"]
	temp.is_init = has_result[1]["is_init"]
	list1[#list1+1] = temp
end
for i=1,#has_result2,1 do
	local temp = {}
	temp.dxq_id = has_result2[1]["dxq_id"]
	temp.name = has_result2[1]["name"]
	temp.person_id = has_result2[1]["person_id"]
	temp.description = has_result2[1]["description"]
	temp.district_id = has_result2[1]["district_id"]
	temp.city_id = has_result2[1]["city_id"]
	temp.province_id = has_result2[1]["province_id"]
	temp.createtime = has_result2[1]["createtime"]
	temp.logo_url = has_result2[1]["logo_url"]
	temp.b_use = has_result2[1]["b_use"]
	temp.b_delete = has_result2[1]["b_delete"]
	temp.qyjh_id = has_result2[1]["qyjh_id"]
	temp.is_init = has_result2[1]["is_init"]
	list1[#list1+1] = temp
end
local returnjson = {}
returnjson.list = list1
returnjson.success = "true"
say(cjson.encode(returnjson))

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0,v_pool_size)