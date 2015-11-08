--[[
区域均衡相关统计
@Author  chenxg
@Date    2015-03-17
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
cjson.encode_empty_table_as_object(false);

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
--区域均衡ID
local qyjh_id = args["qyjh_id"]
--当前用户
local person_id = args["person_id"]
local keyword = args["keyword"]
local pageSize = ngx.var.arg_pageSize
local pageNumber = ngx.var.arg_pageNumber



--判断参数是否为空
if not person_id or string.len(person_id) == 0 
	or not qyjh_id or string.len(qyjh_id) == 0
	or not pageSize or string.len(pageSize) == 0 
	or not pageNumber or string.len(pageNumber) == 0
	then
    say("{\"success\":false,\"info\":\"person_id or qyjh_id or pageSize or pageNumber 参数错误！\"}")
    return
end
pageSize = tonumber(pageSize)
pageNumber = tonumber(pageNumber)

if keyword=="nil" then
	keyword = ""
else  --如果搜索关键字不为空就把传过来的base64进行编码转成真实的内容
	if #keyword~=0 then
		keyword = ngx.decode_base64(keyword)
	else
		keyword = ""
	end
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

local returnjson = {}
local dxqList = {}
returnjson.pageSize = pageSize
returnjson.pageNumber = pageNumber

local offset = pageSize*pageNumber-pageSize
local limit = pageSize

local querySql = "select id from t_qyjh_dxq where qyjh_id="..qyjh_id.." and person_id = "..person_id.." and dxq_name like '%"..keyword.."%' limit "..offset..","..limit.."";

local countSql = "select count(1) as dxqCount from t_qyjh_dxq where qyjh_id="..qyjh_id.." and person_id = "..person_id.." and dxq_name like '%"..keyword.."%'";
local hd_res = mysql_db:query(querySql)

local dxq_count = mysql_db:query(countSql)
local dxqids = {}
local dxqCount = dxq_count[1]["dxqCount"]
for i=1,#hd_res do
	local dxq_id = hd_res[i]["id"]
	table.insert(dxqids, dxq_id)
end
returnjson.totalRow = dxqCount
local totalPage = math.floor((dxqCount + pageSize - 1) / pageSize)
returnjson.totalPage = totalPage


for i=1,#dxqids,1 do
	local temp = {}
	local dxq = ssdb:hget("qyjh_dxq",dxqids[i])
	local t = cjson.decode(dxq[1])
	
	local xzt_tj = ssdb:hget("qyjh_dxq_tj",t.dxq_id.."_xzt_tj")
	local xx_tj = ssdb:hget("qyjh_dxq_tj",t.dxq_id.."_xx_tj")
	local js_tj = ssdb:hget("qyjh_dxq_tj",t.dxq_id.."_js_tj")
	local hd_tj = ssdb:hget("qyjh_dxq_tj",t.dxq_id.."_hd_tj")
	local zy_tj = ssdb:hget("qyjh_dxq_tj",t.dxq_id.."_zy_tj")
	local dtr_tj = ssdb:hget("qyjh_dxq_tj",t.dxq_id.."_dtr_tj")
	
	
	temp.dxq_id = dxqids[i]
	temp.dxq_name = t.name
	temp.xzt_tj = xzt_tj[1]
	temp.xx_tj = xx_tj[1]
	temp.js_tj = js_tj[1]
	temp.hd_tj = hd_tj[1]
	temp.zy_tj = zy_tj[1]
	temp.dtr_tj = dtr_tj[1]
	dxqList[#dxqList+1] = temp
end
returnjson.dxqList = dxqList

returnjson.success = "true"

say(cjson.encode(returnjson))

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
mysql_db:set_keepalive(0,v_pool_size)