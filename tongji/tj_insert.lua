local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local cookie_person_id = tostring(ngx.var.cookie_person_id)
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)

--获取市ID
local shi = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"shi")
--获取区ID
local qu = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"qu")
--获取校ID
local xiao = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"xiao")

--获取学段ID
if args["stage_id"] == nil or args["stage_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"stage_id参数错误！\"}")
    return
end
local stage_id = args["stage_id"]
--获取学科ID
if args["subject_id"] == nil or args["subject_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"subject_id参数错误！\"}")
    return
end
local subject_id = args["subject_id"]
--获取上传文件大小
if args["size"] == nil or args["size"] == "" then
    ngx.say("{\"success\":false,\"info\":\"size参数错误！\"}")
    return
end
local size = args["size"]
--获取上传的类型  1：资源  3：试卷  2：试题  4：备课   5：微课
if args["type_id"] == nil or args["type_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"type_id参数错误！\"}")
    return
end
local type_id = args["type_id"]
local type_name = ""
if type_id == "1" then
    type_name = "zy"
elseif view=="2" then
    type_name = "st"
elseif view=="3" then
    type_name = "sj"
elseif view=="4" then
    type_name = "bk"
else
    type_name = "wk  "
end
--获取媒体类型
if args["mtype"] == nil or args["mtype"] == "" then
    ngx.say("{\"success\":false,\"info\":\"mtype参数错误！\"}")
    return
end
local mtype = args["mtype"]

