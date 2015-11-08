--[[
维护大学区和学校的对应关系
@Author  chenxg
@Date    2015-01-19
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

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
  or not region_id or string.len(region_id) == 0 
  then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

--创建ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--大学区信息
local hdxq = ssdb:hget("qyjh_dxq",dxq_id)
local dxq = cjson.decode(hdxq[1])
--存储详细信息
local horgids = ssdb:hget("qyjh_dxq_orgs_"..dxq_id,region_id)
local orgids = horgids[1]

if not orgids or string.len(orgids) == 0 then
	orgids =","
end
if operationtype == "1" then
	orgids = ","..org_id.. orgids
	ssdb:hset("qyjh_dxq_orgs_"..dxq_id,region_id,orgids)
	--存储学校跟大学区的对应关系
	local olddxqids = ssdb:hget("qyjh_org_dxq",org_id)
	if not olddxqids[1] or string.len(olddxqids[1]) == 0 then
		olddxqids[1] =","
	end
	olddxqids[1] = string.gsub(olddxqids[1], ","..dxq_id..",", ",")
	ssdb:hset("qyjh_org_dxq",org_id,olddxqids[1]..dxq_id..",")
	
	--陈续刚2015.02.03添加，初始化学校上传数量开始
	ssdb:zset("qyjh_dxq_org_uploadcount_"..dxq_id,org_id,0)
	
	local hasqo = ssdb:hexists("qyjh_qyjh_org_uploadcount_"..dxq.qyjh_id,org_id)
	if hasqo[1] == "0" then	
		ssdb:zset("qyjh_qyjh_org_uploadcount_"..dxq.qyjh_id,org_id,0)
	end
	--陈续刚2015.02.03添加，初始化学校上传数量结束
elseif operationtype == "2" then
	orgids = string.gsub(orgids, ","..org_id..",", ",")
	ssdb:hset("qyjh_dxq_orgs_"..dxq_id,region_id,orgids)
	--存储学校跟大学区的对应关系
	local olddxqids = ssdb:hget("qyjh_org_dxq",org_id)
	local newdxqids = string.gsub(olddxqids[1], ","..dxq_id..",", ",")
	ssdb:hset("qyjh_org_dxq",org_id,newdxqids)
	
	--陈续刚2015.02.03添加，初始化学校上传数量开始
	local dorgupcount = ssdb:zget("qyjh_dxq_org_uploadcount_"..dxq_id,org_id)
	if not dorgupcount then
		dorgupcount = 0
	end
	dorgupcount = tonumber(dorgupcount[1])
	
	local qorgupcount = ssdb:zget("qyjh_dxq_org_uploadcount_"..dxq.qyjh_id,org_id)
	if not qorgupcount[1] or string.len(qorgupcount[1]) == 0 then
		qorgupcount[1] = 0
	end
	qorgupcount = tonumber(qorgupcount[1])
	
	ssdb:zdel("qyjh_dxq_org_uploadcount_"..dxq_id,org_id)
	ssdb:zset("qyjh_qyjh_org_uploadcount_"..dxq.qyjh_id,org_id,qorgupcount-dorgupcount)
	ngx.log(ngx.ERR, "===2> " .. dxq.qyjh_id .."**".. org_id.." <=sql=");
	--陈续刚2015.02.03添加，初始化学校上传数量结束
	
elseif operationtype == "3" or operationtype == "4" then
	ssdb:hdel("qyjh_dxq_orgs_"..dxq_id,region_id)
	--根据学校IDS获取学校列表开始
	local orglist
	local res_org = ngx.location.capture("/dsideal_yy/management/region/getSchoolByDistrict?district_id="..region_id.."&stage_id=0")

	if res_org.status == 200 then
		orglist = (cjson.decode(res_org.body))
	else
		say("{\"success\":false,\"info\":\"查询失败！\"}")
		return
	end

	--say(cjson.encode(orglist.table_list))
	local schs = orglist.table_list
	local ordids=""
	for i=1,#schs,1 do
		if operationtype == "3" then
			ordids = schs[i]["school_id"]..","..ordids
			--ssdb:hset("qyjh_org_dxq",schs[i]["school_id"],dxq_id)
			--存储学校跟大学区的对应关系
			local olddxqids = ssdb:hget("qyjh_org_dxq",schs[i]["school_id"])
			if not olddxqids[1] or string.len(olddxqids[1]) <= 2 then
				olddxqids[1] =","
			end
			--先删除原来已经对应的关系
			olddxqids[1] = string.gsub(olddxqids[1], ","..dxq_id..",", ",")
			--重新设置对应关系
			ssdb:hset("qyjh_org_dxq",schs[i]["school_id"],olddxqids[1]..dxq_id..",")
			
			--陈续刚2015.02.03添加，初始化学校上传数量开始
			local hasdo = ssdb:hexists("qyjh_dxq_org_uploadcount_"..dxq_id,schs[i]["school_id"])
			if  hasdo[1] == "0" then	
				ssdb:zset("qyjh_dxq_org_uploadcount_"..dxq_id,schs[i]["school_id"],0)
			end
			
			local hasqo = ssdb:hexists("qyjh_qyjh_org_uploadcount_"..dxq.qyjh_id,schs[i]["school_id"])
			if hasqo[1] == "0" then	
				ssdb:zset("qyjh_qyjh_org_uploadcount_"..dxq.qyjh_id,schs[i]["school_id"],0)
			end
			--陈续刚2015.02.03添加，初始化学校上传数量结束
		end
		if operationtype == "4" then
			--存储学校跟大学区的对应关系
			local olddxqids = ssdb:hget("qyjh_org_dxq",schs[i]["school_id"])
			local newdxqids = string.gsub(olddxqids[1], ","..dxq_id..",", ",")
			ssdb:hset("qyjh_org_dxq",schs[i]["school_id"],newdxqids)
			
			--陈续刚2015.02.03添加，初始化学校上传数量开始
			local dorgupcount = ssdb:zget("qyjh_dxq_org_uploadcount_"..dxq_id,schs[i]["school_id"])
			if not dorgupcount then
				dorgupcount = 0
			end
			dorgupcount = tonumber(dorgupcount[1])
			
			local qorgupcount = ssdb:zget("qyjh_qyjh_org_uploadcount_"..dxq.qyjh_id,schs[i]["school_id"])
			if not qorgupcount[1] or string.len(qorgupcount[1]) == 0 then
				qorgupcount[1] = 0
			end
			qorgupcount = tonumber(qorgupcount[1])
			
			ssdb:zdel("qyjh_dxq_org_uploadcount_"..dxq_id,schs[i]["school_id"])
			ssdb:zset("qyjh_qyjh_org_uploadcount_"..dxq.qyjh_id,schs[i]["school_id"],qorgupcount-dorgupcount)
			ngx.log(ngx.ERR, "===4> " .. dxq.qyjh_id .."**".. schs[i]["school_id"].." <=sql=");
			--陈续刚2015.02.03添加，初始化学校上传数量结束
		end
	end 
	ordids = ","..ordids
	--根据学校IDS获取学校列表结束
	if operationtype == "3" then
		ssdb:hset("qyjh_dxq_orgs_"..dxq_id,region_id,ordids)
	elseif operationtype == "4" then
		ssdb:hdel("qyjh_dxq_orgs_"..dxq_id,region_id)
	end
end
--修改大学区统计中的学校数量和教师数量开始
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
--获取学校ID列表
local b, err = ssdb:hgetall("qyjh_dxq_orgs_"..dxq_id)
if not b then 
	say("{\"success\":false,\"info\":\""..err.."\"}")
	return
end

local orgIDs = ""
for i=2,#b,2 do
	if b[i] ~="," then
		orgIDs = b[i] .. orgIDs
	end
end
orgIDs = string.gsub(orgIDs, ",,", ",")
local res = Split(orgIDs,",")
if #res <= 2 then
	ssdb:hset("qyjh_dxq_tj_"..dxq_id,"xx_tj",0)
	ssdb:hset("qyjh_dxq_tj_"..dxq_id,"js_tj",0)
else
	local ordids = "-1"
	for i=2,#res-1,1 do
		ordids = ordids..","..res[i]
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
	local where = " and bureau_id in("..ordids..")"
	local sql = "SELECT COUNT(1) AS TEACOUNT FROM T_BASE_PERSON P WHERE B_USE=1 and IDENTITY_ID=5 "..where..";";
	ngx.log(ngx.ERR, "===sql===> " .. #res .."**"..sql .. " <===sql===");

	local results, err, errno, sqlstate = db:query(sql);
	if not results then
		ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}");
		ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
		return;
	end
	local TEACOUNT = results[1]["TEACOUNT"]
	ssdb:hset("qyjh_dxq_tj_"..dxq_id,"xx_tj",#res-2)
	ssdb:hset("qyjh_dxq_tj_"..dxq_id,"js_tj",TEACOUNT)
	local ok, err = db: set_keepalive(0, v_pool_size);
	if not ok then
		ngx.log(ngx.ERR, "====>将Mysql数据库连接归还连接池出错！");
	end
end

--修改大学区统计中的学校数量和教师数量结束
say("{\"success\":true,\"info\":\"操作成功！\"}")

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
