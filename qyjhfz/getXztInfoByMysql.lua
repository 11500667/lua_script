--[[
根据大学区ID获取大学区信息[mysql版]
@Author  chenxg
@Date    2015-06-02
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
--参数 
local xzt_id = args["xzt_id"]


--判断参数是否为空
if not xzt_id or string.len(xzt_id) == 0 
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

--获取详细信息
local xzt_sql = "select qyjh_id,dxq_id,xzt_id,xzt_name as name,subject_id,person_name,ts,person_id,createUeer_id,description,district_id,city_id,province_id,createtime,logo_url,org_id,js_tj,hd_tj,zy_tj,is_init from t_qyjh_xzt where b_delete=0 and b_use=1 and xzt_id = "..xzt_id.." "
local xzt_result, err, errno, sqlstate = db:query(xzt_sql);
if not xzt_result then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	return;
end

--统计资源数量
local zy_sql = "select count(distinct obj_id_int) as zy_tj from t_base_publish where b_delete=0 and pub_type=3 and xzt_id="..xzt_id..""
local zy_result, err, errno, sqlstate = db:query(zy_sql);
if not zy_result then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	return;
end

local temp = {}
temp.qyjh_id = xzt_result[1]["qyjh_id"]
temp.dxq_id = xzt_result[1]["dxq_id"]
temp.xzt_id = xzt_result[1]["xzt_id"]
temp.name = xzt_result[1]["name"]
temp.person_id = xzt_result[1]["person_id"]
temp.description = xzt_result[1]["description"]
temp.district_id = xzt_result[1]["district_id"]
temp.city_id = xzt_result[1]["city_id"]
temp.province_id = xzt_result[1]["province_id"]
temp.createtime = xzt_result[1]["createtime"]
temp.logo_url = xzt_result[1]["logo_url"]
temp.b_use = xzt_result[1]["b_use"]
temp.createUeer_id = xzt_result[1]["createUeer_id"]
temp.subject_id = xzt_result[1]["subject_id"]
temp.b_delete = xzt_result[1]["b_delete"]
temp.org_id = xzt_result[1]["org_id"]
temp.js_tj = xzt_result[1]["js_tj"]
temp.hd_tj = xzt_result[1]["hd_tj"]
temp.is_init = xzt_result[1]["is_init"]
temp.zy_tj = zy_result[1]["zy_tj"]

local dxq_sql = "select dxq_id from t_qyjh_dxq where is_init=1 and dxq_id = "..temp.dxq_id.." "
local dxq_result, err, errno, sqlstate = db:query(dxq_sql);
if not dxq_result then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	return;
end
temp.dxq_init = false
if #dxq_result>=1 then
	temp.dxq_init = true
end
temp.success = "true"

--获取person_id详情, 调用java接口
local personlist
local res_person = ngx.location.capture("/dsideal_yy/person/getPersonNameListByIds?ids="..temp.person_id)
if res_person.status == 200 then
	personlist = cjson.decode(res_person.body)
else
	say("{\"success\":false,\"info\":\"查询失败！\"}")
	return
end
--ngx.log(ngx.ERR,"cxg_log ========>"..#personlist.."<=============")

if #personlist.list==0 then--基础数据已经将该用户删除
	temp.person_name = "未知"
else
	temp.person_name = personlist.list[1].personName
end

say(cjson.encode(temp))

--mysql放回连接池
db:set_keepalive(0,v_pool_size)
