--[[
根据大学区ID获取大学区信息[mysql版]
@Author  chenxg
@Date    2015-06-02
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
--参数 
local dxq_id = args["dxq_id"]


--判断参数是否为空
if not dxq_id or string.len(dxq_id) == 0 
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
local querySql = "select xzt_tj,xx_tj,js_tj,hd_tj,zy_tj,dxq_id,dxq_name as name,person_id,description,district_id,city_id,province_id,createtime,logo_url,b_use,b_delete,qyjh_id,is_init from t_qyjh_dxq where dxq_id="..dxq_id
local result, err, errno, sqlstate = db:query(querySql);
if not result then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	return;
end
--统计资源数量
local zy_sql = "select count(distinct obj_id_int) as zy_tj from t_base_publish where b_delete=0 and pub_type=3 and pub_target="..dxq_id..""
local zy_result, err, errno, sqlstate = db:query(zy_sql);
if not zy_result then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	return;
end

local temp = {}
if #result>=1 then
	temp.dxq_id = result[1]["dxq_id"]
	temp.name = result[1]["name"]
	temp.person_id = result[1]["person_id"]
	temp.description = result[1]["description"]
	temp.district_id = result[1]["district_id"]
	temp.city_id = result[1]["city_id"]
	temp.province_id = result[1]["province_id"]
	temp.createtime = result[1]["createtime"]
	temp.logo_url = result[1]["logo_url"]
	temp.b_use = result[1]["b_use"]
	temp.b_delete = result[1]["b_delete"]
	temp.qyjh_id = result[1]["qyjh_id"]
	
	temp.xzt_tj = result[1]["xzt_tj"]
	temp.xx_tj = result[1]["xx_tj"]
	temp.js_tj = result[1]["js_tj"]
	temp.hd_tj = result[1]["hd_tj"]
	temp.zy_tj = zy_result[1]["zy_tj"]
	temp.is_init = result[1]["is_init"]
	--获取person_id详情, 调用java接口
	local personlist
	local res_person = ngx.location.capture("/dsideal_yy/person/getPersonNameListByIds?ids="..temp.person_id)
	if res_person.status == 200 then
		personlist = cjson.decode(res_person.body)
	else
		say("{\"success\":false,\"info\":\"查询失败！\"}")
		return
	end
	temp.person_name = personlist.list[1].personName
end

temp.success = "true"
say(cjson.encode(temp))

--mysql放回连接池
db:set_keepalive(0,v_pool_size)