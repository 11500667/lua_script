--[[
重新统计区域均衡、大学区等信息[mysql版]
@Author  chenxg
@Date    2015-06-05
]]
local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

--获得get请求参数
local region_id = ngx.var.arg_region_id
if not region_id or string.len(region_id) == 0 then
    say("{\"success\":false,\"info\":\" region_id 参数错误！\"}")
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

local numregion_id = tonumber(region_id)
local where = ""
if numregion_id > 300000 then
	where = " and district_id ="..numregion_id
elseif numregion_id > 200000 then
	where = " and city_id ="..numregion_id
else
	where = " and province_id ="..numregion_id
end
--************************区域均衡下信息统计开始******************
--区域均衡下大学区数量统计
local qyjh_dxq_sql = "select dxq_id from t_qyjh_dxq where b_use=1 and qyjh_id="..region_id
local qyjh_dxq_results, err, errno, sqlstate = db:query(qyjh_dxq_sql);
if not qyjh_dxq_results then
	ngx.say("{\"success\":\"false\",\"info\":\"查询大学区数据失败！\"}");
    return;
end
local qyjh_dxq_tj = #qyjh_dxq_results

--区域均衡下协作体数量统计
local qyjh_xzt_sql = "select count(1) as xzt_tj from t_qyjh_xzt where b_use=1 and qyjh_id="..region_id
local qyjh_xzt_results, err, errno, sqlstate = db:query(qyjh_xzt_sql);
if not qyjh_xzt_results then
	ngx.say("{\"success\":\"false\",\"info\":\"查询协作体数据失败！\"}");
    return;
end
local qyjh_xzt_tj = qyjh_xzt_results[1]["xzt_tj"]

--区域均衡下学校数量统计【根据区域ID获取学校数量，需要基础数据提供或者写自己sql语句统计】
local qyjh_xx_sql = "SELECT COUNT(1) AS xx_tj FROM T_BASE_ORGANIZATION O WHERE B_USE=1 AND O.ORG_TYPE=2"..where..";";
local qyjh_xx_results, err, errno, sqlstate = db:query(qyjh_xx_sql);
if not qyjh_xx_results then
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}");
    return;
end
local qyjh_xx_tj = qyjh_xx_results[1]["xx_tj"]

--区域均衡下教师数量统计【根据区域ID获取教师数量，需要基础数据提供或者写自己sql语句统计】
local qyjh_js_sql = "SELECT COUNT(1) AS js_tj FROM T_BASE_PERSON P WHERE B_USE=1 and IDENTITY_ID=5 "..where..";";
local qyjh_js_results, err, errno, sqlstate = db:query(qyjh_js_sql);
if not qyjh_js_results then
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}");
    return;
end
local qyjh_js_tj = qyjh_js_results[1]["js_tj"]

--区域均衡下资源数量统计 陈续刚20150207添加
local qyjh_zy_sql = "select count(distinct obj_id_int) from t_base_publish where b_delete=0 and pub_type=3 and qyjh_id="..region_id..""
local qyjh_zy_results, err, errno, sqlstate = db:query(qyjh_zy_sql);
if not qyjh_zy_results then
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}");
    return;
end
local qyjh_zy_tj = #qyjh_zy_results

--区域均衡下活动数量统计
local qyjh_hd_sql = "select count(1) as hd_tj from t_qyjh_hd where b_delete=0 and qyjh_id="..region_id
local qyjh_hd_results, err, errno, sqlstate = db:query(qyjh_hd_sql);
if not qyjh_hd_results then
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}");
    return;
end
local qyjh_hd_tj = qyjh_hd_results[1]["hd_tj"]

local qyjh_sql = "update t_qyjh_qyjhs set dxq_tj="..qyjh_dxq_tj..",xzt_tj = "..qyjh_xzt_tj..",xx_tj = "..qyjh_xx_tj..",js_tj = "..qyjh_js_tj..",hd_tj = "..qyjh_hd_tj..",zy_tj = "..qyjh_zy_tj.." where qyjh_id="..region_id
local qyjh_results, err, errno, sqlstate = db:query(qyjh_sql);
if not qyjh_results then
	ngx.say("{\"success\":\"false\",\"info\":\"初始化区域均衡统计信息失败！\"}");
    return;
end

