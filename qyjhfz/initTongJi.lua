--[[
重新统计区域均衡、大学区等信息
@Author  chenxg
@Date    2015-01-24
]]
local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"


--获得get请求参数
local region_id = ngx.var.arg_region_id
if not region_id or string.len(region_id) == 0 then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

--创建ssdb连接
local ssdb = ssdblib:new()
ssdb:set_timeout(3000) --不设置也可以, 默认2000
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
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
local numregion_id = tonumber(region_id)
local where = ""
if numregion_id > 300000 then
	where = " and district_id ="..numregion_id
elseif numregion_id > 200000 then
	where = " and city_id ="..numregion_id
else
	where = " and province_id ="..numregion_id
end
local sql = "SELECT COUNT(1) AS SCHCOUNT FROM T_BASE_ORGANIZATION O WHERE B_USE=1 AND O.ORG_TYPE=2"..where..";"..
			"SELECT COUNT(1) AS TEACOUNT FROM T_BASE_PERSON P WHERE B_USE=1 and IDENTITY_ID=5 "..where..";";
--ngx.log(ngx.ERR, "===sql===> " .. sql .. " <===sql===");

local results, err, errno, sqlstate = db:query(sql);
if not results then
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}");
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
    return;
end
local SCHCOUNT = results[1]["SCHCOUNT"]
local res1 = db:read_result()		
local TEACOUNT = res1[1]["TEACOUNT"]

--区域均衡下学校数量统计【根据区域ID获取学校数量，需要基础数据提供或者写自己sql语句统计】
ssdb:hset("qyjh_qyjh_tj_"..region_id,"xx_tj",SCHCOUNT)
--区域均衡下教师数量统计【根据区域ID获取教师数量，需要基础数据提供或者写自己sql语句统计】
ssdb:hset("qyjh_qyjh_tj_"..region_id,"js_tj",TEACOUNT)
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

--************************区域均衡下信息统计开始******************
local dxqs, err = ssdb:zrrange("qyjh_qyjh_dxqs_"..region_id,0,5000)
if not dxqs then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
if #dxqs<2 then 
	ssdb:hset("qyjh_qyjh_tj_"..region_id,"dxq_tj",0)
