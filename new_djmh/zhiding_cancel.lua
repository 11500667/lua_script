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

--系统类型  1:zy  2:wk
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

-- 判断参数中是否包含地址，如果有，则从参数中获取，如果没有，则从cookie中获取（因为前台从cookie中获取不到此值，所以需要传递参数）
local bureau_id = "";
if args["bureau_id"] ~= nil and args["bureau_id"] ~= "" then
    bureau_id = args["bureau_id"];
else
    bureau_id = ngx.var.cookie_background_bureau_id;
end

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--连接redis服务器
local redis = require "resty.redis"
local redis_db = redis:new()
local ok,err = redis_db:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
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

local  update_ts = math.random(1000000)..os.time()
redis_db:set("tuijian_ts_"..bureau_id,update_ts)
redis_db:del("tuijian_"..sys_type.."_ts_"..bureau_id);

-- 申健 2015-08-26 将推荐数据维护到mysql数据库中 
local recommendModel = require "multi_check.model.Recommend";
local paramTable = {};
paramTable["obj_type"]    = recommendModel: getObjType(sys_type);
ngx.log(ngx.ERR, "[sj_log] -> objType: [", paramTable["obj_type"], "]");
paramTable["obj_info_id"] = info_id;
paramTable["unit_id"]     = bureau_id;
paramTable["sort_ts"]     = ts;
paramTable["b_top"]       = 0; -- 0未置顶， 1已置顶
recommendModel: updateRecommend(paramTable);
-- 申健 2015-08-26 将推荐数据维护到mysql数据库中 

local result = {}
result["success"] = true

ssdb_db:set_keepalive(0,v_pool_size)
redis_db:set_keepalive(0,v_pool_size)

local cjson = require "cjson"
ngx.say(cjson.encode(result))
