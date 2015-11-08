--[[
迁移相册历史数据，至我的相册，别删除
]]

local say = ngx.say
local len = string.len
local quote = ngx.quote_sql_str

--require model
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"
local mysqllib = require "resty.mysql"

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

local gsql = "SELECT PERSON_ID,IDENTITY_ID FROM t_resource_info t "..
"WHERE t.`RES_TYPE` = 10 AND  t.`RESOURCE_TYPE` = 1 "..
"AND t.`BK_TYPE` > 999 "..
"GROUP BY t.PERSON_ID,t.IDENTITY_ID"
local gresutl, err = mysql:query(gsql)

if gresutl then
say("共有"..#gresutl.."个人需要导入到相册")
--say(cjson.encode(sresutl))

for i=1,#gresutl do
	local person_id = gresutl[i].PERSON_ID
	local identity_id = gresutl[i].IDENTITY_ID
	local folder_name = "我的相册"
	--insert
	local isql1 = "insert into t_social_gallery_folder(person_id, identity_id, folder_name, create_time, cover_picture_id, is_private, is_default) values ("..
	    person_id..","..identity_id..","..quote(folder_name)..",now(),-1,0,0)"
	local iresutl, err = mysql:query(isql1)
	if not iresutl then
	    ngx.log(ngx.ERR,"创建相册失败_"..person_id.."_"..identity_id)
	end
	local folder_id = iresutl.insert_id

	local ssql = "SELECT PERSON_ID,IDENTITY_ID,RESOURCE_FORMAT,FILE_ID,RESOURCE_TITLE FROM t_resource_info "..
	"WHERE RES_TYPE = 10 AND  RESOURCE_TYPE = 1 "..
	"AND BK_TYPE > 999 AND PERSON_ID = "..person_id.." AND IDENTITY_ID = "..identity_id
	local sresutl, err = mysql:query(ssql)

	if sresutl then
		say("这个人共有"..#sresutl.."条图片需要导入到相册</br>")
		for j=1,#sresutl do
			local extension = sresutl[j].RESOURCE_FORMAT
			local file_id = sresutl[j].FILE_ID
			local picture_name = sresutl[j].RESOURCE_TITLE

			--insert
			local isql2 = "insert into t_social_gallery_picture(person_id, identity_id, picture_name, create_time, folder_id, file_id) values ("..
			    quote(person_id)..","..quote(identity_id)..","..quote(picture_name)..",now(),"..quote(folder_id)..","..quote(file_id.."."..extension)..")"
			--ngx.log(ngx.ERR,"===="..isql2)
			local iresutl2, err = mysql:query(isql2)

			--照片数加1
			local usql = "UPDATE t_social_gallery_folder SET picture_num = picture_num + 1 WHERE id = "..quote(folder_id)
			local uresutl, err = mysql:query(usql)

		end
	end

end
end



