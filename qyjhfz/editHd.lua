--[[
保存编辑后的活动信息
@Author  chenxg
@Date    2015-02-09
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"
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
local hd_id = args["hd_id"]
local active_name = args["active_name"]--活动名称
local subject_id = args["subject_id"]--学段科目
local start_date = args["start_date"]--开始时间
local end_date = args["end_date"]--结束时间
local con_pass = args["con_pass"]--会议密码
local description = args["description"]--描述

--判断参数是否为空
if not hd_id or string.len(hd_id) == 0 
  or not active_name or string.len(active_name) == 0 
  or not start_date or string.len(start_date) == 0 
  or not end_date or string.len(end_date) == 0  
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

local hd = ssdb:hget("qyjh_hd",hd_id)
local hd = cjson.decode(hd[1])
local hd_confid = hd.hd_confid
local hd_type = hd.hd_type
local status = 200
	--跟告白特对接开始 陈续刚2014-02-09添加
	if hd_type ~="1" then
		local res_hd, err = ngx.location.capture("/editHDForGBT", {
			args = {hd_confid = hd_confid,active_name = active_name,start_date = start_date,end_date = end_date,con_pass = con_pass}
		})
		status = res_hd.status
	end
	if status == 200 then
		
		--**********************
		--存储详细信息
		hd.active_name = active_name
		hd.description = description
		hd.subject_id = subject_id
		hd.person_id = person_id
		hd.start_date = start_date
		hd.end_date = end_date
		hd.statu="1"
		hd.con_pass=con_pass

		local ok, err = ssdb:hset("qyjh_hd", hd_id, cjson.encode(hd))
		if not ok then
		   say("{\"success\":false,\"info\":\""..err.."\"}")
		   return
		else
			say("{\"success\":true,\"hd_id\":\""..hd_id.."\",\"name\":\""..active_name.."\",\"info\":\"编辑活动成功！\"}")
		end
		--跟告白特对接结束
		--**********************
		
		--往mysql表中存储活动信息
		local n = ngx.now();
		local ts2 = os.date("%Y%m%d%H%M%S").."00"..string.sub(n,12,14);
		ts2 = ts2..string.rep("0",19-string.len(ts2));
		
		
		local stonum = start_date
		stonum = string.gsub(stonum,"-","")
		stonum = string.gsub(stonum,":","")
		stonum = string.gsub(stonum," ","")
		
		local updateSql = "update t_qyjh_hd  set hd_name ="..quote(active_name)..",start_time="..quote(start_date)..",end_time="..quote(end_date)..",subject_id="..quote(subject_id)..",ts="..quote(ts2)..",startts = "..quote(stonum*100).." where hd_id="..quote(hd_id);
				
		db:query(updateSql)
		
	else
		say("{\"success\":false,\"info\":\"编辑活动失败！\"}")
		return
	end
	


--return

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0, v_pool_size)
