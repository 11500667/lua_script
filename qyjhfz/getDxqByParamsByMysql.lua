--[[
区域均衡相关统计[mysql版]
@Author  chenxg
@Date    2015-06-03
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local quote = ngx.quote_sql_str
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

local returnjson = {}
local dxqList = {}
returnjson.pageSize = pageSize
returnjson.pageNumber = pageNumber

local offset = pageSize*pageNumber-pageSize
local limit = pageSize

local querySql = "select d.xzt_tj,d.xx_tj,d.js_tj,d.hd_tj,d.zy_tj,d.dtr_tj,d.dxq_id,d.dxq_name as name,d.person_id,d.description,d.district_id,d.city_id,d.province_id,d.createtime,d.logo_url,d.b_use,d.b_delete,d.qyjh_id,d.is_init  from t_qyjh_dxq d where b_delete=0 and b_use=1 and qyjh_id="..qyjh_id.." and person_id = "..person_id.." and dxq_name like "..quote("%"..keyword.."%").." limit "..offset..","..limit.."";

local countSql = "select count(1) as dxqCount from t_qyjh_dxq where b_delete=0 and b_use=1 and qyjh_id="..qyjh_id.." and person_id = "..person_id.." and dxq_name like "..quote("%"..keyword.."%").."";
local hd_res = db:query(querySql)
--ngx.log(ngx.ERR,"cxg_log ========>"..querySql.."<=============")
local dxq_count = db:query(countSql)
local dxqCount = dxq_count[1]["dxqCount"]

returnjson.totalRow = dxqCount
local totalPage = math.floor((dxqCount + pageSize - 1) / pageSize)
returnjson.totalPage = totalPage

local result, err, errno, sqlstate = db:query(querySql);
if not result then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	return;
end

--资源数统计
local dxq_id = "0"
for i=1,#result,1 do
	dxq_id = result[i]["dxq_id"]..","..dxq_id
end
local zy_sql = "select pub_target as dxq_id,count(distinct obj_id_int) as zy_tj from t_base_publish where b_delete=0 and pub_type=3 and pub_target in("..dxq_id..") group by pub_target"
local zy_result, err, errno, sqlstate = db:query(zy_sql);
if not zy_result then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	return;
end


for i=1,#result,1 do
	local temp = {}

	temp.dxq_id = result[i]["dxq_id"]
	temp.dxq_name = result[i]["name"]
	temp.person_id = result[i]["person_id"]
	temp.description = result[i]["description"]
	temp.district_id = result[i]["district_id"]
	temp.city_id = result[i]["city_id"]
	temp.province_id = result[i]["province_id"]
	temp.createtime = result[i]["createtime"]
	temp.logo_url = result[i]["logo_url"]
	temp.b_use = result[i]["b_use"]
	temp.b_delete = result[i]["b_delete"]
	temp.qyjh_id = result[i]["qyjh_id"]
	
	temp.xzt_tj = result[i]["xzt_tj"]
	temp.xx_tj = result[i]["xx_tj"]
	temp.js_tj = result[i]["js_tj"]
	temp.hd_tj = result[i]["hd_tj"]
	temp.is_init = result[i]["is_init"]
	temp.zy_tj = 0
	for j=1,#zy_result,1 do
		if temp.dxq_id == zy_result[j]["dxq_id"] then
			temp.zy_tj = zy_result[j]["zy_tj"]
			break
		end
	end
	temp.dtr_tj = result[i]["dtr_tj"]
	
	dxqList[#dxqList+1] = temp
end
returnjson.dxqList = dxqList
returnjson.success = "true"
say(cjson.encode(returnjson))

--mysql放回连接池
db:set_keepalive(0,v_pool_size)