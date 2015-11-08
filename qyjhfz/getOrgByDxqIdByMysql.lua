--[[
根据大学区ID获取学校列表[mysql版]
@Author  chenxg
@Date    2015-06-02
--]]
local say = ngx.say

--引用模块
local cjson = require "cjson"

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
local returnjson = {}
--***************************
local count_sql = "select org_id from t_qyjh_dxq_org where b_use = 1 and dxq_id="..dxq_id.." ";
local limit_sql = " limit "..pageSize*pageNumber-pageSize..","..pageSize.." "
local count_result, err, errno, sqlstate = db:query(count_sql);

local result, err, errno, sqlstate = db:query(count_sql..limit_sql);
if not count_result then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	return
end
local totalRow = #count_result
local totalPage = math.floor((totalRow + pageSize - 1) / pageSize)
returnjson.totalPage = totalPage
returnjson.totalRow = totalRow
--***************************
if #count_sql <= 0 then
	local list = {}
	returnjson.list = list
	returnjson.pageNumber = pageNumber
	returnjson.pageSize = pageSize
	say(cjson.encode(returnjson))
	return
end
 
--分页学校IDS
local orgids ="-1"
for i=1,#count_result,1 do
	orgids = orgids..","..result[i]["org_id"]
end
--根据学校IDS获取学校列表开始
local orglist
local res_org = ngx.location.capture("/dsideal_yy/org/getSchoolNameByIds?ids=".. orgids)

if res_org.status == 200 then
	orglist = (cjson.decode(res_org.body))
else
	say("{\"success\":false,\"info\":\"查询失败！\"}")
	--return
end
--根据学校IDS获取学校列表结束

returnjson.list = orglist.list
returnjson.success = "true"
returnjson.totalRow = totalRow
returnjson.totalPage = totalPage
returnjson.pageNumber = pageNumber
returnjson.pageSize = pageSize
say(cjson.encode(returnjson))

--mysql放回连接池
db:set_keepalive(0,v_pool_size)