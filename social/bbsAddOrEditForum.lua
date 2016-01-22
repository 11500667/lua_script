--[[
分区添加版块
@Author feiliming
@Date   2015-3-23
]]

local say = ngx.say
local len = string.len
local quote = ngx.quote_sql_str

--require model
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"
local mysqllib = require "resty.mysql"

--get args
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

local forum_id = args["forum_id"]
local partition_id = args["partition_id"]
local bbs_id = args["bbs_id"]
local name = args["name"]
local icon_url = args["icon_url"]
local description = args["description"]
local sequence = args["sequence"]
local forum_admin_list = args["forum_admin_list"]
if not partition_id or len(partition_id) == 0 or
	not bbs_id or len(bbs_id) == 0 or
	not name or len(name) == 0 or
	--not icon_url or
	not description or
	not sequence or len(sequence) == 0 or
	not forum_admin_list or len(forum_admin_list) == 0 then
	say("{\"success\":false,\"info\":\"参数错误！\"}")
	return
end
local forum_admin_t = cjson.decode(forum_admin_list)
if #forum_admin_t == 0 then
	say("{\"success\":false,\"info\":\"参数错误！\"}")
	return
end	

--ssdb
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--mysql
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

if forum_id and len(forum_id) > 0 then
	--update mysql
	local usql = "update t_social_bbs_forum set name = "..quote(name)..
	" ,icon_url = "..quote(icon_url)..",description = "..quote(description)..",sequence = "..sequence..
	" where id = "..forum_id
	local uresutl, err = mysql:query(usql)
	if not uresutl then
    	say("{\"success\":false,\"info\":\""..err.."\"}")
   		return
	end
	
	--删除版主
	local usql2 = "update t_social_bbs_forum_user set flag = 0 where forum_id = "..forum_id.." and flag = 1"
	--添加版主
	ngx.log(ngx.ERR,cjson.encode(forum_admin_t))
	for i=1, #forum_admin_t do
		local forum_admin = forum_admin_t[i]
		local sql11 = "select * from t_social_bbs_forum_user where forum_id = "..forum_id.." and person_id = "..forum_admin.person_id.." and identity_id = "..forum_admin.identity_id
		--ngx.log(ngx.ERR,"===="..#forum_admin.person_name.."****"..cjson.encode(forum_admin))
		--ngx.log(ngx.ERR,"ssssss1"..sql11)
		local result11, err = mysql:query(sql11)
		if result11 and #result11 > 0 then
			local sql22 = "update t_social_bbs_forum_user set flag = 1 where forum_id = "..forum_id.." and person_id = "..forum_admin.person_id.." and identity_id = "..forum_admin.identity_id
			--ngx.log(ngx.ERR,"ssssss2"..sql22)
			mysql:query(sql22)
		else
			local sql33 = "insert into t_social_bbs_forum_user(forum_id,person_id,identity_id,person_name,flag)values("..forum_id..","..forum_admin.person_id..","..forum_admin.identity_id..","..quote(forum_admin.person_name)..",1)"
			--ngx.log(ngx.ERR,"ssssss3"..sql33)
			mysql:query(sql33)
		end
	end

	--update ssdb
	ssdb:multi_hset("social_bbs_forum_"..forum_id, "name", name, "icon_url", icon_url, "description", description, "sequence", sequence, "forum_admin_list", cjson.encode(forum_admin_t))
else
	--insert mysql
	forum_id = ssdb:incr("social_bbs_forum_pk")[1]

	local isql = "insert into t_social_bbs_forum(id,bbs_id,partition_id,name,icon_url,description,sequence,last_post_time) values("..
	forum_id..","..bbs_id..","..partition_id..","..quote(name)..","..quote(icon_url)..","..quote(description)..","..sequence..",".."now()"..")"
	local iresutl, err = mysql:query(isql)
	if not iresutl then
    	say("{\"success\":false,\"info\":\""..err.."\"}")
   		return
	end

	--添加版主
	for i=1, #forum_admin_t do
		local forum_admin = forum_admin_t[i]
		local sql33 = "insert into t_social_bbs_forum_user(forum_id,person_id,identity_id,person_name,flag)values("..forum_id..","..forum_admin.person_id..","..forum_admin.identity_id..","..quote(forum_admin.person_name)..",1)"
		mysql:query(sql33)
	end

	--insert ssdb
	local forum = {}
	forum.id = forum_id
	forum.bbs_id = bbs_id
	forum.partition_id = partition_id
	forum.name = name
	forum.icon_url = icon_url
	forum.description = description
	forum.sequence = sequence
	forum.b_delete = 0
	forum.post_today = 0
	forum.post_yestoday = 0
	forum.total_topic = 0
	forum.total_post = 0
	forum.last_post_id = 0
	forum.forum_admin_list = cjson.encode(forum_admin_t)
	ssdb:multi_hset("social_bbs_forum_"..forum_id, forum)

	local fids_t, err = ssdb:hget("social_bbs_include_forum", "partition_id_"..partition_id)
	local fids = ""
	if fids_t and len(fids_t[1]) > 0 then
		fids = fids_t[1]..","..forum_id
	else
		fids = forum_id
	end
	ssdb:hset("social_bbs_include_forum", "partition_id_"..partition_id, fids)
end

--return
local rr = {}
rr.success = true
rr.forum_id = forum_id
rr.bbs_id = bbs_id
rr.partition_id = partition_id
rr.name = name
rr.icon_url = icon_url
rr.description = description
rr.sequence = sequence
rr.forum_admin_list = forum_admin_t
say(cjson.encode(rr))

--release
ssdb:set_keepalive(0,v_pool_size)
mysql:set_keepalive(0,v_pool_size)