--[[
记录区域均衡在新闻模块中的系统号[mysql版]
@Author  chenxg
@Date    2015-06-05
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"

--获得get请求参数
--local qyjh_id = ngx.var.arg_qyjh_id
local qyjh_id = ngx.var.arg_qyjh_id
--类型： 1：存储 2：获取
local page_type = ngx.var.arg_page_type
--类型： 1:公告 2:新闻
local news_type = ngx.var.arg_news_type


local regist_id = ngx.var.arg_regist_id

if not qyjh_id or string.len(qyjh_id) == 0 
	or not page_type or string.len(page_type) == 0 
	or not news_type or string.len(news_type) == 0 
then
    say("{\"success\":false,\"info\":\"qyjh_id or page_type or news_type 参数错误！\"}")
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

local returnjson = {}
returnjson.success=true

if page_type == "1" then -- 存储
	local insert_sql = "insert into t_qyjh_news_regist(qyjh_id,news_type,regist_id) values("..qyjh_id..","..news_type..","..regist_id..")"
	local result, err, errno, sqlstate = db:query(insert_sql);
	if not result then
		ngx.say("{\"success\":false,\"info\":\"创建注册号失败！\"}");
		return;
	end
else --获取注册号
	local query_sql = "select regist_id from t_qyjh_news_regist where qyjh_id="..qyjh_id.." and news_type="..news_type..""
	local result, err, errno, sqlstate = db:query(query_sql);
	if not result then
		ngx.say("{\"success\":false,\"info\":\"查询注册号失败！\"}");
		return;
	end

	if #result>0 then
		returnjson.regist_id = result[1]["regist_id"]
	else
		returnjson.success=false
	end
end
--return
say(cjson.encode(returnjson))
--mysql放回连接池
db:set_keepalive(0,v_pool_size)