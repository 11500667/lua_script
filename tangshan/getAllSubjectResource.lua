local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--一页显示多少
if args["pageSize"] == nil or args["pageSize"] == "" then
    ngx.say("{\"success\":\"false\",\"info\":\"pageSize参数错误！\"}")
    return
end
local pageSize = args["pageSize"]

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
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end

local cjson = require "cjson"

local stage_list = {"4","小学","5","初中","6","高中"}

local result = {}
local i_count = 1

for i=1,#stage_list,2 do
	local stage_subject = {}
	local subject_json = ""
	local resource_json = ""	
	local stage_id = stage_list[i]

	stage_subject["xd_id"] = stage_id
	stage_subject["xd_name"] = stage_list[i+1]
	subject_json = ngx.location.capture("/dsideal_yy/getSubjectByStage?stage_id="..stage_id)
	stage_subject["subject_list"] = cjson.decode(subject_json.body)
	resource_json = ngx.location.capture("/dsideal_yy/tangshan/getStageSubjectSortResourceInfo?stage_id="..stage_id.."&InOut=1&subject_id=-1&pageNumber=1&pageSize="..pageSize)
	stage_subject["data_list"] = cjson.decode(resource_json.body)
	result[i_count] = stage_subject
	i_count = i_count+1
end

local str = {}

str["success"] = true
str["list"] = result

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)

ngx.say(tostring(cjson.encode(str)))




