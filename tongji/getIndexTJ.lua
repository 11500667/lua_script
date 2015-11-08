ngx.header.content_type = "text/plain;charset=utf-8"
--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
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
--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end


local cjson = require "cjson"
local res = ""
local today = os.date("%Y%m%d")
local all = {}

--获取资源的统计信息
local zy = {}
local zy_tj_info = ssdb_db:multi_hget("tj_zy_all","total_count","total_size","view_count","down_count","comment_count")
local zy_tj_info_tab = {total_count="0",total_size="0",view_count="0",down_count="0",comment_count="0",subject_count="30"}
for i=1,#zy_tj_info,2 do
    zy_tj_info_tab[zy_tj_info[i]]=zy_tj_info[i+1]
end
zy["tj_info"] = zy_tj_info_tab

--获取资源的今日统计
local zy_tj_today = ssdb_db:multi_hget("tj_zy_today_"..today,"view_count","upload_count","down_count")
local zy_tj_today_tab = {view_count="0",upload_count="0",down_count="0"}
for i=1,#zy_tj_today,2 do
    zy_tj_today_tab[zy_tj_today[i]]=zy_tj_today[i+1]
end
zy["tj_today"] = zy_tj_today_tab


--获取资源的最热资源
local zy_tj_hot_all_tab = {}
res = mysql_db:query("SELECT SQL_NO_CACHE id FROM t_resource_info_sphinxse where query='filter=group_id,1;filter=res_type,1;filter=release_status,1,3;groupby=attr:resource_id_int;groupsort=down_count desc;limit=8'")

for i=1,#res do    
    --local zy_tj_hot = cache:hmget("resource_"..res[i]["id"],"resource_title","resource_format","resource_page","file_id","thumb_id","preview_status","width","height","for_urlencoder_url","for_iso_url","down_count","scheme_id_int","resource_id_int")
	local zy_tj_hot = ssdb_db:multi_hget("resource_"..res[i]["id"],"resource_title","resource_format","resource_page","file_id","thumb_id","preview_status","width","height","for_urlencoder_url","for_iso_url","down_count","scheme_id_int","resource_id_int")
    --根据版本ID获取该版本属于哪个学科    
    local subject_name = ssdb_db:hget("t_resource_scheme_"..zy_tj_hot[24],"subject_name")[1]    
    local zy_tj_hot_tab = {}
    zy_tj_hot_tab["resource_title"] = zy_tj_hot[2]
    zy_tj_hot_tab["resource_format"] = zy_tj_hot[4]
    zy_tj_hot_tab["resource_page"] = zy_tj_hot[6]
    zy_tj_hot_tab["file_id"] = zy_tj_hot[8]
    zy_tj_hot_tab["thumb_id"] = zy_tj_hot[10]
    zy_tj_hot_tab["preview_status"] = zy_tj_hot[12]
    zy_tj_hot_tab["width"] = zy_tj_hot[14]
    zy_tj_hot_tab["height"] = zy_tj_hot[16]
    zy_tj_hot_tab["for_urlencoder_url"] = zy_tj_hot[18]
    zy_tj_hot_tab["for_iso_url"] = zy_tj_hot[20]
    zy_tj_hot_tab["browse_count"] = zy_tj_hot[22]
    zy_tj_hot_tab["resource_id_int"] = zy_tj_hot[26]
    zy_tj_hot_tab["subject"] = subject_name
    zy_tj_hot_all_tab[i] = zy_tj_hot_tab    
end
zy["tj_hot"] = zy_tj_hot_all_tab


--获取资源的最新资源
local zy_tj_new_all_tab = {}
res = mysql_db:query("SELECT SQL_NO_CACHE id FROM t_resource_info_sphinxse where query='filter=group_id,1;filter=res_type,1;filter=release_status,1,3;groupby=attr:file_id;groupsort=ts desc;limit=8'")


