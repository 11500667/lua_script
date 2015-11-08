--[[
前台接口Lua，根据联盟id、学段id、学科id、学校id、personId查询微课
@Author feiliming
@Date   2015-2-5
]]

local say = ngx.say
local len = string.len
local quote = ngx.quote_sql_str

--require model
local cjson = require "cjson"
local mysqllib = require "resty.mysql"
local redislib = require "resty.redis"

--get args
local league_id = ngx.var.arg_league_id
--
local stage_id = ngx.var.arg_stage_id
local subject_id = ngx.var.arg_subject_id
local school_id = ngx.var.arg_school_id
local person_id = ngx.var.arg_person_id
--
local pageSize = ngx.var.arg_pageSize
local pageNumber = ngx.var.arg_pageNumber
local order_type = ngx.var.arg_order_type

if not league_id or len(league_id) == 0 
    or not pageSize or len(pageSize) == 0 
    or not pageNumber or len(pageNumber) == 0
    or not order_type or len(order_type) == 0 then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end
pageSize = tonumber(pageSize)
pageNumber = tonumber(pageNumber)
local offset = pageSize*pageNumber-pageSize
local limit = pageSize

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

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--sql
local sphinxfilter = "filter=b_delete,0;filter=pub_target,"..league_id..";"
if stage_id and len(stage_id) > 0 then
	sphinxfilter = sphinxfilter.."filter=stage_id,"..stage_id..";"
end
if subject_id and len(subject_id) > 0 then
	sphinxfilter = sphinxfilter.."filter=subject_id,"..subject_id..";"
end
if school_id and len(school_id) > 0 then
	sphinxfilter = sphinxfilter.."filter=school_id,"..school_id..";"
end
if person_id and len(person_id) > 0 then
	sphinxfilter = sphinxfilter.."filter=person_id,"..person_id..";"
end
if order_type == "1" then
	sphinxfilter = sphinxfilter.."sort=attr_desc:ts;"
end
if order_type == "2" then
	sphinxfilter = sphinxfilter.."sort=attr_desc:play_count;"
end
sphinxfilter = sphinxfilter.."maxmatches=10000;offset="..offset..";limit="..limit

local sql = "SELECT SQL_NO_CACHE id FROM t_base_publish_wk_sphinxse WHERE QUERY='"..sphinxfilter.."';SHOW ENGINE SPHINX  STATUS;"
ngx.log(ngx.ERR, "==="..sql)
local ids = mysql:query(sql)

--去第二个结果集中的Status中截取总个数
local wkds1 = mysql:read_result()
local _,s_str = string.find(wkds1[1]["Status"],"found: ")
local e_str = string.find(wkds1[1]["Status"],", time:")
local totalRow = string.sub(wkds1[1]["Status"],s_str+1,e_str-1)
local totalPage = math.floor((totalRow+pageSize-1)/pageSize)

--redis
local redis = redislib:new()
local ok, err = redis:connect(v_redis_ip,v_redis_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local list = {}
for i=1,#ids do
	local obj_info_id = redis:hget("publish_"..ids[i].id, "obj_info_id")
	local wkds_value = redis:hmget("wkds_"..obj_info_id,"wkds_id_int","wkds_id_char","scheme_id","structure_id","wkds_name","study_instr","teacher_name","play_count","score_average","create_time","download_count","thumb_id","downloadable","person_id","table_pk","group_id","content_json")
	
	--thumb_id
	local  thumb_id = ""
	local content_json = wkds_value[17]
    local aa = ngx.decode_base64(content_json)
    local data = cjson.decode(aa)
    if #data.sp_list ~= 0 then
		local resource_info_id = data.sp_list[1].id
        if resource_info_id ~= ngx.null then
            local thumbid = ssdb_db:multi_hget("resource_"..resource_info_id, "thumb_id")
            if tostring(thumbid[2]) ~= "userdata: NULL" then
                thumb_id = thumbid[2]
            end
        end                            
    else
        thumb_id = "E6648460-4FFD-E626-1C14-6FBF9F94A23C"
    end
    if not thumb_id or len(thumb_id) == 0 then
		thumb_id = "E6648460-4FFD-E626-1C14-6FBF9F94A23C"
	end 

	local wk = {}
	wk.id = obj_info_id
	wk.wkds_id_int = wkds_value[1]
	wk.wkds_id_char = wkds_value[2]
	wk.scheme_id = wkds_value[3]
	wk.structure_id = wkds_value[4]
	wk.wkds_name = wkds_value[5]
	wk.study_instr = wkds_value[6]
	wk.teacher_name = wkds_value[7]
	wk.play_count = wkds_value[8]
	wk.score_average = wkds_value[9]
	wk.create_time = wkds_value[10]
	wk.download_count = wkds_value[11]
	wk.thumb_id = thumb_id
	wk.downloadable = wkds_value[13]
	wk.person_id = wkds_value[14]
	wk.table_pk = wkds_value[15]
	wk.group_id = wkds_value[16]
	wk.content_json = wkds_value[17]

	list[#list + 1] = wk
end

local rr = {}
rr.success = true
rr.totalRow = totalRow
rr.totalPage = totalPage
rr.pageNumber = pageNumber
rr.pageSize = pageSize
rr.list = list
cjson.encode_empty_table_as_object(false)
say(cjson.encode(rr))

mysql:set_keepalive(0,v_pool_size)
redis:set_keepalive(0,v_pool_size)
--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size);