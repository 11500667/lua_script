--[[
跟基础数据同步时，获取缺失学段学科信息的名师列表
@Author  chenxg
@Date    2015-05-21
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
local pageSize = args["pageSize"]
local pageNumber = args["pageNumber"]
if not pageSize or string.len(pageSize) == 0 
	or not pageNumber or string.len(pageNumber) == 0 
	  then
		say("{\"success\":false,\"info\":\"pageSize or pageNumber 参数错误！\"}")
		return
	end

--获取mysql数据库连接
local mysql = require "resty.mysql";
local db, err = mysql : new();
if not db then 
	ngx.log(ngx.ERR, err);
	return;
end
db:set_timeout(1000) -- 1 sec

local ok, err, errno, sqlstate = db:connect{
	host = v_mysql_ip,
	port = v_mysql_port,
	database = v_mysql_database,
	user = v_mysql_user,
	password = v_mysql_password,
	max_packet_size = 1024 * 1024 }

if not ok then
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}")
	ngx.log(ngx.ERR, "=====> 连接数据库失败!");
	return
end

local returnjson = {}
pageSize = tonumber(pageSize)
pageNumber = tonumber(pageNumber)

local limit = "limit "..pageNumber*pageSize-pageSize..","..pageSize..""
-- t_base_person_exception   t_person_ex
local person_Sql = "select p.person_id,p.person_name,o.org_name from t_base_person_exception e left join t_base_person p on e.person_id = p.person_id left join t_base_organization o on p.bureau_id = o.org_id ";

local all_person_list, err, errno, sqlstate = db:query(person_Sql);
local person_list, err, errno, sqlstate = db:query(person_Sql..limit);

if not all_person_list then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	ngx.log(ngx.ERR, "cxg_log==="..sch_sql.."<====countsql");
	return;
end

local totalRow = #all_person_list
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

returnjson.totalPage = totalPage
returnjson.pageNumber = pageNumber
returnjson.pageSize = pageSize
returnjson.totalRow = totalRow
local sch_res_list = {}
for i=1,#person_list do
	local res_list = {}
	res_list.person_id = person_list[i]["person_id"]
	res_list.person_name = person_list[i]["person_name"]
	res_list.org_name = person_list[i]["org_name"]
	sch_res_list[i] = res_list
end

returnjson.person_list = sch_res_list
returnjson.success = true
say(cjson.encode(returnjson))

--mysql放回连接池
db:set_keepalive(0, v_pool_size)
