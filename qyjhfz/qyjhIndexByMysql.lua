--[[
根据区域均衡ID获取区域均衡首页的信息[mysql版]
@Author  chenxg
@Date    2015-06-03
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
local returnjson = {}
--参数 
local qyjh_id = args["qyjh_id"]
--判断参数是否为空
if not qyjh_id or string.len(qyjh_id) == 0 
   then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
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
--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end
local qyjh_sql = "select dxq_tj,xzt_tj,xx_tj,js_tj,hd_tj,zy_tj from t_qyjh_qyjhs where qyjh_id="..qyjh_id
local qyjh_result, err, errno, sqlstate = db:query(qyjh_sql);
if not qyjh_result then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	return;
end

--统计资源数量
local zy_sql = "select count(distinct obj_id_int) as zy_tj from t_base_publish where b_delete=0 and pub_type=3 and qyjh_id="..qyjh_id..""
local zy_result, err, errno, sqlstate = db:query(zy_sql);
if not zy_result then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	return;
end

--区域均衡下学校数量统计【根据区域ID获取学校数量，需要基础数据提供或者写自己sql语句统计】
local numregion_id = tonumber(qyjh_id)
local where = ""
if numregion_id > 300000 then
	where = " and district_id ="..numregion_id
elseif numregion_id > 200000 then
	where = " and city_id ="..numregion_id
else
	where = " and province_id ="..numregion_id
end
local qyjh_xx_sql = "SELECT COUNT(1) AS xx_tj FROM T_BASE_ORGANIZATION O WHERE B_USE=1 AND O.ORG_TYPE=2"..where..";";
local qyjh_xx_results, err, errno, sqlstate = db:query(qyjh_xx_sql);
if not qyjh_xx_results then
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}");
    return;
end
local qyjh_xx_tj = qyjh_xx_results[1]["xx_tj"]

--区域均衡下教师数量统计【根据区域ID获取教师数量，需要基础数据提供或者写自己sql语句统计】
local qyjh_js_sql = "SELECT COUNT(1) AS js_tj FROM T_BASE_PERSON P WHERE B_USE=1 and IDENTITY_ID=5 "..where..";";
local qyjh_js_results, err, errno, sqlstate = db:query(qyjh_js_sql);
if not qyjh_js_results then
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}");
    return;
end
local qyjh_js_tj = qyjh_js_results[1]["js_tj"]

--获取区域均衡统计信息开始
local dxq_tj = qyjh_result[1]["dxq_tj"]
local xzt_tj = qyjh_result[1]["xzt_tj"]
local xx_tj = qyjh_xx_tj--qyjh_result[1]["xx_tj"]
local js_tj = qyjh_js_tj--qyjh_result[1]["js_tj"]
local hd_tj = qyjh_result[1]["hd_tj"]
local zy_tj = zy_result[1]["zy_tj"]
--获取区域均衡统计信息结束
--根据区域均衡ID获取按照点击量排行的前6个大学区开始
local dxq_sql = "select dxq_id,dxq_name as name,person_id,description,district_id,city_id,province_id,createtime,logo_url,b_use,b_delete,qyjh_id from t_qyjh_dxq where b_delete=0 and b_use=1 and qyjh_id="..qyjh_id.." order by djl_tj desc limit 0,6"
local dxq_result, err, errno, sqlstate = db:query(dxq_sql);
if not dxq_result then
	ngx.say("{\"success\":false,\"info\":\"查询大学区数据失败！\"}");
	return;
end
local dxqs = {}
for i=1,#dxq_result,1 do
	local temp = {}
	temp.dxq_id = dxq_result[i]["dxq_id"]
	temp.name = dxq_result[i]["name"]
	temp.person_id = dxq_result[i]["person_id"]
	temp.description = dxq_result[i]["description"]
	temp.district_id = dxq_result[i]["district_id"]
	temp.city_id = dxq_result[i]["city_id"]
	temp.province_id = dxq_result[i]["province_id"]
	temp.createtime = dxq_result[i]["createtime"]
	temp.logo_url = dxq_result[i]["logo_url"]
	temp.b_use = dxq_result[i]["b_use"]
	temp.b_delete = dxq_result[i]["b_delete"]
	temp.qyjh_id = dxq_result[i]["qyjh_id"]
	dxqs[#dxqs+1] = temp
end
returnjson.dxq_list = dxqs

--UFT_CODE
local function urlEncode(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end

--获取最新的活动开始 陈续刚2015-02-09添加
local hdlist
local params = "?page_type=1&hd_type=-1&path_id="..qyjh_id.."&pageSize=3&pageNumber=1&subject_id=-1"
local res_org = ngx.location.capture("/dsideal_yy/qyjhfz/getHdByParams"..params)

if res_org.status == 200 then
	hdlist = (cjson.decode(res_org.body))
else
	say("{\"success\":false,\"info\":\"查询活动失败！\"}")
	return
end
returnjson.hd_list = hdlist.hd_list
--获取最新的活动结束

returnjson.success = "true"
returnjson.dxq_tj = dxq_tj
returnjson.xzt_tj = xzt_tj
returnjson.xx_tj = xx_tj
returnjson.js_tj = js_tj
returnjson.hd_tj = hd_tj
returnjson.zy_tj = zy_tj

say(cjson.encode(returnjson))

--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0,v_pool_size)