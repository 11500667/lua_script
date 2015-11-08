--[[
根据区域均衡ID获取区域均衡信息[mysql版]
@Author  chenxg
@Date    2015-06-01
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

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
--参数 
local region_id = args["region_id"]


--判断参数是否为空
if not region_id or string.len(region_id) == 0 
   then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

--创建ssdb连接
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

--获取详细信息
local sql = "SELECT qyjh_id,name,description,logo_url,createtime,province_id,city_id,district_id, b_use,b_open FROM T_QYJH_QYJHS O WHERE qyjh_id = "..region_id..";";
local results, err, errno, sqlstate = db:query(sql);
if not results then
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}");
	return;
end
local qyjh_id = results[1]["qyjh_id"]
local name = results[1]["name"]
local description = results[1]["description"]
local logo_url = results[1]["logo_url"]
local createtime = results[1]["createtime"]
local province_id = results[1]["province_id"]
local city_id = results[1]["city_id"]
local district_id = results[1]["district_id"]
local b_use = results[1]["b_use"]
local b_open = results[1]["b_open"]
local temp = {}
temp.qyjh_id = qyjh_id
temp.name = name
temp.description = description
temp.logo_url = logo_url
temp.createtime = createtime
temp.province_id = province_id
temp.city_id = city_id
temp.district_id = district_id
temp.b_use = b_use
temp.b_open = b_open
--temp.success=true
temp.success = "true"

say(cjson.encode(temp))

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0,v_pool_size)