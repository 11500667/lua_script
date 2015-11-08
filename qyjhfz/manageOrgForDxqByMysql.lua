--[[
维护大学区和学校的对应关系 学校只能属于一个大学区[mysql版]
@Author  chenxg
@Date    2015-06-01
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local quote = ngx.quote_sql_str

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
	--操作：1单个选中,2单个取消，3全部选中，4全部取消
local operationtype = args["operationtype"]
local region_id = args["region_id"]

--判断参数是否为空
if not dxq_id or string.len(dxq_id) == 0  
  or not operationtype or string.len(operationtype) == 0  
  or not org_id or string.len(org_id) == 0 
  or not region_id or string.len(region_id) == 0 
  then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
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
	return
end
--大学区信息
local dxq_Sql = "select qyjh_id from t_qyjh_dxq where dxq_id= "..dxq_id;
ngx.log(ngx.ERR, "bad result: ", ""..dxq_Sql.."");
local dxq_result, err, errno, sqlstate = db:query(dxq_Sql);
if not dxq_result then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	return
end
local dxq = {}
dxq.qyjh_id = dxq_result[1]["qyjh_id"]

--存储详细信息
local ts = os.date("%Y%m%d%H%M%S")


local where = " and bureau_id ="..org_id..""
local sql = "SELECT COUNT(1) AS TEACOUNT FROM T_BASE_PERSON P WHERE B_USE=1 and IDENTITY_ID=5 "..where..";";

local results, err, errno, sqlstate = db:query(sql);
if not results then
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}");
	ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	return;
end
local TEACOUNT = results[1]["TEACOUNT"]

if operationtype == "1" then
	--********************************
	local querySql = "select dxq_id from t_qyjh_dxq_org where b_use=1 and org_id= "..org_id;
	local result, err, errno, sqlstate = db:query(querySql);
	if not result then
		ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
		return
	end
	if #result >= 1 then
		say("{\"success\":false,\"info\":\"该学校已经被别的大学区选取，请选择别的学校！\"}")
		return
	end
	--********************************
	--存储大学区跟学校的关系
	local insertSql = "insert into t_qyjh_dxq_org (qyjh_id,dxq_id,org_id,start_time,region_id)values("..quote(dxq.qyjh_id)..","..quote(dxq_id)..","..quote(org_id)..","..quote(ts)..","..quote(region_id)..")"
	db:query(insertSql)

	local updateSql = "update t_qyjh_dxq set xx_tj = xx_tj+1,js_tj = js_tj+"..TEACOUNT.." where dxq_id="..dxq_id..""
	db:query(updateSql)
elseif operationtype == "2" then
	--更新大学区跟学校的对应关系
	local updateSql = "update t_qyjh_dxq_org set b_use = 0,end_time = "..quote(ts).." where dxq_id = "..quote(dxq_id).." and org_id="..quote(org_id).."and b_use = 1"
	db:query(updateSql)
	local updateSql = "update t_qyjh_dxq set xx_tj = xx_tj-1,js_tj = js_tj-"..TEACOUNT.." where dxq_id="..dxq_id..""
	db:query(updateSql)
end
say("{\"success\":true,\"info\":\"操作成功！\"}")

--mysql放回连接池
db:set_keepalive(0, v_pool_size)
