local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--资源的info_id
if args["info_id"] == nil or args["info_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"info_id参数错误！\"}")
    return
end
local info_id = args["info_id"]

--资源上传人
if args["person_id"] == nil or args["person_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
    return
end
local person_id = args["person_id"]

--系统类型  1:zy(资源)  2:wk(微课)  3:bk(备课)  4:sj(试卷)
if args["sys_type"] == nil or args["sys_type"] == "" then
    ngx.say("{\"success\":false,\"info\":\"sys_type参数错误！\"}")
    return
end
local sys_type = ""
if tostring(args["sys_type"]) == "1" then
	sys_type = "zy"
elseif tostring(args["sys_type"]) == "2" then
	sys_type = "wk"
elseif tostring(args["sys_type"]) == "3" then
	sys_type = "bk"
else
	sys_type = "sj"
end

--学段ID
if args["stage_id"] == nil or args["stage_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"stage_id参数错误！\"}")
    return
end
local stage_id = args["stage_id"]

--科目ID
if args["subject_id"] == nil or args["subject_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"subject_id参数错误！\"}")
    return
end
local subject_id = args["subject_id"]

local bureau_id = ngx.var.cookie_background_bureau_id

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--获取TS
local myts = require "resty.TS";
local ts =  myts.getTs();

ssdb_db:zset("tuijian_"..sys_type.."_"..bureau_id,info_id,ts)
ssdb_db:zset("tuijian_"..sys_type.."_"..bureau_id.."_"..stage_id,info_id,ts)
ssdb_db:zset("tuijian_"..sys_type.."_"..bureau_id.."_"..stage_id.."_"..subject_id,info_id,ts)

--再记一遍人员
ssdb_db:zset("tuijian_"..sys_type.."_"..bureau_id.."_"..person_id,info_id,ts)
ssdb_db:zset("tuijian_"..sys_type.."_"..bureau_id.."_"..stage_id.."_"..person_id,info_id,ts)
ssdb_db:zset("tuijian_"..sys_type.."_"..bureau_id.."_"..stage_id.."_"..subject_id.."_"..person_id,info_id,ts)

local result = {}
result["success"] = true
--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)

local cjson = require "cjson"
ngx.say(cjson.encode(result))
