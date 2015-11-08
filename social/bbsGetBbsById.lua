--[[
获得论坛信息
@Author feiliming
@Date   2015-3-21
]]

local say = ngx.say
local len = string.len

--require model
local cjson = require "cjson"
local mysqllib = require "resty.mysql"

--get args
local bbs_id = ngx.var.arg_bbs_id

if not bbs_id or len(bbs_id) == 0 then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
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

--从mysql判断
local ssql = "select id,region_id,name,logo_url,icon_url,domain,status,social_type from t_social_bbs where id = "..bbs_id.." and social_type = 1"
local sresult, err = mysql:query(ssql)
if not sresult then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local bbs = {}
--opened
if sresult and #sresult > 0 then
	
	bbs = sresult[1]

	--partitioin
	local partitioin_list = {}
	local psql = "select id,bbs_id,name,sequence from t_social_bbs_partition where bbs_id = "..bbs.id.." and b_delete = 0 order by sequence"
	local presult, err = mysql:query(psql)
	if presult and #presult > 0 then
		for i=1, #presult do
			--forum
			local partitioin = presult[i]
			local fsql = "select id,bbs_id,partition_id,name,icon_url,description,sequence from t_social_bbs_forum where partition_id = "..partitioin.id.." and b_delete = 0 order by sequence"
			local fresult, err = mysql:query(fsql)
			local forum_list = {}
			if fresult and #fresult > 0 then
				for j=1, #fresult do

					local forum = fresult[j]
					--取版主
					local ssql2 = "select forum_id,person_id,identity_id,person_name from t_social_bbs_forum_user where forum_id = "..forum.id.." and flag = 1"
					local sresult2, err = mysql:query(ssql2)
					local forum_admin_list = {}
					if sresult2 and #sresult2 > 0 then
					    for i=1, #sresult2 do
					        forum_admin_list[#forum_admin_list + 1] = sresult2[i]
					    end
					end
					forum.forum_admin_list = forum_admin_list
					
					forum_list[#forum_list + 1] = forum
				end
			end
			partitioin.forum_list = forum_list

			partitioin_list[#partitioin_list + 1] = partitioin
		end
	end
	bbs.partitioin_list = partitioin_list

	local rr = {}
	rr.success = true
	rr.bbs = bbs
	cjson.encode_empty_table_as_object(false)
	say(cjson.encode(rr))
else
	local rr = {}
	rr.success = false
	rr.info = "未找到论坛!"
	say(cjson.encode(rr))
end

--release
--ssdb:set_keepalive(0,v_pool_size)
mysql:set_keepalive(0,v_pool_size)