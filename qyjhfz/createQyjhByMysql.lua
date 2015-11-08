--[[
开通区域均衡[mysql版]
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
local region_id = args["region_id"]
local name = args["name"]
local description = args["description"]
local logo_url = args["logo_url"]

--从cookie获取当前用户的省市区ID
local cookie_province_id = tostring(ngx.var.cookie_background_province_id)
local cookie_city_id = tostring(ngx.var.cookie_background_city_id)
local cookie_district_id = tostring(ngx.var.cookie_background_district_id)

--判断参数是否为空
if not region_id or string.len(region_id) == 0 
  or not name or string.len(name) == 0 
  or not description or string.len(description) == 0 
  or not logo_url or string.len(logo_url) == 0 
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

--判断是否已经开通
local querySql = "select b_open from t_qyjh_qyjhs where qyjh_id= "..region_id;
local result, err, errno, sqlstate = db:query(querySql);
if not result then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	return;
end
if result and #result>=1 then
	say("{\"success\":false,\"info\":\"已经开通！\"}")
	return
end

--(1)存储开通信息

local ts = os.date("%Y%m%d%H%M%S")
--初始化统计信息开始
local numregion_id = tonumber(region_id)
local where = ""
if numregion_id > 300000 then
	where = " and district_id ="..numregion_id
elseif numregion_id > 200000 then
	where = " and city_id ="..numregion_id
else
	where = " and province_id ="..numregion_id
end
local sql = "SELECT COUNT(1) AS SCHCOUNT FROM T_BASE_ORGANIZATION O WHERE B_USE=1 AND O.ORG_TYPE=2"..where..";".."SELECT COUNT(1) AS TEACOUNT FROM T_BASE_PERSON P WHERE B_USE=1 and IDENTITY_ID=5 "..where..";";
local results, err, errno, sqlstate = db:query(sql);
if not results then
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}");
    return;
end
local SCHCOUNT = results[1]["SCHCOUNT"]
local res1 = db:read_result()		
local TEACOUNT = res1[1]["TEACOUNT"]
--初始化统计信息结束
local insertSql = "insert into t_qyjh_qyjhs(qyjh_id,name,description,logo_url,createtime,province_id,city_id,district_id,xx_tj,js_tj) values("..quote(region_id)..","..quote(name)..","..quote(description)..","..quote(logo_url)..","..quote(ts)..","..quote(cookie_province_id)..","..quote(cookie_city_id)..","..quote(cookie_district_id)..","..quote(SCHCOUNT)..","..quote(TEACOUNT)..")"

local results, err, errno, sqlstate = db:query(insertSql);
if not results then
	ngx.say("{\"success\":\"false\",\"info\":\"开通区域均衡失败！\"}");
    return;
end
--return
say("{\"success\":true,\"qyjh_id\":\""..region_id.."\",\"name\":\""..name.."\",\"b_use\":1,\"info\":\"开通成功！\"}")

--mysql放回连接池
db:set_keepalive(0,v_pool_size)