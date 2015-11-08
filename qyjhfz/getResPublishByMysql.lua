--[[
根据当前用户获取资源发布范围[mysql版]
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


--判断参数是否为空
if not person_id or string.len(person_id) == 0 then
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
local jtbk_hj = {}--集体备课环节
local jxgm_hj = {}--教学观摩环节

local xzt_sql = "select distinct x.qyjh_id,x.dxq_id,x.xzt_id,x.xzt_name as name from t_qyjh_xzt x,t_qyjh_xzt_tea xt where x.xzt_id = xt.xzt_id and xt.b_use=1 and tea_id = "..person_id.." "
local xzt_result, err, errno, sqlstate = db:query(xzt_sql);
if not xzt_result then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	return;
end

--查询已发布
local sql = "SELECT pub_target,qyjh_id,xzt_id,hd_id,hj_id FROM t_base_publish p WHERE "..
	"p.person_id = "..person_id.." AND p.pub_type = "..pub_type.." "..
	"AND p.obj_type = "..obj_type.." AND p.obj_id_int = "..obj_id_int.." AND p.b_delete = 0"
	local result, err = db:query(sql)
if not result then
	say("{\"success\":false,\"info\":\""..err.."\"}")
	return
end

if #xzt_result>0 then
	for i=1,#xzt_result,1 do
		local t = {}
		t.qyjh_id = xzt_result[i]["qyjh_id"]
		t.dxq_id = xzt_result[i]["dxq_id"]
		t.xzt_id = xzt_result[i]["xzt_id"]
		t.name = xzt_result[i]["name"]
		
		local xzt = {}
		xzt.name = t.name
		xzt.id = t.qyjh_id.."_"..t.dxq_id.."_"..t.xzt_id.."_-1_-1"
		xzt.pId = "0"
		xzt.checked = false
		xzt.open = true
		
		for j=1,#result do
			local iddddd = result[j].qyjh_id.."_"..result[j].pub_target.."_"..result[j].xzt_id.."_"..result[j].hd_id.."_"..result[j].hj_id
			--say(xzt.xzt_id.."**"..iddddd)
			if xzt.id == tostring(iddddd) then
				xzt.checked = true
				break
			end
		end
		
		--根据协作体获取活动
		local hd_sql = "select qyjh_id,dxq_id,xzt_id,hd_id,lx_id as hd_type,hd_name as active_name from t_qyjh_hd where b_delete = 0 and xzt_id="..t.xzt_id
		local hd_result, err, errno, sqlstate = db:query(hd_sql);
		if not hd_result then
			ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
			return;
		end
		
		local hdlist1 = {}
		if #hd_result>0 then
			for j=1,#hd_result,1 do
				local hd = {}
				local temphd = {}
				
				temphd.hd_id  = hd_result[j]["hd_id"]
				temphd.active_name = hd_result[j]["active_name"]
				temphd.hd_type = hd_result[j]["hd_type"]
				
				local id = t.qyjh_id.."_"..t.dxq_id.."_"..t.xzt_id.."_"..temphd.hd_id
				hd.id = t.qyjh_id.."_"..t.dxq_id.."_"..t.xzt_id.."_"..temphd.hd_id.."_-1"
				hd.name = temphd.active_name
				hd.pId = xzt.id
				hd.checked = false
				
				for j=1,#result do
					local iddddd = result[j].qyjh_id.."_"..result[j].pub_target.."_"..result[j].xzt_id.."_"..result[j].hd_id.."_"..result[j].hj_id
					if hd.id == tostring(iddddd) then
						hd.checked = true
						break
					end
				end
				
				
				----活动类型：1培训学习2专家讲座3集体备课4教学观摩5交流研讨
				--[[
				if temphd.hd_type == "3" then
					local hj_1_checked = false				
					local hj_2_checked = false				
					local hj_3_checked = false				
					local hj_4_checked = false				
					local hj_5_checked = false				
					for j=1,#result do
						local iddddd = result[j].qyjh_id.."_"..result[j].pub_target.."_"..result[j].xzt_id.."_"..result[j].hd_id.."_"..result[j].hj_id
						if id.."_1" == tostring(iddddd) then
							hj_1_checked = true
						elseif id.."_2" == tostring(iddddd) then
							hj_2_checked = true
						elseif id.."_3" == tostring(iddddd) then
							hj_3_checked = true
						elseif id.."_4" == tostring(iddddd) then
							hj_4_checked = true
						elseif id.."_5" == tostring(iddddd) then
							hj_5_checked = true
						end
					end
				
					jtbk_hj[1] = cjson.decode("{\"pId\":\""..hd.id.."\",\"name\":\"主备\",\"id\":\""..id.."_1\",\"checked\":"..hj_1_checked.."}")
jtbk_hj[2] = cjson.decode("{\"pId\":\""..hd.id.."\",\"name\":\"协备\",\"id\":\""..id.."_2\",\"checked\":"..hj_2_checked.."}")
jtbk_hj[3] = cjson.decode("{\"pId\":\""..hd.id.."\",\"name\":\"自备\",\"id\":\""..id.."_3\",\"checked\":"..hj_3_checked.."}")
jtbk_hj[4] = cjson.decode("{\"pId\":\""..hd.id.."\",\"name\":\"反思\",\"id\":\""..id.."_4\",\"checked\":"..hj_4_checked.."}")
jtbk_hj[5] = cjson.decode("{\"pId\":\""..hd.id.."\",\"name\":\"总结\",\"id\":\""..id.."_5\",\"checked\":"..hj_5_checked.."}")
					--hd.hj = jtbk_hj
					list1[#list1+1] = jtbk_hj[1]
					list1[#list1+1] = jtbk_hj[2]
					list1[#list1+1] = jtbk_hj[3]
					list1[#list1+1] = jtbk_hj[4]
					list1[#list1+1] = jtbk_hj[5]
				elseif temphd.hd_type == "4" then
				
				
					local hj_1_checked = false				
					local hj_2_checked = false				
					local hj_3_checked = false							
					for j=1,#result do
						local iddddd = result[j].qyjh_id.."_"..result[j].pub_target.."_"..result[j].xzt_id.."_"..result[j].hd_id.."_"..result[j].hj_id
						if id.."_1" == tostring(iddddd) then
							hj_1_checked = true
						elseif id.."_2" == tostring(iddddd) then
							hj_2_checked = true
						elseif id.."_3" == tostring(iddddd) then
							hj_3_checked = true
						end
					end
					jxgm_hj[1] = cjson.decode("{\"pId\":\""..hd.id.."\",\"name\":\"上课\",\"id\":\""..id.."_1\",\"checked\":\""..hj_1_checked.."\"}")
jxgm_hj[2] = cjson.decode("{\"pId\":\""..hd.id.."\",\"name\":\"说课\",\"id\":\""..id.."_2\",\"checked\":\""..hj_2_checked.."\"}")
jxgm_hj[3] = cjson.decode("{\"pId\":\""..hd.id.."\",\"name\":\"评课\",\"id\":\""..id.."_3\",\"checked\":\""..hj_3_checked.."\"}")
					hd.hj = jxgm_hj
					list1[#list1+1] = jxgm_hj[1]
					list1[#list1+1] = jxgm_hj[2]
					list1[#list1+1] = jxgm_hj[3]
				end
				]]
				list1[#list1+1] = hd
			end
		end
		--xzt.hd_list = hdlist1
		list1[#list1+1] = xzt
	end
	
end
say(cjson.encode(list1))

--mysql放回连接池
db:set_keepalive(0, v_pool_size)
