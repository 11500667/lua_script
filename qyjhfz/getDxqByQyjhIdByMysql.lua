--[[
根据区域均衡ID获取大学区列表[mysql版]
@Author  chenxg
@Date    2015-06-01
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
local qyjh_id = args["qyjh_id"]
local pageSize = ngx.var.arg_pageSize
local pageNumber = ngx.var.arg_pageNumber
--page_type[1：前台2：后台]
local page_type = ngx.var.arg_page_type


--判断参数是否为空
if not qyjh_id or string.len(qyjh_id) == 0 
	or not pageSize or string.len(pageSize) == 0 
	or not pageNumber or string.len(pageNumber) == 0
	or not page_type or string.len(page_type) == 0
   then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end
pageSize = tonumber(pageSize)
pageNumber = tonumber(pageNumber)

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
--判断是否已经开通
local querySql = "select b_open from t_qyjh_qyjhs where qyjh_id= "..qyjh_id;
local result, err, errno, sqlstate = db:query(querySql);
if not result then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	return
end
if #result < 1 then
	say("{\"success\":false,\"info\":\"该地区尚未开通区域均衡！\"}")
	return
end
local returnjson = {}
local list1 = {}
--*****
local tids  = {}
local totalDxqs={}
--计算检索数据的起始和结束为止
local order_sql = " order by ts desc"
local count_sql = "select qyjh_id,dxq_id,dxq_name as name,person_id,description,district_id,city_id,province_id,createtime,logo_url,xx_tj,xzt_tj,dtr_tj from t_qyjh_dxq where b_use=1 and b_delete=0 and qyjh_id="..qyjh_id..""
local limit_sql = " limit "..pageSize*pageNumber-pageSize..","..pageSize.." "

local count_result, err, errno, sqlstate = db:query(count_sql);
--ngx.log(ngx.ERR,"cxg_log===******===>"..count_sql..order_sql..limit_sql.."<=====******=====")
local result, err, errno, sqlstate = db:query(count_sql..order_sql..limit_sql);
if not count_result then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	return
end
local totalRow = #count_result
local totalPage = math.floor((totalRow + pageSize - 1) / pageSize)
returnjson.totalPage = totalPage
returnjson.totalRow = totalRow

local personids = "-1"
if #count_result>=1 then
	for i=1,#result,1 do
		local temp = {}
		personids = personids..","..result[i]["person_id"]
		temp.dxq_id = result[i]["dxq_id"]
		temp.district_id = result[i]["district_id"]
		temp.province_id = result[i]["province_id"]
		temp.createtime = result[i]["createtime"]
		temp.city_id = result[i]["city_id"]
		temp.description = result[i]["description"]
		temp.b_use = result[i]["b_use"]
		temp.name = result[i]["name"]
		temp.logo_url = result[i]["logo_url"]
		temp.qyjh_id = result[i]["qyjh_id"]
		temp.person_id = result[i]["person_id"]
		temp.b_delete = result[i]["b_delete"]
		if page_type == "1" then -- 前台
			temp.orgCount= result[i]["xx_tj"]
			temp.xztCount= result[i]["xzt_tj"]
			temp.dtrCount= result[i]["dtr_tj"]
		else
			if result[i]["xx_tj"] > 0 then 
				temp.hasOrg=true
			else
				temp.hasOrg=false
			end
		end
		list1[#list1+1] = temp
	end
end
--获取person_id详情, 调用lua接口
local personlist

local res_person = ngx.location.capture("/dsideal_yy/person/getPersonNameListByIds?ids="..personids)
if res_person.status == 200 then
	personlist = cjson.decode(res_person.body)
else
	say("{\"success\":false,\"info\":\"查询失败！\"}")
	return
end
--合并list1和personlist
for i=1,#list1 do
	for j=1,#personlist.list do
		if list1[i].person_id == tostring(personlist.list[j].personID) then
			list1[i].person_name = personlist.list[j].personName
			break
		end
	end
end
--获取大学区下的教师ID列表结束


returnjson.list = list1
returnjson.success = "true"
returnjson.pageNumber = pageNumber
returnjson.pageSize = pageSize
say(cjson.encode(returnjson))

--mysql放回连接池
db:set_keepalive(0,v_pool_size)