--************************区域均衡下信息统计结束******************
if #qyjh_dxq_results>=1 then
	for i = 1,#qyjh_dxq_results,1 do
		--大学区下协作体数量统计
		local dxq_id = qyjh_dxq_results[i]["dxq_id"]
		local dxq_xzt_sql = "select xzt_id from t_qyjh_xzt where b_use=1 and dxq_id="..dxq_id
		local dxq_xzt_results, err, errno, sqlstate = db:query(dxq_xzt_sql);
		if not dxq_xzt_results then
			ngx.say("{\"success\":\"false\",\"info\":\"查询协作体数据失败！\"}");
			return;
		end
		local dxq_xzt_tj = #dxq_xzt_results
		
		--*******协作体相关信息统计开始
		for j=1,#dxq_xzt_results,1 do
			--协作体下教师统计
			local xzt_id= dxq_xzt_results[j]["xzt_id"]
			local xzt_js_sql = "select count(1) as js_tj from t_qyjh_xzt_tea where b_use=1 and xzt_id="..xzt_id
			local xzt_js_results, err, errno, sqlstate = db:query(xzt_js_sql);
			if not xzt_js_results then
				ngx.say("{\"success\":\"false\",\"info\":\"查询协作体数据失败！\"}");
				return;
			end
			local xzt_js_tj = xzt_js_results[1]["js_tj"]
		
			--协作体下资源统计
			local xzt_zy_tj = db:query("select count(distinct obj_id_int) from t_base_publish where b_delete=0 and pub_type=3 and qyjh_id="..region_id.." and xzt_id="..xzt_id.."")
			
			--协作体下微课统计
			local xzt_wk_tj = db:query("select count(distinct obj_id_int) from t_base_publish where b_delete=0 and pub_type=3 and qyjh_id="..region_id.." and xzt_id="..xzt_id.." and obj_type=5")
			
			--协作体下活动统计
			local xzt_hd_sql = "select hd_id from t_qyjh_hd where b_delete=0 and xzt_id="..xzt_id
			local xzt_hd_results, err, errno, sqlstate = db:query(xzt_hd_sql);
			if not xzt_hd_results then
				ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}");
				return;
			end
			local xzt_hd_tj = #xzt_hd_results
			
			local xzt_sql = "update t_qyjh_xzt set js_tj = "..xzt_js_tj..",hd_tj = "..xzt_hd_tj..",zy_tj = "..#xzt_zy_tj..",wk_tj = "..#xzt_wk_tj.." where xzt_id="..xzt_id
			local xzt_results, err, errno, sqlstate = db:query(xzt_sql);
			if not xzt_results then
				ngx.say("{\"success\":\"false\",\"info\":\"初始化协作体统计信息失败！\"}");
				return;
			end
			
			--===========活动相关信息统计开始===========
			if #xzt_hd_results>=1 then
				--统计活动下的资源
				for h=1,#xzt_hd_results,1 do
					local hd_id = xzt_hd_results[h]["hd_id"]
					
					local hd_zy_tj = db:query("select count(distinct obj_id_int) from t_base_publish where b_delete=0 and pub_type=3 and qyjh_id="..region_id.." and hd_id="..hd_id.."")

					local hd_wk_tj = db:query("select count(distinct obj_id_int) from t_base_publish where b_delete=0 and pub_type=3 and qyjh_id="..region_id.." and hd_id="..hd_id.." and obj_type=5")

					local hd_sql = "update t_qyjh_hd set zy_tj = "..#hd_zy_tj..",wk_tj = "..#hd_wk_tj.." where hd_id="..hd_id
					local hd_results, err, errno, sqlstate = db:query(hd_sql);
					if not hd_results then
						ngx.say("{\"success\":\"false\",\"info\":\"初始化活动统计信息失败！\"}");
						return;
					end
				end				
			end
			--===========活动相关信息统计结束===========

		end
		--*******协作体相关信息统计结束
		--大学区下带头人数量统计
		local dxq_dtr_sql = "select count(1) as dtr_tj from t_qyjh_dxq_dtr where b_use=1 and dxq_id="..dxq_id
		local dxq_dtr_results, err, errno, sqlstate = db:query(dxq_dtr_sql);
		if not dxq_dtr_results then
			ngx.say("{\"success\":\"false\",\"info\":\"初始化大学区带头人统计信息失败！\"}");
			return;
		end
		local dxq_dtr_tj = dxq_dtr_results[1]["dtr_tj"]
		
		--大学区下学校数量统计
		local dxq_xx_sql = "select org_id from t_qyjh_dxq_org where b_use=1 and dxq_id="..dxq_id
		local dxq_xx_results, err, errno, sqlstate = db:query(dxq_xx_sql);
		if not dxq_xx_results then
			ngx.say("{\"success\":\"false\",\"info\":\"初始化大学区学校数量统计信息失败！\"}");
			return;
		end
		local dxq_xx_tj = #dxq_xx_results
		--大学区下教师数量统计【根据学校IDS获取教师数量，需要基础数据提供或者写自己sql语句统计】
		local dxq_js_sql = "SELECT COUNT(1) AS js_tj FROM T_BASE_PERSON P WHERE B_USE=1 and bureau_id in("..dxq_xx_sql..");";
		local dxq_js_results, err, errno, sqlstate = db:query(dxq_js_sql);
		if not dxq_js_results then
			ngx.say("{\"success\":\"false\",\"info\":\"初始化大学区学校数量统计信息失败！\"}");
			return;
		end
		local dxq_js_tj = dxq_js_results[1]["js_tj"]

		--大学区下资源数量统计
		local dxq_zy_tj = db:query("select count(distinct obj_id_int) from t_base_publish where b_delete=0 and pub_type=3 and qyjh_id="..region_id.." and pub_target="..dxq_id.." ")
		
		--大学区下活动数量统计
		local dxq_hd_sql = "select hd_id from t_qyjh_hd where b_delete=0 and dxq_id="..dxq_id
		local dxq_hd_results, err, errno, sqlstate = db:query(dxq_hd_sql);
		if not dxq_hd_results then
			ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}");
			return;
		end
		local dxq_hd_tj = #dxq_hd_results
		
		local dxq_sql = "update t_qyjh_dxq set xzt_tj = "..dxq_xzt_tj..",xx_tj = "..dxq_xx_tj..",js_tj = "..dxq_js_tj..",hd_tj = "..dxq_hd_tj..",zy_tj = "..#dxq_zy_tj.." where qyjh_id="..region_id
		local dxq_results, err, errno, sqlstate = db:query(dxq_sql);
		if not dxq_results then
			ngx.say("{\"success\":\"false\",\"info\":\"初始化大学区统计信息失败！\"}");
			return;
		end
		
	end
end
--************************大学区下信息统计结束******************

--mysql放回连接池
db:set_keepalive(0,v_pool_size)

say("{\"success\":\"true\",\"info\":\"初始化统计信息成功！\"}")