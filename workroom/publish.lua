--[[
这是一个通用发布接口
将资源、试卷、备课、微课等发布到名师工作室、微课联盟等
@Author feiliming
@Date   2014-12-24
--]]

local say = ngx.say
local len = string.len
local gsub = string.gsub
local quote = ngx.quote_sql_str

local cjson = require "cjson"
local mysqllib = require "resty.mysql"
local redislib = require "resty.redis"
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

--获得请求参数
local person_id = args["person_id"]
local identity_id = args["identity_id"]
--local pub_type = args["pub_type"]
--local addArray = ngx.unescape_uri(args["addArray"])
--local delArray = ngx.unescape_uri(args["delArray"])
local target = ngx.unescape_uri(args["target"])
local obj_type = args["obj_type"]
local obj_id_int = args["obj_id_int"]
local obj_id_char = args["obj_id_char"]
local obj_info_id = args["obj_info_id"]
local obj_name = args["obj_name"]
local scheme_id = args["scheme_id"]
local structure_id = args["structure_id"]
local media_type = args["media_type"]
local app_type_id = args["app_type_id"]
local tp = args["type"]
local stage_id = args["stage_id"]
local subject_id = args["subject_id"]
--local qyjh_id = args["qyjh_id"]

if not person_id or len(person_id) == 0
	or not identity_id or len(identity_id) == 0
	--or not pub_type or len(pub_type) == 0
	--or not addArray
	--or not delArray
	or not target
	or not obj_type or len(obj_type) == 0
	or not obj_id_int or len(obj_id_int) == 0 
	or not obj_id_char or len(obj_id_char) == 0
	or not obj_info_id or len(obj_info_id) == 0 
	or not obj_name then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

if not scheme_id or len(scheme_id) == 0 then
	scheme_id = "-1"
end
if not structure_id or len(structure_id) == 0 then
	structure_id = "-1"
end
if not media_type or len(media_type) == 0 then
	media_type = "-1"
end
if not app_type_id or len(app_type_id) == 0 then
	app_type_id = "-1"
end
if not stage_id or len(stage_id) == 0 then
	stage_id = "-1"
end
if not subject_id or len(subject_id) == 0 then
	subject_id = "-1"
end
--if not qyjh_id or len(qyjh_id) == 0 then
--	qyjh_id = "-1"
--end

--连接redis服务器
local redis = redislib:new()
local ok, err = redis:connect(v_redis_ip,v_redis_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
local mysql, err = mysqllib:new()
if not mysql then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
local ok, err = mysql:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024 * 1024 }
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--ts
local n = ngx.now();
local ts = os.date("%Y%m%d%H%M%S").."00"..string.sub(n,12,14);
ts = ts..string.rep("0",19-string.len(ts));

--myinfo转info
--TODO如果以后资源、试卷的myinfo表去掉的话, 就不需要转换了
if tp and tp == "2" then
	if obj_type == "1" then --资源
		local sql = "SELECT SQL_NO_CACHE ID FROM T_RESOURCE_INFO_SPHINXSE "..
		"WHERE QUERY='filter=resource_id_int,"..obj_id_int..";select=(IF(group_id=2,1,0) OR IF(group_id=1,1,0)) as has_info;filter=has_info,1;sort=attr_desc:group_id;limit=1'"
		local result, err = mysql:query(sql)
		if result and result[1] then
			obj_info_id = result[1].ID
		end
	elseif obj_type == "3" then --试卷
		local sql = "SELECT SQL_NO_CACHE ID FROM T_SJK_PAPER_INFO_SPHINXSE "..
		"WHERE QUERY='filter=paper_id_int,"..obj_id_int..";select=(IF(group_id=2,1,0) OR IF(group_id=1,1,0)) as has_info;filter=has_info,1;sort=attr_desc:group_id;limit=1'"
		local result = mysql:query(sql)
		if result and result[1] then
			obj_info_id = result[1].ID
		end
	elseif obj_type == "4" then --备课
		local sql = "SELECT SQL_NO_CACHE ID FROM T_RESOURCE_INFO_SPHINXSE "..
		"WHERE QUERY='filter=resource_id_int,"..obj_id_int..";select=(IF(group_id=2,1,0) OR IF(group_id=1,1,0)) as has_info;filter=has_info,1;sort=attr_desc:group_id;limit=1'"
		local result, err = mysql:query(sql)
		if result and result[1] then
			obj_info_id = result[1].ID
		end
	end