for i=1,#res do    
    --local zy_tj_new = cache:hmget("resource_"..res[i]["id"],"resource_title","resource_format","resource_page","file_id","thumb_id","preview_status","width","height","for_urlencoder_url","for_iso_url","down_count","scheme_id_int","resource_id_int")
	local zy_tj_new = ssdb_db:multi_hget("resource_"..res[i]["id"],"resource_title","resource_format","resource_page","file_id","thumb_id","preview_status","width","height","for_urlencoder_url","for_iso_url","down_count","scheme_id_int","resource_id_int")
    --根据版本ID获取该版本属于哪个学科    
    local subject_name = ssdb_db:hget("t_resource_scheme_"..zy_tj_new[12],"subject_name")[1]    
    local zy_tj_new_tab = {}
    zy_tj_new_tab["resource_title"] = zy_tj_new[2]
    zy_tj_new_tab["resource_format"] = zy_tj_new[4]
    zy_tj_new_tab["resource_page"] = zy_tj_new[6]
    zy_tj_new_tab["file_id"] = zy_tj_new[8]
    zy_tj_new_tab["thumb_id"] = zy_tj_new[10]
    zy_tj_new_tab["preview_status"] = zy_tj_new[12]
    zy_tj_new_tab["width"] = zy_tj_new[14]
    zy_tj_new_tab["height"] = zy_tj_new[16]
    zy_tj_new_tab["for_urlencoder_url"] = zy_tj_new[18]
    zy_tj_new_tab["for_iso_url"] = zy_tj_new[20]
    zy_tj_new_tab["browse_count"] = zy_tj_new[22]
    zy_tj_new_tab["resource_id_int"] = zy_tj_new[26]
    zy_tj_new_tab["subject"] = subject_name
    zy_tj_new_all_tab[i] = zy_tj_new_tab    
end
zy["tj_new"] = zy_tj_new_all_tab


--获取试卷的统计信息
local sj = {}
local sj_tj_info = ssdb_db:multi_hget("tj_sj_all","total_count","total_size","view_count","down_count","comment_count")
local sj_tj_info_tab = {total_count="0",total_size="0",view_count="0",down_count="0",comment_count="0",subject_count="30"}
for i=1,#sj_tj_info,2 do
    sj_tj_info_tab[sj_tj_info[i]]=sj_tj_info[i+1]
end
sj["tj_info"] = sj_tj_info_tab

--获取试卷的今日统计
local sj_tj_today = ssdb_db:multi_hget("tj_sj_today_"..today,"view_count","upload_count","down_count")
local sj_tj_today_tab = {view_count="0",upload_count="0",down_count="0"}
for i=1,#sj_tj_today,2 do
    sj_tj_today_tab[sj_tj_today[i]]=sj_tj_today[i+1]
end
sj["tj_today"] = sj_tj_today_tab

--获取试卷的最热资源
local sj_tj_hot_all_tab = {}
res = mysql_db:query("SELECT SQL_NO_CACHE id FROM t_resource_info_sphinxse where query='filter=group_id,1;filter=res_type,4;filter=release_status,1,3;groupby=attr:file_id;groupsort=down_count desc;limit=8'")
for i=1,#res do    
    --local sj_tj_hot = cache:hmget("resource_"..res[i]["id"],"resource_title","resource_format","resource_page","file_id","thumb_id","preview_status","width","height","for_urlencoder_url","for_iso_url","down_count","scheme_id_int")
	local sj_tj_hot = ssdb_db:multi_hget("resource_"..res[i]["id"],"resource_title","resource_format","resource_page","file_id","thumb_id","preview_status","width","height","for_urlencoder_url","for_iso_url","down_count","scheme_id_int")	
    --根据版本ID获取该版本属于哪个学科    
    local subject_name = ssdb_db:hget("t_resource_scheme_"..sj_tj_hot[24],"subject_name")[1]    
    local sj_tj_hot_tab = {}
    sj_tj_hot_tab["resource_title"] = sj_tj_hot[2]
    sj_tj_hot_tab["resource_format"] = sj_tj_hot[4]
    sj_tj_hot_tab["resource_page"] = sj_tj_hot[6]
    sj_tj_hot_tab["file_id"] = sj_tj_hot[8]
    sj_tj_hot_tab["thumb_id"] = sj_tj_hot[10]
    sj_tj_hot_tab["preview_status"] = sj_tj_hot[12]
    sj_tj_hot_tab["width"] = sj_tj_hot[14]
    sj_tj_hot_tab["height"] = sj_tj_hot[16]
    sj_tj_hot_tab["for_urlencoder_url"] = sj_tj_hot[18]
    sj_tj_hot_tab["for_iso_url"] = sj_tj_hot[20]
    sj_tj_hot_tab["browse_count"] = sj_tj_hot[22]
    sj_tj_hot_tab["subject"] = subject_name
    sj_tj_hot_all_tab[i] = sj_tj_hot_tab    
