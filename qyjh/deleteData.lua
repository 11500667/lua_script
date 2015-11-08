--[[
删除区域均衡下的全部垃圾数据
@Author  chenxg
@Date    2015-02-13
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"


--获得get请求参数
local region_id = ngx.var.arg_region_id
local isdelqyjh = ngx.var.arg_isdelqyjh
local isdeldxq = ngx.var.arg_isdeldxq
local isdelxzt = ngx.var.arg_isdelxzt
local isdelhd = ngx.var.arg_isdelhd
local qyjh_id = region_id
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
--获取区域均衡下所有大学区
local dxqs, err = ssdb:hget("qyjh_dxqs", region_id)
if not dxqs then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
--获取区域均衡下所有协作体
--[[local dxqs, err = ssdb:hget("qyjh_dxqs", region_id)
if not dxqs then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end]]
--删除活动相关信息
	--删除区域均衡跟活动的对应关系
	local qyjhHds = ssdb:zrrange("qyjh_qyjh_hds_"..qyjh_id,0,100000)
	if #qyjhHds>=2 then
		for i=1,(#qyjhHds/2),2 do
			ssdb:hdel("qyjh_hd",qyjhHds[i])
			ssdb:zdel("qyjh_qyjh_hds_"..qyjh_id,qyjhHds[i])
			ssdb:zdel("qyjh_qyjh_hds_"..qyjh_id.."_1",qyjhHds[i])
			ssdb:zdel("qyjh_qyjh_hds_"..qyjh_id.."_2",qyjhHds[i])
			ssdb:zdel("qyjh_qyjh_hds_"..qyjh_id.."_3",qyjhHds[i])
			ssdb:zdel("qyjh_qyjh_hds_"..qyjh_id.."_4",qyjhHds[i])
			ssdb:zdel("qyjh_qyjh_hds_"..qyjh_id.."_5",qyjhHds[i])
		end
	end
	--删除大学区跟活动的对应关系
	if string.len(dxqs[1]) >=2 then
		local dxqids = Split(dxqs[1],",")
		for d=2,#dxqids-1,1 do
			--获取大学区下的所有学校
			local dallorgids = ssdb:hgetall("qyjh_dxq_orgs_"..dxqids[d])
			if string.len(dallorgids[1]) >=2 
			--获取大学区下的协作体
			local xzts, err = ssdb:hget("qyjh_dxq_xzts", dxqids[d])
			if not xzts then
				say("{\"success\":false,\"info\":\""..err.."\"}")
				return
			end
			if not xzts[1] or string.len(xzts[1]) <=2 then 
				ssdb:hdel("qyjh_dxq_tj_"..dxqids[d],"xzt_tj")
			else
				local xztids = Split(xzts[1],",")
				for x=2,#xztids-1,1 do
					--获取协作体下的活动
					local xztHds = ssdb:zrrange("qyjh_xzt_hds_"..xztids[x],0,100000)
					--删除协作体跟活动的对应关系
					if #xztHds>=2 then
						for h=1,#xztHds/2,2 do
							ssdb:zdel("qyjh_xzt_hds_"..xztids[x],xztHds[h])
							ssdb:zdel("qyjh_xzt_hds_"..xztids[x].."_1",xztHds[h])
							ssdb:zdel("qyjh_xzt_hds_"..xztids[x].."_2",xztHds[h])
							ssdb:zdel("qyjh_xzt_hds_"..xztids[x].."_3",xztHds[h])
							ssdb:zdel("qyjh_xzt_hds_"..xztids[x].."_4",xztHds[h])
							ssdb:zdel("qyjh_xzt_hds_"..xztids[x].."_5",xztHds[h])
						end
					end
					--删除协作体的相关信息
						local personid = ssdb:hget("qyjh_xzt_manager",xztids[x])
						--删除负责人
						ssdb:hdel("qyjh_xzt_manager",xztids[x])
						ssdb:hdel("qyjh_manager_xzts",personid[1])
						--删除教师上传信息
						
						--删除基本信息
						ssdb:hdel("qyjh_xzt",xztids[x])
						--删除统计信息
						ssdb:hclear("qyjh_xzt_tj_"..xztids[x])
						
				end
			end
			
			--获取大学区下的活动
			
			--删除协作体相关信息
		end
		
	
	end
	--删除协作体跟活动的对应关系

--删除区域均衡信息


--删除区域均衡跟大学区的对应关系
ssdb:hdel("qyjh_dxqs",qyjh_id)
--删除区域均衡跟协作体的对应关系
ssdb:hdel("qyjh_qyjh_xzts",qyjh_id)
--***********************************************************************
if not dxqs[1] or string.len(dxqs[1]) <=2 then 
	ssdb:hset("qyjh_qyjh_tj_"..region_id,"dxq_tj",0)
else 
	local dxqids = Split(dxqs[1],",")
	ssdb:hset("qyjh_qyjh_tj_"..region_id,"dxq_tj",#dxqids-2)
end
--区域均衡下协作体数量统计
local xzts, err = ssdb:hget("qyjh_qyjh_xzts", region_id)
if not xzts then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
if not xzts[1] or string.len(xzts[1]) <=2 then 
	ssdb:hset("qyjh_qyjh_tj_"..region_id,"xzt_tj",0)
else 
	local xztids = Split(xzts[1],",")
	ssdb:hset("qyjh_qyjh_tj_"..region_id,"xzt_tj",#xztids-2)
end
--区域均衡下学校数量统计【根据区域ID获取学校数量，需要基础数据提供或者写自己sql语句统计】
ssdb:hset("qyjh_qyjh_tj_"..region_id,"xx_tj",SCHCOUNT)
--区域均衡下教师数量统计【根据区域ID获取教师数量，需要基础数据提供或者写自己sql语句统计】
ssdb:hset("qyjh_qyjh_tj_"..region_id,"js_tj",TEACOUNT)
--区域均衡下资源数量统计 陈续刚20150207添加
local qres = db:query("SELECT SQL_NO_CACHE id FROM t_base_publish_sphinxse WHERE query='filter=b_delete,0;filter=pub_type,3;groupby=attr:obj_info_id;sort=attr_desc:DOWN_COUNT;'")
ssdb:hset("qyjh_qyjh_tj_"..region_id,"zy_tj",#qres)
--区域均衡下活动数量统计
local totalHds = ssdb:zrrange("qyjh_qyjh_hds_"..region_id,0,100000)
if #totalHds>=2 then
	count = #totalHds/2
end
ssdb:hset("qyjh_qyjh_tj_"..region_id,"hd_tj",count)
--************************区域均衡下信息统计结束******************
--************************大学区下信息统计开始******************

if not dxqs[1] or string.len(dxqs[1]) >2 then
	local dxqids = Split(dxqs[1],",")
	for i=2,#dxqids-1,1 do
		--大学区下协作体数量统计
		local xzts, err = ssdb:hget("qyjh_dxq_xzts", dxqids[i])
		if not xzts then
			say("{\"success\":false,\"info\":\""..err.."\"}")
			return
		end
		if not xzts[1] or string.len(xzts[1]) <=2 then 
			ssdb:hset("qyjh_dxq_tj_"..dxqids[i],"xzt_tj",0)
		else 
			local xztids = Split(xzts[1],",")
			ssdb:hset("qyjh_dxq_tj_"..dxqids[i],"xzt_tj",#xztids-2)
			--*******协作体相关信息统计开始
			for j=2,#xztids-1,1 do
				--协作体下教师统计
				local teas,err = ssdb:hget("qyjh_xzt_teas",xztids[j])
				if not teas then
					say("{\"success\":false,\"info\":\""..err.."\"}")
					return
				end
				if not teas[1] or string.len(teas[1]) <=2 then 
					ssdb:hset("qyjh_xzt_tj_"..xztids[j],"js_tj",0)
				else 
					local orgids = Split(teas[1],",")
					ssdb:hset("qyjh_xzt_tj_"..xztids[j],"js_tj",#orgids-2)
				end
				--协作体下资源统计 陈续刚20150207添加
				local xres = db:query("SELECT SQL_NO_CACHE id FROM t_base_publish_sphinxse WHERE query='filter=b_delete,0;filter=pub_type,3;filter=pub_target,"..xztids[j]..";groupby=attr:obj_info_id;'")
				ssdb:hset("qyjh_xzt_tj_"..xztids[j],"zy_tj",#xres)
				--协作体下活动统计
				local totalHds = ssdb:zrrange("qyjh_xzt_hds_"..xztids[j],0,100000)
				local count=0
				if #totalHds>=2 then
					count = #totalHds/2
				end
				ssdb:hset("qyjh_xzt_tj_"..xztids[j],"hd_tj",count)
				--协作体点击量
				ssdb:zset("qyjh_qyjh_xzt_djl_"..region_id, xztids[j],0)
				ssdb:zset("qyjh_dxq_xzt_djl_"..dxqids[i], xztids[j],0)
			end
			--*******协作体相关信息统计结束
		end
		
		--大学区下学校数量统计
		local orgs, err = ssdb:hgetall("qyjh_dxq_orgs_"..dxqids[i])
		if not orgs then
			say("{\"success\":false,\"info\":\""..err.."\"}")
			return
		end
		if not orgs[2] or string.len(orgs[2]) <=2 then 
			ssdb:hset("qyjh_dxq_tj_"..dxqids[i],"xx_tj",0)
		else 
			local orgids = Split(orgs[2],",")
			ssdb:hset("qyjh_dxq_tj_"..dxqids[i],"xx_tj",#orgids-2)
		end
		
		--大学区下教师数量统计【根据学校IDS获取教师数量，需要基础数据提供或者写自己sql语句统计】
		--*******************************
		if not orgs[2] or string.len(orgs[2]) <=2 then 
			local dxqteacount = 0
		else 
			local res = Split(orgs[2],",")
			if #res >2 then 
				local ordids ="0"
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
				local dxqteacount = result[1]["TEACOUNT"]
			end	
		end
		--************************************
		ssdb:hset("qyjh_dxq_tj_"..dxqids[i],"js_tj",dxqteacount)
		--区域均衡下资源数量统计 陈续刚20150207添加
		local dres = db:query("SELECT SQL_NO_CACHE id FROM t_base_publish_sphinxse WHERE query='filter=b_delete,0;filter=pub_type,3;filter=pub_target,"..dxqids[i]..";groupby=attr:obj_info_id;'")
		ssdb:hset("qyjh_dxq_tj_"..dxqids[i],"zy_tj",#dres)
		--区域均衡下活动数量统计
		local totalHds = ssdb:zrrange("qyjh_dxq_hds_"..dxqids[i],0,100000)
		local count=0
		if #totalHds>=2 then
			count = #totalHds/2
		end
		ssdb:hset("qyjh_dxq_tj_"..dxqids[i],"hd_tj",count)
		--大学区点击量
		--ssdb:zset("qyjh_dxq_djl_"..region_id, dxqids[i],0)
	end
end
--************************大学区下信息统计结束******************




local ok, err = db: set_keepalive(0, v_pool_size);
if not ok then
	ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
end

say("{\"success\":\"true\",\"info\":\"初始化统计信息成功！\"}")