end

--创建ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--
local t_target = cjson.decode(target)

for i=1,#t_target do
	local pub_type = t_target[i].pub_type
	pub_type = tostring(pub_type)
	local add = t_target[i].addArray
	local del = t_target[i].delArray
	--插入发布
	--addArray = gsub(addArray, "[%[%]\" ]", "")
	local school_id = redis:hget("person_"..person_id.."_"..identity_id, "xiao")
	--if addArray and len(addArray) > 0 then
		--ngx.log(ngx.ERR, type(school_id))
		--local add = Split(addArray, ",")
		for i=1,#add do

			local pub_target = add[i]
			--发布到区域均衡特殊处理
			local qyjh_id = "-1"
			--local dxq_id = "-1"用的pub_target
			local xzt_id = "-1"
			local hd_id = "-1"
			local hj_id = "-1"
			if pub_type == "3" then 
				local iddddd = Split(add[i], "_")
				qyjh_id = iddddd[1]
				pub_target = iddddd[2]
				xzt_id = iddddd[3]
				hd_id = iddddd[4]
				hj_id = iddddd[5]
			end
			
			--教研发布资源
			if pub_type == "5" then 
				local iddddd = Split(add[i], "_")
				pub_target = iddddd[1]
				qyjh_id = iddddd[2]
			end

			local id = redis:incr("t_base_publish_pk")
			local create_time = os.date("%Y".."-".."%m".."-".."%d".." ".."%H"..":".."%M"..":".."%S")
			local addsql = "insert into t_base_publish (id, person_id, identity_id"..
				", pub_time, ts, update_ts, pub_type, pub_target"..
				", obj_type, obj_id_int, obj_id_char, obj_name"..
				", obj_info_id, scheme_id, structure_id, media_type, app_type_id, b_delete, school_id, stage_id, subject_id, qyjh_id, xzt_id, hd_id, hj_id) values("
				..id..","..quote(person_id)..","..quote(identity_id)..
				","..quote(create_time)..","..quote(ts)..","..quote(ts)..","..quote(pub_type)..","..quote(pub_target)..
				","..quote(obj_type)..","..quote(obj_id_int)..","..quote(obj_id_char)..","..quote(obj_name)..
				","..quote(obj_info_id)..","..quote(scheme_id)..","..quote(structure_id)..","..quote(media_type)..","..quote(app_type_id)..
				",0,"..school_id..","..quote(stage_id)..","..quote(subject_id)..","..quote(qyjh_id)..","..quote(xzt_id)..","..quote(hd_id)..","..quote(hj_id)..")"
			--mysql
			local ok, err = mysql:query(addsql)
			if ok then
				redis:hmset("publish_"..id, "id", id, "obj_info_id", obj_info_id, "obj_type", obj_type, "xzt_id", xzt_id, "hd_id", hd_id)
			end
			--工作室统计数加1
			if pub_type == "1" then 
				ssdb:hincr("workroom_tj_all", "resource_count", 1)
				ssdb:set("workroom_generate_tj_ts_"..add[i], "1")
			end
			--微课联盟统计
			if pub_type == "2" then
				ssdb:zincr("league_stage_school_wknum", add[i].."_"..stage_id.."_"..school_id, 1)
				ssdb:zincr("league_stage_teacher_wknum", add[i].."_"..stage_id.."_"..person_id, 1)
				ssdb:zincr("league_school_wknum", add[i].."_"..school_id, 1)
				ssdb:zincr("league_teacher_wknum", add[i].."_"..person_id, 1)			
			end
			--区域均衡统计
			--[[if pub_type == "3" then 
				local qyjh_zy_sql = "update t_qyjh_qyjhs set zy_tj = zy_tj+1 where qyjh_id="..qyjh_id..";"
				mysql:query(qyjh_zy_sql);
				qyjh_zy_sql = "update t_qyjh_dxq set zy_tj = zy_tj+1 where dxq_id="..pub_target..";"
				mysql:query(qyjh_zy_sql);
				qyjh_zy_sql = "update t_qyjh_xzt set zy_tj = zy_tj+1 where xzt_id="..xzt_id..";"
				mysql:query(qyjh_zy_sql);
				if hd_id ~="-1" then
					qyjh_zy_sql = "update t_qyjh_hd set zy_tj = zy_tj+1 where hd_id="..hd_id..";"
					mysql:query(qyjh_zy_sql);
				end
			end]]
		end
	--end

	--标志删除发布
	--delArray = gsub(delArray, "[%[%]\" ]", "")
	--if delArray and len(delArray) > 0 then
		--local del = Split(delArray, ",")
		for i=1,#del do

			local pub_target = del[i]
			--发布到区域均衡特殊处理
			local qyjh_id = "-1"
			--local dxq_id = "-1"用的pub_target
			local xzt_id = "-1"
			local hd_id = "-1"
			local hj_id = "-1"
			if pub_type == "3" then 
				local iddddd = Split(del[i], "_")
				qyjh_id = iddddd[1]
				pub_target = iddddd[2]
				xzt_id = iddddd[3]
				hd_id = iddddd[4]
				hj_id = iddddd[5]
			end

			--select
			local ssql = "SELECT id from t_base_publish "..
			"WHERE person_id = "..quote(person_id).." "..
			"AND identity_id = "..quote(identity_id).."  AND pub_type = "..quote(pub_type).." "..
			"AND pub_target = "..quote(pub_target).." AND qyjh_id = "..quote(qyjh_id).." AND xzt_id = "..quote(xzt_id).." "..
			" AND hd_id = "..quote(hd_id).." AND hj_id = "..quote(hj_id).." "..
			" AND obj_type = "..quote(obj_type).." "..
			"AND obj_id_int = "..quote(obj_id_int).." "..--" AND obj_info_id = "..quote(obj_info_id).." "..
			"AND b_delete = 0"
			local result = mysql:query(ssql)
			if result and result[1] then
				--update
				local usql = "UPDATE t_base_publish SET b_delete = 1, update_ts = "..ts.." "..
				"WHERE id = "..result[1].id
				local ok, err = mysql:query(usql)
				if ok then
					redis:del("publish_"..result[1].id)
				end
			end
			--工作室统计数加1
			if pub_type == "1" then 
				ssdb:hincr("workroom_tj_all", "resource_count", -1)
				ssdb:set("workroom_generate_tj_ts_"..del[i], "1")
			end
			--微课联盟统计
			if pub_type == "2" then
				ssdb:zincr("league_stage_school_wknum", del[i].."_"..stage_id.."_"..school_id, -1)
				ssdb:zincr("league_stage_teacher_wknum", del[i].."_"..stage_id.."_"..person_id, -1)
				ssdb:zincr("league_school_wknum", del[i].."_"..school_id, 1)
				ssdb:zincr("league_teacher_wknum", del[i].."_"..person_id, 1)		
			end
			--区域均衡统计
			--[[if pub_type == "3" then 
				local qyjh_zy_sql = "update t_qyjh_qyjhs set zy_tj = zy_tj-1 where qyjh_id="..qyjh_id..";"
				mysql:query(qyjh_zy_sql);
				qyjh_zy_sql = "update t_qyjh_dxq set zy_tj = zy_tj-1 where dxq_id="..pub_target..";"
				mysql:query(qyjh_zy_sql);
				qyjh_zy_sql = "update t_qyjh_xzt set zy_tj = zy_tj-1 where xzt_id="..xzt_id..";"
				mysql:query(qyjh_zy_sql);
				if hd_id ~="-1" then
					qyjh_zy_sql = "update t_qyjh_hd set zy_tj = zy_tj-1 where hd_id="..hd_id..";"
					mysql:query(qyjh_zy_sql);
				end
			end]]
		end
	--end
end

say("{\"success\":true,\"info\":\"发布成功！\"}")

--放回连接池
redis:set_keepalive(0,v_pool_size)
mysql:set_keepalive(0,v_pool_size)
ssdb:set_keepalive(0,v_pool_size)