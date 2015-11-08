ngx.header.content_type = "text/plain;charset=utf-8"
local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)

ngx.req.read_body()
local args = ngx.req.get_post_args()
local stage_id = tostring(args["stage_id"])
--判断是否有stage_id参数
if stage_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"没有stage_id参数！\"}")
    return
end

local subject_id = tostring(args["subject_id"])
--判断是否有subject_id参数
if subject_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"没有subject_id参数！\"}")
    return
end

local stage_name = tostring(args["stage_name"])
--判断是否有stage_name参数
if stage_name == "nil" then
    ngx.say("{\"success\":false,\"info\":\"没有stage_name参数！\"}")
    return
end

local subject_name = tostring(args["subject_name"])
--判断是否有subject_name参数
if subject_name == "nil" then
    ngx.say("{\"success\":false,\"info\":\"没有subject_name参数！\"}")
    return
end

local json_str = tostring(args["json_str"])
--判断是否有json_str参数
if json_str == "nil" then
    ngx.say("{\"success\":false,\"info\":\"没有json_str参数！\"}")
    return
end

local paper_name = tostring(args["paper_name"])
--判断是否有paper_name参数
if paper_name == "nil" then
    ngx.say("{\"success\":false,\"info\":\"没有paper_name参数！\"}")
    return
end

local ti_count = tostring(args["ti_count"])
--判断是否有ti_count参数
if ti_count == "nil" then
    ngx.say("{\"success\":false,\"info\":\"没有ti_count参数！\"}")
    return
end

local paper_id = tostring(args["paper_id"])
--判断是否有paper_id参数
if paper_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"没有paper_id参数！\"}")
    return
end

local insert_update = tostring(args["insert_update"])
--判断是否有insert_update参数
if insert_update == "nil" then
    ngx.say("{\"success\":false,\"info\":\"没有insert_update参数！\"}")
    return
end

stage_name = ngx.decode_base64(stage_name)
subject_name = ngx.decode_base64(subject_name)
--json_str = ngx.decode_base64(json_str)
paper_name= ngx.decode_base64(paper_name)

local ctime = tostring(os.date("%Y-%m-%d %H:%M:%S"))

--连接redis服务器
local redis = require "resty.redis"
local cache = redis.new()
local ok,err = cache.connect(cache,v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

--local paper_list = "{\"paper_id\":\""..paper_id.."\",\"paper_name\":\""..paper_name.."\",\"stage_id\":\""..stage_id.."\",\"subject_id\":\""..subject_id.."\",\"stage_name\":\""..stage_name.."\",\"subject_name\":\""..subject_name.."\",\"ti_num\":\""..ti_count.."\",\"create_time\":\""..ctime.."\"}"



--时间截
local ts = tostring(ngx.now()*1000)
if insert_update=="1" then
    cache:zadd("paperlist_"..cookie_person_id,ts,paper_id)
end

cache:hmset("paperinfo_"..paper_id,"paper_id",paper_id,"paper_name",paper_name,"stage_id",stage_id,"stage_name",stage_name,"subject_id",subject_id,"subject_name",subject_name,"person_id",cookie_person_id,"identity_id",cookie_identity_id,"question_count",ti_count,"json_content",json_str,"create_time",ctime,"update_time",ctime)

local str = "{\"action\":\"sp_add_paper\",\"need_newcache\":\"0\",\"paras\":{\"p_paper_id\":\""..paper_id.."\",\"p_paper_name\":\""..paper_name.."\",\"p_stage_id\":\""..stage_id.."\",\"p_subject_id\":\""..subject_id.."\",\"p_stage_name\":\""..stage_name.."\",\"p_subject_name\":\""..subject_name.."\",\"p_question_count\":\""..ti_count.."\",\"p_json_content\":\""..json_str.."\",\"p_create_time\":\""..ctime.."\",\"p_person_id\":\""..cookie_person_id.."\",\"p_identity_id\":\""..cookie_identity_id.."\",\"p_update_time\":\""..ctime.."\",\"p_insert_update\":\""..insert_update.."\"}}"

cache:lpush("async_write_list",str)

ngx.say("{\"success\":true}")