end
sj["tj_hot"] = sj_tj_hot_all_tab

--获取试卷的最新资源
local sj_tj_new_all_tab = {}
res = mysql_db:query("SELECT SQL_NO_CACHE id FROM t_resource_info_sphinxse where query='filter=group_id,1;filter=res_type,4;filter=release_status,1,3;groupby=attr:file_id;groupsort=ts desc;limit=8'")
for i=1,#res do    
    --local sj_tj_new = cache:hmget("resource_"..res[i]["id"],"resource_title","resource_format","resource_page","file_id","thumb_id","preview_status","width","height","for_urlencoder_url","for_iso_url","down_count","scheme_id_int")
	local sj_tj_new = ssdb_db:multi_hget("resource_"..res[i]["id"],"resource_title","resource_format","resource_page","file_id","thumb_id","preview_status","width","height","for_urlencoder_url","for_iso_url","down_count","scheme_id_int")
    --根据版本ID获取该版本属于哪个学科    
    local subject_name = ssdb_db:hget("t_resource_scheme_"..sj_tj_new[24],"subject_name")[1]    
    local sj_tj_new_tab = {}
    sj_tj_new_tab["resource_title"] = sj_tj_new[2]
    sj_tj_new_tab["resource_format"] = sj_tj_new[4]
    sj_tj_new_tab["resource_page"] = sj_tj_new[6]
    sj_tj_new_tab["file_id"] = sj_tj_new[8]
    sj_tj_new_tab["thumb_id"] = sj_tj_new[10]
    sj_tj_new_tab["preview_status"] = sj_tj_new[12]
    sj_tj_new_tab["width"] = sj_tj_new[14]
    sj_tj_new_tab["height"] = sj_tj_new[16]
    sj_tj_new_tab["for_urlencoder_url"] = sj_tj_new[18]
    sj_tj_new_tab["for_iso_url"] = sj_tj_new[20]
    sj_tj_new_tab["browse_count"] = sj_tj_new[22]
    sj_tj_new_tab["subject"] = subject_name
    sj_tj_new_all_tab[i] = sj_tj_new_tab    
end
sj["tj_new"] = sj_tj_new_all_tab


--获取试题的统计信息
local st = {}
local st_tj_info = ssdb_db:multi_hget("tj_st_all","total_count","total_size","view_count","down_count","comment_count")
local st_tj_info_tab = {total_count="0",total_size="0",view_count="0",down_count="0",comment_count="0",subject_count="30"}
for i=1,#st_tj_info,2 do
    st_tj_info_tab[st_tj_info[i]]=st_tj_info[i+1]
end
st["tj_info"] = st_tj_info_tab

--获取试题的今日统计
local st_tj_today = ssdb_db:multi_hget("tj_st_today_"..today,"view_count","upload_count","down_count")
local st_tj_today_tab = {view_count="0",upload_count="0",down_count="0"}
for i=1,#st_tj_today,2 do
    st_tj_today_tab[st_tj_today[i]]=st_tj_today[i+1]
end
st["tj_today"] = st_tj_today_tab

