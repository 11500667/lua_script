--[[
根据大学区ID获取带头人列表[mysql版]
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
local pageSize = ngx.var.arg_pageSize
local pageNumber = ngx.var.arg_pageNumber

--判断参数是否为空
if not dxq_id or string.len(dxq_id) == 0 
	or not pageSize or string.len(pageSize) == 0 
	or not pageNumber or string.len(pageNumber) == 0
   then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end
pageSize = tonumber(pageSize)
pageNumber = tonumber(pageNumber)

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
--**********
local query_sql = "select person_id from t_qyjh_dxq_dtr where b_use=1 and dxq_id="..dxq_id.." ";
local limit_sql = " limit "..pageSize*pageNumber-pageSize..","..pageSize
local count_result, err, errno, sqlstate = db:query(query_sql);
local result, err, errno, sqlstate = db:query(query_sql..limit_sql);

if not result then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	return;
end
if #count_result == 0 then
	local returnjson = {}
	returnjson.list = ""
	returnjson.success = "true"
	returnjson.totalRow = 0
	returnjson.totalPage = 0
	returnjson.pageNumber = pageNumber
	returnjson.pageSize = pageSize
	say(cjson.encode(returnjson))
	return
end
local totalRow = #count_result
local totalPage = math.floor((totalRow + pageSize - 1) / pageSize)

local teaids = {}
for i=1,#result,1 do
	table.insert(teaids, result[i]["person_id"])
end
--获取person_id详情, 调用java接口
local personlist
local res_person = ngx.location.capture("/getTeaDetailInfo", {
	args = { person_id = table.concat(teaids,",") }
})
if res_person.status == 200 then
	personlist = cjson.decode(res_person.body)
else
	say("{\"success\":false,\"info\":\"查询失败！\"}")
	return
end

--获取大学区下的教师ID列表结束
local returnjson = {}
returnjson.list = personlist
returnjson.success = "true"
returnjson.totalRow = totalRow
returnjson.totalPage = totalPage
returnjson.pageNumber = pageNumber
returnjson.pageSize = pageSize
say(cjson.encode(returnjson))

--mysql放回连接池
db:set_keepalive(0,v_pool_size)
