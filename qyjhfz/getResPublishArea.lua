--[[
根据当前用户获取资源发布范围
@Author  chenxg
@Date    2015-03-03
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"
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
--参数 
local person_id = ngx.var.arg_person_id
local pub_type = ngx.var.arg_pub_type
local obj_type = ngx.var.arg_obj_type
local obj_id_int = ngx.var.arg_obj_id_int
local qyjh_id = ngx.var.arg_qyjh_id
if not person_id or string.len(person_id) == 0
	or not pub_type or string.len(pub_type) == 0
	or not obj_type or string.len(obj_type) == 0
	or not obj_id_int or string.len(obj_id_int) == 0 then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

local returnjson = {}
--判断参数是否为空
if not person_id or string.len(person_id) == 0 then
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
--获取当前用户所相关的协作体（所属和所管理，不包含大学区负责人）======================
local list1 = {}
local xzts = ssdb:hget("qyjh_tea_xzts",person_id)
local jtbk_hj = {}--集体备课环节
local jxgm_hj = {}--教学观摩环节


--查询已发布
local sql = "SELECT pub_target,qyjh_id,xzt_id,hd_id,hj_id FROM t_base_publish p WHERE "..
	"p.person_id = "..person_id.." AND p.pub_type = "..pub_type.." "..
	"AND p.obj_type = "..obj_type.." AND p.obj_id_int = "..obj_id_int.." AND p.b_delete = 0"
	local result, err = db:query(sql)
if not result then
	say("{\"success\":false,\"info\":\""..err.."\"}")
	return
end

if xzts[1] and string.len(xzts[1])>2 then
	local tids = {}
	local xztids = Split(xzts[1],",")
	for i=2,#xztids-1,1 do
		table.insert(tids, xztids[i])
	end
	--协作体列表
	local xztlist, err = ssdb:multi_hget('qyjh_xzt',unpack(tids));
	for i=2,#xztlist,2 do
		local t = cjson.decode(xztlist[i])
		local xzt = {}
		xzt.name = t.name
		xzt.xzt_id = t.qyjh_id.."_"..t.dxq_id.."_"..t.xzt_id.."_-1_-1"
		xzt.publish = "0"
		
		for j=1,#result do
			local iddddd = result[j].qyjh_id.."_"..result[j].pub_target.."_"..result[j].xzt_id.."_"..result[j].hd_id.."_"..result[j].hj_id
			--say(xzt.xzt_id.."**"..iddddd)
			if xzt.xzt_id == tostring(iddddd) then
				xzt.publish = "1"
			end
		end
		
		--根据协作体获取活动
		local hdlist = ssdb:zrrange("qyjh_xzt_hds_"..t.xzt_id,0,100000)
		local hdlist1 = {}
		if #hdlist>=2 then
			for j=1,#hdlist,2 do
				local hd = {}
				local hhd = ssdb:hget("qyjh_hd",hdlist[j])
				--ngx.log(ngx.ERR,"@@@@@@@@@"..hdlist[j].."@@@@@@@@@")
				if string.len(hhd[1])>1 then 
					local temphd = cjson.decode(hhd[1])
					local id = t.qyjh_id.."_"..t.dxq_id.."_"..t.xzt_id.."_"..temphd.hd_id
					hd.hd_id = t.qyjh_id.."_"..t.dxq_id.."_"..t.xzt_id.."_"..temphd.hd_id.."_-1"
					hd.active_name = temphd.active_name
					hd.publish = "0"
					
					for j=1,#result do
						local iddddd = result[j].qyjh_id.."_"..result[j].pub_target.."_"..result[j].xzt_id.."_"..result[j].hd_id.."_"..result[j].hj_id
						if hd.hd_id == tostring(iddddd) then
							hd.publish = "1"
						end
					end
					
					
					----活动类型：1培训学习2专家讲座3集体备课4教学观摩5交流研讨
					if temphd.hd_type == "3" then
						local hj_1_publish ="0"				
						local hj_2_publish ="0"				
						local hj_3_publish ="0"				
						local hj_4_publish ="0"				
						local hj_5_publish ="0"				
						for j=1,#result do
							local iddddd = result[j].qyjh_id.."_"..result[j].pub_target.."_"..result[j].xzt_id.."_"..result[j].hd_id.."_"..result[j].hj_id
							if id.."_1" == tostring(iddddd) then
								hj_1_publish = "1"
							elseif id.."_2" == tostring(iddddd) then
								hj_2_publish = "1"
							elseif id.."_3" == tostring(iddddd) then
								hj_3_publish = "1"
							elseif id.."_4" == tostring(iddddd) then
								hj_4_publish = "1"
							elseif id.."_5" == tostring(iddddd) then
								hj_5_publish = "1"
							end
						end
					
						jtbk_hj[1] = cjson.decode("{\"hjname\":\"主备\",\"hjid\":\""..id.."_1\",\"publish\":\""..hj_1_publish.."\"}")
jtbk_hj[2] = cjson.decode("{\"hjname\":\"协备\",\"hjid\":\""..id.."_2\",\"publish\":\""..hj_2_publish.."\"}")
jtbk_hj[3] = cjson.decode("{\"hjname\":\"自备\",\"hjid\":\""..id.."_3\",\"publish\":\""..hj_3_publish.."\"}")
jtbk_hj[4] = cjson.decode("{\"hjname\":\"反思\",\"hjid\":\""..id.."_4\",\"publish\":\""..hj_4_publish.."\"}")
jtbk_hj[5] = cjson.decode("{\"hjname\":\"总结\",\"hjid\":\""..id.."_5\",\"publish\":\""..hj_5_publish.."\"}")
						hd.hj = jtbk_hj
					elseif temphd.hd_type == "4" then
					
					
						local hj_1_publish ="0"				
						local hj_2_publish ="0"				
						local hj_3_publish ="0"							
						for j=1,#result do
							local iddddd = result[j].qyjh_id.."_"..result[j].pub_target.."_"..result[j].xzt_id.."_"..result[j].hd_id.."_"..result[j].hj_id
							if id.."_1" == tostring(iddddd) then
								hj_1_publish = "1"
							elseif id.."_2" == tostring(iddddd) then
								hj_2_publish = "1"
							elseif id.."_3" == tostring(iddddd) then
								hj_3_publish = "1"
							end
						end
						jxgm_hj[1] = cjson.decode("{\"hjname\":\"上课\",\"hjid\":\""..id.."_1\",\"publish\":\""..hj_1_publish.."\"}")
jxgm_hj[2] = cjson.decode("{\"hjname\":\"说课\",\"hjid\":\""..id.."_2\",\"publish\":\""..hj_2_publish.."\"}")
jxgm_hj[3] = cjson.decode("{\"hjname\":\"评课\",\"hjid\":\""..id.."_3\",\"publish\":\""..hj_3_publish.."\"}")
						hd.hj = jxgm_hj
					else
						hd.hj={}
					end
					hdlist1[#hdlist1+1] = hd
				end
			end
		end
		xzt.hd_list = hdlist1
		list1[#list1+1] = xzt
	end
	
end

returnjson.xztlist = list1
returnjson.success = "true"
say(cjson.encode(returnjson))


--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0, v_pool_size)
