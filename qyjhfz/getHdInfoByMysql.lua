--[[
根据活动ID获取活动信息[mysql版]
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
--参数 
local hd_id = args["hd_id"]


--判断参数是否为空
if not hd_id or string.len(hd_id) == 0 
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
local temp = {}
local querySql = "select id as mysql_id,qyjh_id,dxq_id,xzt_id,person_id,hd_name as active_name,hd_id,lx_id as hd_type,statu,start_time as start_date,end_time as end_date,create_time as createtime,ts,subject_id,b_delete,startts,description,hd_confid,con_pass from t_qyjh_hd where hd_id = "..hd_id
local result, err, errno, sqlstate = db:query(querySql);
if not result then
	ngx.say("{\"success\":false,\"info\":\"查询协作体数据失败！\"}");
	return;
end
temp.hd_id = result[1]["hd_id"]
temp.mysql_id = result[1]["mysql_id"]
temp.subject_id = result[1]["subject_id"]
temp.hd_confid = result[1]["hd_confid"]
temp.active_name = result[1]["active_name"]
temp.description = result[1]["description"]
temp.person_id = result[1]["person_id"]
temp.start_date = result[1]["start_date"]
temp.end_date = result[1]["end_date"]
temp.statu=result[1]["statu"]
temp.con_pass=result[1]["con_pass"]
temp.createtime = result[1]["createtime"]
temp.b_delete = result[1]["b_delete"]
temp.hd_type = tostring(result[1]["hd_type"])
local ssname
local res_person = ngx.location.capture("/dsideal_yy/dzsb/getSubjectStageById?subject_id="..temp.subject_id)
if res_person.status == 200 then
	ssname = cjson.decode(res_person.body)
else
	say("{\"success\":false,\"info\":\"查询失败！\"}")
	return
end

temp.subject_name=ssname.stage_name..ssname.subject_name

temp.success = "true"

say(cjson.encode(temp))

--mysql放回连接池
db:set_keepalive(0, v_pool_size)