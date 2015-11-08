--[[
区域均衡相关统计[mysql版]
@Author  chenxg
@Date    2015-06-04
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
--当前用户
local person_id = args["person_id"]
--1：大学区管理员统计 2：协作体带头人统计 3：统计自己的信息
local user_type = args["user_type"]
--统计类型：1：区域统计分析2：协作体统计分析3：学校统计分析4：个人统计分析
local tongji_type = args["tongji_type"]



--判断参数是否为空
if not person_id or string.len(person_id) == 0 
	or not user_type or string.len(user_type) == 0
	or not tongji_type or string.len(tongji_type) == 0
	then
    say("{\"success\":false,\"info\":\"person_id or user_type or tongji_type  参数错误！\"}")
    return
end

--根据分隔符分割字符串
function Split(str, delim, maxNb)   
	-- Eliminate bad cases...   
	if string.find(str, delim) == nil then  
		return { str }  
	end  
	if maxNb == nil or maxNb < 1 then  
		maxNb = 0    -- No limit   
	end  
	local result = {}
	local pat = "(.-)" .. delim .. "()"   
	local nb = 0  
	local lastPos   
	for part, pos in string.gfind(str, pat) do  
		nb = nb + 1  
		result[nb] = part   
		lastPos = pos   
		if nb == maxNb then break end  
	end  
	-- Handle the last field   
	if nb ~= maxNb then  
		result[nb + 1] = string.sub(str, lastPos)   
	end  
	return result
end

--创建ssdb连接
local ssdblib = require "resty.ssdb"
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--连接mysql数据库
local mysql = require "resty.mysql"
local mysql_db = mysql:new()
mysql_db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024*1024
}


local returnjson = {}
local xztCount = 0
local dtrCount = 0
local zyCount = 0
local hdzyCount = 0
local xxCount = 0 
local jsCount = 0
local hdCount = 0
if user_type == "1" then--大学区管理员相关统计
	--获取当前用户所管理的大学区
	local dxq_sql = "select dxq_id,xzt_tj,xx_tj,js_tj,hd_tj,zy_tj,dtr_tj  from t_qyjh_dxq d where b_delete=0 and b_use=1 and person_id = "..person_id
	local has_result, err, errno, sqlstate = mysql_db:query(dxq_sql);
	if not has_result then
		ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
		return;
	end
	returnjson.dxqCount = #has_result
	
	--资源数统计
	local dxq_ids = "0"
	for i=1,#has_result,1 do
		dxq_ids = has_result[i]["dxq_id"]..","..dxq_ids
	end
	local zy_sql = "select pub_target as dxq_id,count(distinct obj_id_int) as zy_tj from t_base_publish where b_delete=0 and pub_type=3 and pub_target in("..dxq_ids..") group by pub_target"
	local zy_result, err, errno, sqlstate = mysql_db:query(zy_sql);
	if not zy_result then
		ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
		ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
		return;
	end
	
	for i=1,#has_result,1 do
		local dxq_id = has_result[i]["dxq_id"]
		local xzt_tj = has_result[i]["xzt_tj"]
		local xx_tj = has_result[i]["xx_tj"]
		local js_tj = has_result[i]["js_tj"]
		local hd_tj = has_result[i]["hd_tj"]
		local zy_tj = 0
		for j=1,#zy_result,1 do
			if dxq_id == zy_result[j]["dxq_id"] then
				zy_tj = zy_result[j]["zy_tj"]
				break
			end
		end
		local dtr_tj = has_result[i]["dtr_tj"]
		
		xztCount = xztCount+tonumber(xzt_tj)
		--ngx.log(ngx.ERR,"---->"..xzt_tj[1].."<------")
		dtrCount = tonumber(dtrCount)+tonumber(dtr_tj)
		zyCount = tonumber(zyCount)+tonumber(zy_tj)
		xxCount = tonumber(xxCount)+tonumber(xx_tj)
		jsCount = tonumber(jsCount)+tonumber(js_tj)
		hdCount = tonumber(hdCount)+tonumber(hd_tj)
	end
elseif user_type == "2" then--协作体带头人相关统计
	local xzt_sql = "select xzt_id,js_tj,hd_tj from t_qyjh_xzt where b_use=1 and person_id = "..person_id.." "

	--获取协作体列表【带头人】
	local xzt_result, err, errno, sqlstate = mysql_db:query(xzt_sql);
	if not xzt_result then
		ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
		return;
	end
	xztCount = #xzt_result
	--资源数统计
	local xzt_ids = "0"
	for i=1,#xzt_result,1 do
		xzt_ids = xzt_result[i]["xzt_id"]..","..xzt_ids
	end
	local zy_sql = "select xzt_id,count(distinct obj_id_int) as zy_tj from t_base_publish where b_delete=0 and pub_type=3 and xzt_id in("..xzt_ids..") group by xzt_id"
	local zy_result, err, errno, sqlstate = mysql_db:query(zy_sql);
	if not zy_result then
		ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
		ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
		
		return;
	end
	
	for i=1,#xzt_result,1 do
		local xzt_id = xzt_result[i]["xzt_id"]
		--根据协作体获取资源数
		local zy_tj = 0
		for j=1,#zy_result,1 do
			if xzt_id == zy_result[j]["xzt_id"] then
				zy_tj = zy_result[j]["zy_tj"]
				break
			end
		end
		--根据协作体获取参与人数
		local js_tj = xzt_result[i]["js_tj"]
		--根据协作体获取活动数
		local hd_tj = xzt_result[i]["hd_tj"]
			
		zyCount = tonumber(zyCount)+tonumber(zy_tj)
		jsCount = tonumber(jsCount)+tonumber(js_tj)
		hdCount = tonumber(hdCount)+tonumber(hd_tj)
	end
	--根据协作体获取活动资源数
	local hdzyCountSql = "select count(distinct obj_info_id) as hdzyCount from t_base_publish p where p.pub_type = 3 and p.b_delete=0 and p.xzt_id in(select xzt_id from t_qyjh_xzt where b_use=1 and person_id = "..person_id.." ) and hd_id != -1";
	--ngx.log(ngx.ERR,"cxg_log======>"..hdzyCountSql.."<====")
	local hdzy_res = mysql_db:query(hdzyCountSql)
	hdzyCount = hdzy_res[1]["hdzyCount"]
elseif user_type == "3" then--协作体带头人、普通教师相关统计
	--协作体
	local xzt_sql = "select xzt_id from t_qyjh_xzt_tea where b_use=1 and tea_id = "..person_id..""
	local xzt_result, err, errno, sqlstate = mysql_db:query(xzt_sql);
	if not xzt_result then
		ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
		return;
	end
	xztCount = #xzt_result
	
	local hd_sql = "select hd_id from t_qyjh_hd where b_delete=0 and xzt_id in(select xzt_id from t_qyjh_xzt_tea where b_use=1 and tea_id = "..person_id..")"
	local hd_result, err, errno, sqlstate = mysql_db:query(hd_sql);
	if not hd_result then
		ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
		return;
	end
	--if 
	hdCount = #hd_result--[1]["hd_count"]
	--资源数
	local res_sql = "select count(distinct obj_info_id) as res_count from t_base_publish where b_delete=0 and pub_type=3 and xzt_id in(select xzt_id from t_qyjh_xzt_tea where b_use=1 and tea_id = "..person_id..") and person_id="..person_id.."";
	local res_result, err, errno, sqlstate = mysql_db:query(res_sql);
	if not res_result then
		ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
		return;
	end
	zyCount = res_result[1]["res_count"]

	--根据协作体获取活动资源数
	local hdzyCountSql = "select count(distinct obj_info_id) as hdzyCount from t_base_publish p where p.pub_type = 3 and p.b_delete=0 and p.xzt_id in(select xzt_id from t_qyjh_xzt_tea where b_use=1 and tea_id = "..person_id.." ) and hd_id > 0 and person_id="..person_id.."";
	ngx.log(ngx.ERR,"cxg_log   ======>"..hdzyCountSql.."<====")
	local hdzy_res = mysql_db:query(hdzyCountSql)
	hdzyCount = hdzy_res[1]["hdzyCount"]
	
	--获取协作体教师总数
	local xzt_js_sql = "select sum(js_tj) as js_tj from t_qyjh_xzt where b_use=1 and xzt_id in(select xzt_id from t_qyjh_xzt_tea where b_use=1 and tea_id = "..person_id..") "
	local xzt_js_result, err, errno, sqlstate = mysql_db:query(xzt_js_sql);
	if not xzt_js_result then
		ngx.say("{\"success\":false,\"info\":\"查询教师数据失败 ！\"}");
		return;
	end
	local js_tj = xzt_js_result[1]["js_tj"]
	jsCount = tonumber(js_tj)
end

returnjson.xztCount = xztCount
returnjson.dtrCount = dtrCount
returnjson.zyCount = zyCount
returnjson.hdzyCount = hdzyCount
returnjson.xxCount = xxCount
returnjson.jsCount = jsCount
returnjson.hdCount = hdCount

returnjson.success = "true"

say(cjson.encode(returnjson))

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
--mysql放回连接池
mysql_db:set_keepalive(0,v_pool_size)