--获取试题的最热资源
local st_tj_hot_all_tab = {}
res = mysql_db:query("SELECT SQL_NO_CACHE id FROM t_tk_question_info_sphinxse where query='filter=group_id,1;groupby=attr:question_id_char;groupsort=use_count desc;limit=5'")
for i=1,#res do    
    local st_tj_hot = cache:hmget("question_"..res[i]["id"],"json_question","scheme_id_int")
    --根据版本ID获取该版本属于哪个学科    
    local subject_name = ssdb_db:hget("t_resource_scheme_"..st_tj_hot[2],"subject_name")[1]    
    local st_tj_hot_tab = {}    
    st_tj_hot_tab["subject"] = subject_name
    --获取题的json从中获取file_id
    local question_encode = st_tj_hot[1]
    local question_str = ngx.decode_base64(question_encode)
    local question_json = cjson.decode(question_str)    
    st_tj_hot_tab["file_id"] = question_json["t_id"]
    st_tj_hot_all_tab[i] = st_tj_hot_tab    
end
st["tj_hot"] = st_tj_hot_all_tab

--获取试题的最新资源
local st_tj_new_all_tab = {}
res = mysql_db:query("SELECT SQL_NO_CACHE id FROM t_tk_question_info_sphinxse where query='filter=group_id,1;groupby=attr:question_id_char;groupsort=ts desc;limit=5'")
for i=1,#res do    
    local st_tj_new = cache:hmget("question_"..res[i]["id"],"json_question","scheme_id_int")
    --根据版本ID获取该版本属于哪个学科    
    local subject_name = ssdb_db:hget("t_resource_scheme_"..st_tj_new[2],"subject_name")[1]    
    local st_tj_new_tab = {}    
    st_tj_new_tab["subject"] = subject_name
    --获取题的json从中获取file_id
    local question_encode = st_tj_new[1]
    local question_str = ngx.decode_base64(question_encode)
    local question_json = cjson.decode(question_str)    
    st_tj_new_tab["file_id"] = question_json["t_id"]    
    st_tj_new_all_tab[i] = st_tj_new_tab    
end
st["tj_new"] = st_tj_new_all_tab


--获取备课的统计信息
local bk = {}
local bk_tj_info = ssdb_db:multi_hget("tj_bk_all","total_count","total_size","view_count","down_count","comment_count")
local bk_tj_info_tab = {total_count="0",total_size="0",view_count="0",down_count="0",comment_count="0",subject_count="30"}
for i=1,#bk_tj_info,2 do
    bk_tj_info_tab[bk_tj_info[i]]=bk_tj_info[i+1]
end
bk["tj_info"] = bk_tj_info_tab

--获取备课的今日统计
local bk_tj_today = ssdb_db:multi_hget("tj_bk_today_"..today,"view_count","upload_count","down_count")
local bk_tj_today_tab = {view_count="0",upload_count="0",down_count="0"}
for i=1,#bk_tj_today,2 do
    bk_tj_today_tab[bk_tj_today[i]]=bk_tj_today[i+1]
end
bk["tj_today"] = bk_tj_today_tab

--获取备课的最热资源
local bk_tj_hot_all_tab = {}
res = mysql_db:query("SELECT SQL_NO_CACHE id FROM t_resource_info_sphinxse where query='filter=group_id,1;filter=res_type,2;!filter=bk_type,1;filter=release_status,1,3;sort=attr_desc:down_count;limit=8'")
for i=1,#res do    
    --local bk_tj_hot = cache:hmget("resource_"..res[i]["id"],"resource_title","resource_format","resource_page","file_id","thumb_id","preview_status","width","height","for_urlencoder_url","for_iso_url","down_count","scheme_id_int","resource_id_int")
	local bk_tj_hot = ssdb_db:multi_hget("resource_"..res[i]["id"],"resource_title","resource_format","resource_page","file_id","thumb_id","preview_status","width","height","for_urlencoder_url","for_iso_url","down_count","scheme_id_int","resource_id_int")
    --根据版本ID获取该版本属于哪个学科    
    local subject_name = ssdb_db:hget("t_resource_scheme_"..bk_tj_hot[24],"subject_name")[1]    
    local bk_tj_hot_tab = {}
    bk_tj_hot_tab["resource_title"] = bk_tj_hot[2]
    bk_tj_hot_tab["resource_format"] = bk_tj_hot[4]
    bk_tj_hot_tab["resource_page"] = bk_tj_hot[6]
    bk_tj_hot_tab["file_id"] = bk_tj_hot[8]
    bk_tj_hot_tab["thumb_id"] = bk_tj_hot[10]
    bk_tj_hot_tab["preview_status"] = bk_tj_hot[12]
    bk_tj_hot_tab["width"] = bk_tj_hot[14]
    bk_tj_hot_tab["height"] = bk_tj_hot[16]
    bk_tj_hot_tab["for_urlencoder_url"] = bk_tj_hot[18]
    bk_tj_hot_tab["for_iso_url"] = bk_tj_hot[20]
    bk_tj_hot_tab["browse_count"] = bk_tj_hot[22]
    bk_tj_hot_tab["resource_id_int"] = bk_tj_hot[26]    
    bk_tj_hot_tab["subject"] = subject_name
    bk_tj_hot_all_tab[i] = bk_tj_hot_tab    
