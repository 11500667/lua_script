local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

local person_id = tostring(ngx.var.cookie_person_id)

--a_type  1：上传		2：收藏		3：共享		4：推荐
if args["a_type"] == nil or args["a_type"] == "" then
	ngx.print("{\"success\":false,\"info\":\"a_type参数错误！\"}")
	return
end
local a_type = args["a_type"]

--s_type 系统ID 1：资源	2：试题		3：试卷		4：备课		5：微课
if args["s_type"] == nil or args["s_type"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"s_type参数错误！\"}")
	return
end
local s_type = args["s_type"]

--r_type 资源类型
if args["r_type"] == nil or args["r_type"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"r_type参数错误！\"}")
	return
end
local r_type = args["r_type"]

--subject_id科目
if args["subject_id"] == nil or args["subject_id"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"subject_id参数错误！\"}")
	return
end
local subject_id = args["subject_id"]

--记录个数
if args["count"] == nil or args["count"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"count参数错误！\"}")
	return
end
local count = args["count"]

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.print("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local a_type_name = ""
if a_type == "1" then
	a_type_name = "shangchuanCount"
elseif a_type == "2" then
	a_type_name = "shoucangCount"
elseif a_type == "3" then
	a_type_name = "gongxiangCount"
elseif  a_type == "4" then
	a_type_name = "tuijianCount"
else
	a_type_name = "pinglunCount"
end

ssdb_db:hincr("tj_person_"..subject_id.."_"..s_type.."_"..r_type.."_"..person_id,a_type_name,count)
ssdb_db:hincr("tj_person_"..subject_id.."_"..s_type.."_"..person_id,a_type_name,count)

--放回到SSDB连接池
ssdb_db:set_keepalive(0,v_pool_size)

ngx.print("{\"success\":true}")
