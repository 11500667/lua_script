--[[
根据大学区ID、县区ID获取学校列表[mysql版]
@Author  chenxg
@Date    2015-06-02
--]]
local say = ngx.say

--引用模块
local cjson = require "cjson"
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
local dxq_id = args["dxq_id"]
local region_id = args["region_id"]

--判断参数是否为空
if not dxq_id or string.len(dxq_id) == 0 
	or not region_id or string.len(region_id) == 0
   then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
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
--获取学校ID列表
local querySql = "select org_id from t_qyjh_dxq_org where b_use=1 and dxq_id="..dxq_id.." and region_id = "..region_id
local result, err, errno, sqlstate = db:query(querySql);
if not result then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	return;
end
--**********************
local orgids ={}
for i=1,#result,1 do
	table.insert(orgids,result[i]["org_id"])
end
--**********************
local returnjson = {}
returnjson.orgIds = orgids
returnjson.success = "true"
say(cjson.encode(returnjson))


--mysql放回连接池
db:set_keepalive(0,v_pool_size)