else 
	ssdb:hset("qyjh_qyjh_tj_"..region_id,"dxq_tj",(#dxqs/2))
end
--区域均衡下协作体数量统计
local xzts, err = ssdb:zrrange("qyjh_qyjh_xzts_"..region_id,0,5000)
if not xzts then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

if #xzts<2 then  
	ssdb:hset("qyjh_qyjh_tj_"..region_id,"xzt_tj",0)
else 
	ssdb:hset("qyjh_qyjh_tj_"..region_id,"xzt_tj",(#xzts/2))
end
--区域均衡下学校数量统计【根据区域ID获取学校数量，需要基础数据提供或者写自己sql语句统计】
ssdb:hset("qyjh_qyjh_tj_"..region_id,"xx_tj",SCHCOUNT)
--区域均衡下教师数量统计【根据区域ID获取教师数量，需要基础数据提供或者写自己sql语句统计】
ssdb:hset("qyjh_qyjh_tj_"..region_id,"js_tj",TEACOUNT)
--区域均衡下资源数量统计 陈续刚20150207添加
local qres = db:query("SELECT SQL_NO_CACHE id FROM t_base_allpublish_sphinxse WHERE query='filter=b_delete,0;filter=pub_type,3;filter=qyjh_id,"..region_id..";'")

ssdb:hset("qyjh_qyjh_tj_"..region_id,"zy_tj",#qres)

--区域均衡下活动数量统计
local totalHds = ssdb:zrrange("qyjh_qyjh_hds_"..region_id,0,100000)
local count = 0
if #totalHds>=2 then
	count = #totalHds/2
end
ssdb:hset("qyjh_qyjh_tj_"..region_id,"hd_tj",count)
--************************区域均衡下信息统计结束******************
if #dxqs>=2 then
	for i = 1,#dxqs,2 do
		--大学区下协作体数量统计
		local xzts, err = ssdb:hget("qyjh_dxq_xzts", dxqs[i])
		if not xzts then
			say("{\"success\":false,\"info\":\""..err.."\"}")
			return
		end
		
		if not xzts[1] or string.len(xzts[1]) <=2 then 
			ssdb:hset("qyjh_dxq_tj",dxqs[i].."_xzt_tj",0)
		else 
			local xztids = Split(xzts[1],",")
			
			ssdb:hset("qyjh_dxq_tj",dxqs[i].."_xzt_tj",#xztids-2)
			--*******协作体相关信息统计开始
			for j=2,#xztids-1,1 do
				--协作体下教师统计
				local teas,err = ssdb:hget("qyjh_xzt_teas",xztids[j])
				if not teas then
					say("{\"success\":false,\"info\":\""..err.."\"}")
					return
				end
				if not teas[1] or string.len(teas[1]) <=2 then 
					ssdb:hset("qyjh_xzt_tj",xztids[j].."_js_tj",0)
				else 
					local tesids = Split(teas[1],",")
					ssdb:hset("qyjh_xzt_tj",xztids[j].."_js_tj",#tesids-2)
				end
				
				--协作体下资源统计
				local xres = db:query("SELECT SQL_NO_CACHE id FROM t_base_allpublish_sphinxse WHERE query='filter=b_delete,0;filter=pub_type,3;filter=qyjh_id,"..region_id..";filter=xzt_id,"..xztids[j]..";'")
				ssdb:hset("qyjh_xzt_tj",xztids[j].."_zy_tj",#xres)
				
				--协作体下资源统计
				local wkres = db:query("SELECT SQL_NO_CACHE id FROM t_base_allpublish_sphinxse WHERE query='filter=b_delete,0;filter=pub_type,3;filter=qyjh_id,"..region_id..";filter=xzt_id,"..xztids[j]..";filter=obj_type,5'")
				ssdb:hset("qyjh_xzt_tj",xztids[j].."_wk_tj",#wkres)
				
				--协作体下活动统计
				local totalHds = ssdb:zrrange("qyjh_xzt_hds_"..xztids[j],0,100000)
				local count=0
				if #totalHds>=2 then
					count = #totalHds/2
				end
				ssdb:hset("qyjh_xzt_tj",xztids[j].."_hd_tj",count)
				
				--===========活动相关信息统计开始===========
				if #totalHds>=2 then
					--统计活动下的资源
					for h=1,#totalHds,2 do
						local hdres = db:query("SELECT SQL_NO_CACHE id FROM t_base_allpublish_sphinxse WHERE query='filter=b_delete,0;filter=pub_type,3;filter=qyjh_id,"..region_id..";filter=hd_id,"..totalHds[h]..";'")
						ssdb:hset("qyjh_hd_uploadcount",totalHds[h],#hdres)
					end
					--统计活动评论数
					
				end
				--===========活动相关信息统计结束===========
				
				--协作体点击量
				--ssdb:zset("qyjh_qyjh_xzt_djl_"..region_id, xztids[j],0)
				--ssdb:zset("qyjh_dxq_xzt_djl_"..dxqs[i], xztids[j],0)
			end
			--*******协作体相关信息统计结束
		end
		--大学区下带头人数量统计
		local dtrs = ssdb:hget("qyjh_dxq_dtrs",dxqs[i])
		local dtsc=2
		if string.len(dtrs[1])>2 then 
			dtsc = #Split(dtrs[1],",")
		end
		ssdb:hset("qyjh_dxq_tj",dxqs[i].."_dtr_tj",dtsc-2)
		
		--大学区下学校数量统计
		local orgs, err = ssdb:hgetall("qyjh_dxq_orgs_"..dxqs[i])
		if not orgs then
			say("{\"success\":false,\"info\":\""..err.."\"}")
			return
		end
		if not orgs[2] or string.len(orgs[2]) <=2 then 
			ssdb:hset("qyjh_dxq_tj",dxqs[i].."_xx_tj",0)
		else 
			local orgids = Split(orgs[2],",")
			ssdb:hset("qyjh_dxq_tj",dxqs[i].."_xx_tj",#orgids-2)
		end
	
		--大学区下教师数量统计【根据学校IDS获取教师数量，需要基础数据提供或者写自己sql语句统计】
		--*******************************
		local dxqteacount = 0
		if not orgs[2] or string.len(orgs[2]) <=2 then 
			dxqteacount = 0
		else 
			local res = Split(orgs[2],",")
			if #res >2 then 
				local ordids ="-2"
				for i=2,#res-1,1 do
					ordids = ordids..","..res[i]
				end
			
				local sql = "SELECT COUNT(1) AS TEACOUNT FROM T_BASE_PERSON P WHERE B_USE=1 and bureau_id in("..ordids..");";
				ngx.log(ngx.ERR, "===sql===> " .. sql .. " <===sql===");

				local result, err, errno, sqlstate = db:query(sql);
				if not result then
					ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}");
					ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
					return;
				end
				dxqteacount = result[1]["TEACOUNT"]
			end	
		end
		ssdb:hset("qyjh_dxq_tj",dxqs[i].."_js_tj",dxqteacount)
		--************************************
		--大学区下资源数量统计
		local dres = db:query("SELECT SQL_NO_CACHE id FROM t_base_allpublish_sphinxse WHERE query='filter=b_delete,0;filter=pub_type,3;filter=qyjh_id,"..region_id..";filter=pub_target,"..dxqs[i]..";'")
		ssdb:hset("qyjh_dxq_tj",dxqs[i].."_zy_tj",#dres)
		--区域均衡下活动数量统计
		local hdres = db:query("SELECT SQL_NO_CACHE id FROM t_qyjh_hd_sphinxse WHERE query='filter=b_delete,0;filter=dxq_id,"..dxqs[i]..";filter=qyjh_id,"..region_id..";'")
		ssdb:hset("qyjh_dxq_tj",dxqs[i].."_hd_tj",#hdres)	
	end
end
--************************大学区下信息统计结束******************



--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0,v_pool_size)

say("{\"success\":\"true\",\"info\":\"初始化统计信息成功！\"}")