--连接SSDB
local ssdb = require "resty.ssdb"
local db = ssdb:new()
local ok, err = db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--只有资源和微课才存
if type_id == "1" or type_id == "5" then
    --管道开始
    db:init_pipeline()
    --*********保存市的信息************
    --tj_all_res_市ID_区ID_学段ID_学科ID (HASH)   每个单元格的资源个数和资源大小
    db:hincr("tj_shi_"..type_name.."_"..shi.."_"..qu.."_"..stage_id.."_"..subject_id,"resource_count")
    db:hincr("tj_shi_"..type_name.."_"..shi.."_"..qu.."_"..stage_id.."_"..subject_id,"resource_size",size)
    
    --tj_all_res_市ID_区ID_学段ID (HASH)	 每个区横向的合计
    db:hincr("tj_shi_"..type_name.."_"..shi.."_"..qu.."_"..stage_id,"resource_count")
    db:hincr("tj_shi_"..type_name.."_"..shi.."_"..qu.."_"..stage_id,"resource_size",size)
    
    --tj_all_res_市ID_学段ID_学科ID_zset (ZSET)	 按学科排序形成区的顺序
    db:zincr("tj_shi_"..type_name.."_"..shi.."_"..stage_id.."_"..subject_id.."_zset",qu)
    
    --tj_all_res_市ID_学段ID (ZSET)	横向合计的排序
    db:zincr("tj_shi_"..type_name.."_"..shi.."_"..stage_id,qu)
    
    --tj_all_res_市ID_学段ID_学科ID_hash (HASH)   最底下的合计
    db:hincr("tj_shi_"..type_name.."_"..shi.."_"..stage_id.."_"..subject_id.."_hash","resource_count")
    db:hincr("tj_shi_"..type_name.."_"..shi.."_"..stage_id.."_"..subject_id.."_hash","resource_size",size)
    
    
    --*********保存区的信息************
    --tj_qu_res_市ID_区ID_校ID_学段ID_学科ID (HASH)   每个单元格的资源个数和资源大小
    db:hincr("tj_qu_"..type_name.."_"..shi.."_"..qu.."_"..xiao.."_"..stage_id.."_"..subject_id,"resource_count")
    db:hincr("tj_qu_"..type_name.."_"..shi.."_"..qu.."_"..xiao.."_"..stage_id.."_"..subject_id,"resource_size",size)
    
    --tj_qu_res_市ID_区ID_校ID_学段ID (HASH)	 每个区横向的合计
    db:hincr("tj_qu_"..type_name.."_"..shi.."_"..qu.."_"..xiao.."_"..stage_id,"resource_count")
    db:hincr("tj_qu_"..type_name.."_"..shi.."_"..qu.."_"..xiao.."_"..stage_id,"resource_size",size)
    
    --tj_qu_res_市ID_区ID_学段ID_学科ID_zset (ZSET)	 按学科排序形成区的顺序
    db:zincr("tj_qu_"..type_name.."_"..shi.."_"..qu.."_"..stage_id.."_"..subject_id.."_zset",xiao)
    
    --tj_qu_res_市ID_区ID_学段ID (ZSET)	横向合计的排序
    db:zincr("tj_qu_"..type_name.."_"..shi.."_"..qu.."_"..stage_id,xiao)
    
    --tj_qu_res_市ID_区ID_学段ID_学科ID_hash (HASH)   最底下的合计
    db:hincr("tj_qu_"..type_name.."_"..shi.."_"..qu.."_"..stage_id.."_"..subject_id.."_hash","resource_count")
    db:hincr("tj_qu_"..type_name.."_"..shi.."_"..qu.."_"..stage_id.."_"..subject_id.."_hash","resource_size",size)
    
    
    --*********保存校的信息************
    --tj_xiao_res_市ID_区ID_校ID_学段ID_学科ID_类型ID (HASH)	每个单元格的资源个数和资源大小
    db:hincr("tj_xiao_"..type_name.."_"..shi.."_"..qu.."_"..xiao.."_"..stage_id.."_"..subject_id.."_"..mtype,"resource_count")
    db:hincr("tj_xiao_"..type_name.."_"..shi.."_"..qu.."_"..xiao.."_"..stage_id.."_"..subject_id.."_"..mtype,"resource_size",size)
    
    --tj_xiao_res_市ID_区ID_校ID_学段ID_学科ID (HASH)	每科横向的合计
    db:hincr("tj_xiao_"..type_name.."_"..shi.."_"..qu.."_"..xiao.."_"..stage_id.."_"..subject_id,"resource_count")
    db:hincr("tj_xiao_"..type_name.."_"..shi.."_"..qu.."_"..xiao.."_"..stage_id.."_"..subject_id,"resource_size",size)
    
    --tj_xiao_res_市ID_区ID_校ID_学段ID_类型ID_zset (ZSET)	按类型排序形成的学科顺序
    db:zincr("tj_xiao_"..type_name.."_"..shi.."_"..qu.."_"..xiao.."_"..stage_id.."_"..mtype.."_zset",subject_id)
    
    --tj_xiao_res_市ID_区ID_校ID_学段ID (ZSET)		横向合计的排序
    db:zincr("tj_xiao_"..type_name.."_"..shi.."_"..qu.."_"..xiao.."_"..stage_id,subject_id)
    
    --tj_xiao_res_市ID_区ID_校ID_学段ID_类型ID_hash (HASH)	最底下的合计
    db:hincr("tj_xiao_"..type_name.."_"..shi.."_"..qu.."_"..xiao.."_"..stage_id.."_"..mtype.."_hash","resource_count")
    db:hincr("tj_xiao_"..type_name.."_"..shi.."_"..qu.."_"..xiao.."_"..stage_id.."_"..mtype.."_hash","resource_size",size)
    
    local results, err = db:commit_pipeline()
    if not results then  
        ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
        return
    end
end

--云平台门户
db:init_pipeline()
--统计信息
db:hincr("tj_"..type_name.."_all","total_count")
db:hincr("tj_"..type_name.."_all","total_size",size)
--今日统计
local today = os.date("%Y%m%d")
db:hincr("tj_"..type_name.."_today".."_"..today,"upload_count")
--设置今日统计的过期时间
db:expire("tj_"..type_name.."_today".."_"..today,"172800")

--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--放回到SSDB连接池
db:set_keepalive(0,v_pool_size)