end
bk["tj_hot"] = bk_tj_hot_all_tab

--获取备课的最新资源
local bk_tj_new_all_tab = {}
res = mysql_db:query("SELECT SQL_NO_CACHE id FROM t_resource_info_sphinxse where query='filter=group_id,1;filter=res_type,2;!filter=bk_type,1;filter=release_status,1,3;sort=attr_desc:ts;limit=8'")
for i=1,#res do    
    --local bk_tj_new = cache:hmget("resource_"..res[i]["id"],"resource_title","resource_format","resource_page","file_id","thumb_id","preview_status","width","height","for_urlencoder_url","for_iso_url","down_count","scheme_id_int","resource_id_int")
	local bk_tj_new = ssdb_db:multi_hget("resource_"..res[i]["id"],"resource_title","resource_format","resource_page","file_id","thumb_id","preview_status","width","height","for_urlencoder_url","for_iso_url","down_count","scheme_id_int","resource_id_int")
    --根据版本ID获取该版本属于哪个学科    
    local subject_name = ssdb_db:hget("t_resource_scheme_"..bk_tj_new[24],"subject_name")[1]    
    local bk_tj_new_tab = {}
    bk_tj_new_tab["resource_title"] = bk_tj_new[2]
    bk_tj_new_tab["resource_format"] = bk_tj_new[4]
    bk_tj_new_tab["resource_page"] = bk_tj_new[6]
    bk_tj_new_tab["file_id"] = bk_tj_new[8]
    bk_tj_new_tab["thumb_id"] = bk_tj_new[10]
    bk_tj_new_tab["preview_status"] = bk_tj_new[12]
    bk_tj_new_tab["width"] = bk_tj_new[14]
    bk_tj_new_tab["height"] = bk_tj_new[16]
    bk_tj_new_tab["for_urlencoder_url"] = bk_tj_new[18]
    bk_tj_new_tab["for_iso_url"] = bk_tj_new[20]
    bk_tj_new_tab["browse_count"] = bk_tj_new[22]
    bk_tj_new_tab["resource_id_int"] = bk_tj_new[26]
    bk_tj_new_tab["subject"] = subject_name
    bk_tj_new_all_tab[i] = bk_tj_new_tab    
end
bk["tj_new"] = bk_tj_new_all_tab

--获取微课的统计信息
local wk = {}
local wk_tj_info = ssdb_db:multi_hget("tj_wk_all","total_count","total_size","view_count","down_count","comment_count")
local wk_tj_info_tab = {total_count="0",total_size="0",view_count="0",down_count="0",comment_count="0",subject_count="30"}
for i=1,#wk_tj_info,2 do
    wk_tj_info_tab[wk_tj_info[i]]=wk_tj_info[i+1]
end
wk["tj_info"] = wk_tj_info_tab

--获取微课的今日统计
local wkj_tj_today = ssdb_db:multi_hget("tj_wk_today_"..today,"view_count","upload_count","down_count")
local wk_tj_today_tab = {view_count="0",upload_count="0",down_count="0"}
for i=1,#wkj_tj_today,2 do
    wk_tj_today_tab[wkj_tj_today[i]]=wkj_tj_today[i+1]
end
wk["tj_today"] = wk_tj_today_tab

