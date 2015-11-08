--[[
根据协作体ID获取协作体首页的信息[mysql版]
@Author  chenxg
@Date    2015-06-03
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"

--判断request类型, 获得请求参数
local request_method = ngx.var.request_method
local args,err
if request_method == "GET" then
    args,err = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args,err = ngx.req.get_post_args() 
end
if not args then 
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local returnjson = {}
--参数 
local xzt_id = args["xzt_id"]

--判断参数是否为空
if not xzt_id or string.len(xzt_id) == 0 
   then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

--创建ssdb连接
local ssdblib = require "resty.ssdb"
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
--连接mysql数据库
local mysql = require "resty.mysql"
local db = mysql:new()
db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024*1024
}

--根据协作体ID获取协作体信息开始
local xztinfo
local res_org = ngx.location.capture("/dsideal_yy/qyjhfz/getXztInfo?xzt_id="..xzt_id)

if res_org.status == 200 then
	xztinfo = (cjson.decode(res_org.body))
else
	say("{\"success\":false,\"info\":\"查询协作体信息失败！\"}")
	--return
end
--根据协作体ID获取协作体信息结束

--获取最新的活动开始 陈续刚2015-02-09添加
local hdlist
local params = "?page_type=3&hd_type=1&path_id="..xzt_id.."&pageSize=6&pageNumber=1"
local res_org = ngx.location.capture("/dsideal_yy/qyjhfz/getHdByParams"..params)

if res_org.status == 200 then
	hdlist = (cjson.decode(res_org.body))
else
	say("{\"success\":false,\"info\":\"获取活动信息失败！\"}")
	return
end
returnjson.hd_list = hdlist.hd_list
--获取最新的活动结束
--统计资源数量  and hd_id !=-1
local zy_sql = "select count(distinct obj_id_int) as zy_tj from t_base_publish where b_delete=0 and pub_type=3 and xzt_id="..xzt_id..""
local zy_result, err, errno, sqlstate = db:query(zy_sql);
if not zy_result then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	return;
end

returnjson.success = "true"
returnjson.js_tj = xztinfo.js_tj
returnjson.hd_tj = xztinfo.hd_tj
returnjson.zy_tj = zy_result[1]["zy_tj"]
returnjson.fzr_id = xztinfo.person_id
returnjson.fzr_name = xztinfo.person_name
returnjson.description = xztinfo.description
returnjson.name = xztinfo.name

say(cjson.encode(returnjson))
--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0,v_pool_size)