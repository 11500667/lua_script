--[[
区域均衡相关统计
@Author  chenxg
@Date    2015-03-17
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
	local dxqs = ssdb:hget("qyjh_manager_dxqs",person_id)
	if string.len(dxqs[1])>1 then
		local dxqids = Split(dxqs[1],",")
		returnjson.dxqCount = #dxqids-2
		for i=2,#dxqids-1,1 do
			local xzt_tj = ssdb:hget("qyjh_dxq_tj",dxqids[i].."_xzt_tj")
			local xx_tj = ssdb:hget("qyjh_dxq_tj",dxqids[i].."_xx_tj")
			local js_tj = ssdb:hget("qyjh_dxq_tj",dxqids[i].."_js_tj")
			local hd_tj = ssdb:hget("qyjh_dxq_tj",dxqids[i].."_hd_tj")
			local zy_tj = ssdb:hget("qyjh_dxq_tj",dxqids[i].."_zy_tj")
			local dtr_tj = ssdb:hget("qyjh_dxq_tj",dxqids[i].."_dtr_tj")
			
			xztCount = xztCount+tonumber(xzt_tj[1])
			--ngx.log(ngx.ERR,"---->"..xzt_tj[1].."<------")
			dtrCount = tonumber(dtrCount)+tonumber(dtr_tj[1])
			zyCount = tonumber(zyCount)+tonumber(zy_tj[1])
			xxCount = tonumber(xxCount)+tonumber(xx_tj[1])
			jsCount = tonumber(jsCount)+tonumber(js_tj[1])
			hdCount = tonumber(hdCount)+tonumber(hd_tj[1])
		end
	end
elseif user_type == "2" then--协作体带头人相关统计
	--获取协作体列表【带头人】
	local xzts = ssdb:hget("qyjh_manager_xzts",person_id)
	local xztids = Split(xzts[1],",")
	if string.len(xzts[1])>2 then
		xztCount = #xztids-2
		for i=2,#xztids-1,1 do
			--根据协作体获取资源数
			local zy_tj = ssdb:hget("qyjh_xzt_tj",xztids[i].."_zy_tj")
			--根据协作体获取参与人数
			local js_tj = ssdb:hget("qyjh_xzt_tj",xztids[i].."_js_tj")
			--根据协作体获取活动数
			local hd_tj = ssdb:hget("qyjh_xzt_tj",xztids[i].."_hd_tj")
				
			zyCount = tonumber(zyCount)+tonumber(zy_tj[1])
			jsCount = tonumber(jsCount)+tonumber(js_tj[1])
			hdCount = tonumber(hdCount)+tonumber(hd_tj[1])
		end
		--根据协作体获取活动资源数
		local hdzyCountSql = "select count(1) as hdzyCount from t_base_publish p where p.pub_type = 3 and p.xzt_id in("..string.sub(xzts[1],2,string.len(xzts[1])-1)..") and hd_id != -1";
		ngx.log(ngx.ERR,"====>"..hdzyCountSql.."<====")
		local hdzy_res = mysql_db:query(hdzyCountSql)
		hdzyCount = hdzy_res[1]["hdzyCount"]
	end
elseif user_type == "3" then--协作体带头人、普通教师相关统计
	--协作体
	local xzts = ssdb:hget("qyjh_tea_xzts",person_id)
	if string.len(xzts[1])>1 then
		local xztids = Split(xzts[1],",")
		xztCount = #xztids-2
		local xzt = ssdb:hget("qyjh_xzt",xztids[2])
		local temp = cjson.decode(xzt[1])
		--根据大学区获取活动
		local hd_tj = ssdb:hget("qyjh_dxq_tj",temp.dxq_id.."_hd_tj")
		hdCount = hd_tj[1]
		--资源数
		zyCount = ssdb:zget("qyjh_dxq_tea_uploadcount_"..temp.dxq_id,person_id)[1]
	end
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