--获取微课的最热资源
local wk_tj_hot_all_tab = {}
res = mysql_db:query("SELECT SQL_NO_CACHE id FROM t_wkds_info_sphinxse where query='filter=b_delete,0;filter=isdraft,0;filter=check_status,0,1;groupby=attr:wkds_id_int;groupsort=play_count desc;limit=8'")
for i=1,#res do
    local wk_tj_hot = cache:hmget("wkds_"..res[i]["id"],"wkds_id_int","play_count","content_json","wkds_name","scheme_id")
	local subject_name = ssdb_db:hget("t_resource_scheme_"..wk_tj_hot[5],"subject_name")[1]
    local wk_tj_hot_tab = {}
    wk_tj_hot_tab["id"] = tostring(res[i]["id"])
    wk_tj_hot_tab["wkds_id_int"] = wk_tj_hot[1]
    wk_tj_hot_tab["play_count"] = wk_tj_hot[2]
    wk_tj_hot_tab["wkds_name"] = wk_tj_hot[4]
	wk_tj_hot_tab["subject"] = subject_name
    --获取微课的缩略图
    local wk_thumb_id = ""
    local content_encode = wk_tj_hot[3]
    local content_str = ngx.decode_base64(content_encode)
    local content_json = cjson.decode(content_str)
    if #content_json.sp_list ~=0 then
    	local resource_info_id = content_json.sp_list[1].id
    	if resource_info_id ~= ngx.null then
    	    --wk_thumb_id = cache:hget("resource_"..resource_info_id,"thumb_id")
			wk_thumb_id = ssdb_db:hget("resource_"..resource_info_id,"thumb_id")[1]
    	end
    else
    	wk_thumb_id = "E6648460-4FFD-E626-1C14-6FBF9F94A23C"
    end
    wk_tj_hot_tab["thumb_id"] = wk_thumb_id
    wk_tj_hot_all_tab[i] = wk_tj_hot_tab
end
wk["tj_hot"] = wk_tj_hot_all_tab

--获取微课的最新资源
local wk_tj_new_all_tab = {}
res = mysql_db:query("SELECT SQL_NO_CACHE id FROM t_wkds_info_sphinxse where query='filter=b_delete,0;filter=isdraft,0;filter=check_status,0,1;groupby=attr:wkds_id_int;groupsort=ts desc;limit=8'")
for i=1,#res do
    local wk_tj_new = cache:hmget("wkds_"..res[i]["id"],"wkds_id_int","play_count","content_json","wkds_name","scheme_id")
	local subject_name = ssdb_db:hget("t_resource_scheme_"..wk_tj_new[5],"subject_name")[1]
    local wk_tj_new_tab = {}
    wk_tj_new_tab["id"] = tostring(res[i]["id"])
    wk_tj_new_tab["wkds_id_int"] = wk_tj_new[1]
    wk_tj_new_tab["play_count"] = wk_tj_new[2]
    wk_tj_new_tab["wkds_name"] = wk_tj_new[4]
	wk_tj_new_tab["subject"] = subject_name
    --获取微课的缩略图
    local wk_thumb_id = ""
    local content_encode = wk_tj_new[3]
    local content_str = ngx.decode_base64(content_encode)
    local content_json = cjson.decode(content_str)
    if #content_json.sp_list ~=0 then
    	local resource_info_id = content_json.sp_list[1].id
    	if resource_info_id ~= ngx.null then
    	    --wk_thumb_id = cache:hget("resource_"..resource_info_id,"thumb_id")
			wk_thumb_id = ssdb_db:hget("resource_"..resource_info_id,"thumb_id")[1]
    	end
    else
    	wk_thumb_id = "E6648460-4FFD-E626-1C14-6FBF9F94A23C"
    end
    wk_tj_new_tab["thumb_id"] = wk_thumb_id
    wk_tj_new_all_tab[i] = wk_tj_new_tab
end
wk["tj_new"] = wk_tj_new_all_tab

--将资源、试卷、备课、微课放到总table中
all["zy"]=zy
all["sj"]=sj
all["st"]=st
all["bk"]=bk
all["wk"]=wk

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
mysql_db:set_keepalive(0,v_pool_size)

cjson.encode_empty_table_as_object(false)
ngx.say(tostring(cjson.encode(all)))
