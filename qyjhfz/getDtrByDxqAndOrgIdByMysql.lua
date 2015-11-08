--[[
根据大学区ID、学校ID获取带头人列表[mysql版]
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
local org_id = args["org_id"]

--判断参数是否为空
if not dxq_id or string.len(dxq_id) == 0 
	or not org_id or string.len(org_id) == 0
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
local querySql = "select person_id from t_qyjh_dxq_dtr where b_use=1 and dxq_id="..dxq_id.." and org_id="..org_id
local result, err, errno, sqlstate = db:query(querySql);
if not result then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	return;
end
--**********************
local teaids ={}
for i=1,#result,1 do
	table.insert(teaids,result[i]["person_id"])
end
--**********************

local returnjson = {}
returnjson.teaids = teaids
returnjson.success = "true"
say(cjson.encode(returnjson))

--mysql放回连接池
db:set_keepalive(0,v_pool_size)
