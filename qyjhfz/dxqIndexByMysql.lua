--[[
根据大学区ID获取大学区首页的信息[mysql版]
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
local dxq_id = args["dxq_id"]

--判断参数是否为空
if not dxq_id or string.len(dxq_id) == 0 
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

--根据大学区ID获取按照[资源数+活动数]排行的前6个协作体开始
local xzt_sql = "select qyjh_id,dxq_id,xzt_id,xzt_name as name,subject_id,person_name,ts,person_id,createUeer_id,description,district_id,city_id,province_id,createtime,logo_url,org_id  from t_qyjh_xzt where b_delete=0 and b_use=1 and dxq_id="..dxq_id.." order by zy_tj+hd_tj desc limit 0,6"
local xzt_result, err, errno, sqlstate = db:query(xzt_sql);
if not xzt_result then
	ngx.say("{\"success\":false,\"info\":\"查询协作体数据失败！\"}");
	return;
end

local xzt_id = "0"
for i=1,#xzt_result,1 do
	xzt_id = xzt_result[i]["xzt_id"]..","..xzt_id
end
local zy_sql = "select xzt_id,count(distinct obj_id_int) as zy_tj from t_base_publish where b_delete=0 and pub_type=3 and xzt_id in("..xzt_id..") group by xzt_id"
local wk_sql = "select xzt_id,count(distinct obj_id_int) as wk_tj from t_base_publish where b_delete=0 and pub_type=3 and obj_type=5 and xzt_id in("..xzt_id..") group by xzt_id"
local zy_result, err, errno, sqlstate = db:query(zy_sql);
local wk_result, err, errno, sqlstate = db:query(wk_sql);
if not zy_result then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
	return;
end

local xzts = {}
if #xzt_result>=1 then
	for i=1,#xzt_result,1 do
		local temp = {}
		temp.qyjh_id = xzt_result[i]["qyjh_id"]
		temp.dxq_id = xzt_result[i]["dxq_id"]
		temp.xzt_id = xzt_result[i]["xzt_id"]
		temp.name = xzt_result[i]["name"]
		temp.person_id = xzt_result[i]["person_id"]
		temp.person_name = xzt_result[i]["person_name"]
		temp.description = xzt_result[i]["description"]
		temp.district_id = xzt_result[i]["district_id"]
		temp.city_id = xzt_result[i]["city_id"]
		temp.province_id = xzt_result[i]["province_id"]
		temp.createtime = xzt_result[i]["createtime"]
		temp.logo_url = xzt_result[i]["logo_url"]
		temp.b_use = xzt_result[i]["b_use"]
		temp.createUeer_id = xzt_result[i]["createUeer_id"]
		temp.subject_id = xzt_result[i]["subject_id"]
		temp.b_delete = xzt_result[i]["b_delete"]
		temp.org_id = xzt_result[i]["org_id"]
		temp.js_tj = xzt_result[i]["js_tj"]
		temp.hd_tj = xzt_result[i]["hd_tj"]
		temp.zy_tj = 0
		temp.wk_tj = 0
		for j=1,#zy_result,1 do
			if temp.xzt_id == zy_result[j]["xzt_id"] then
				temp.zy_tj = zy_result[j]["zy_tj"]
				break
			end
		end
		for j=1,#wk_result,1 do
			if temp.xzt_id == wk_result[j]["xzt_id"] then
				temp.wk_tj = wk_result[j]["wk_tj"]
				break
			end
		end
		xzts[#xzts+1] = temp
	end
end
returnjson.xzt_list = xzts
--根据大学区ID获取按照点击量排行的前6个协作体结束
--根据大学区ID获取大学区信息开始
local dxqinfo
local res_org = ngx.location.capture("/dsideal_yy/qyjhfz/getDxqInfo?dxq_id="..dxq_id)

if res_org.status == 200 then
	dxqinfo = (cjson.decode(res_org.body))
else
	say("{\"success\":false,\"info\":\"查询失败！\"}")
	--return
end
--根据大学区ID获取大学区信息结束


--根据上传数量获取前N个学校列表开始
local org_sql = "select qxt.org_id ,count(bp.obj_id_int) as res_count from t_qyjh_dxq_org qxt LEFT JOIN t_base_publish bp on bp.school_id = qxt.org_id and qxt.b_use=1 and qxt.qyjh_id=bp.qyjh_id and pub_type=3 and bp.b_delete=0 where qxt.dxq_id="..dxq_id.." GROUP BY qxt.org_id order by res_count desc limit 0,8"
local org_result, err, errno, sqlstate = db:query(org_sql);
if not org_result then
	ngx.say("{\"success\":false,\"info\":\"查询学校数据失败！\"}");
	return;
end
local orgids = "-1"
local orgs = {}
if #org_result>=1 then
	for i=1,#org_result,1 do
		orgids = org_result[i]["org_id"]..","..orgids
	end
	local res_org = ngx.location.capture("/dsideal_yy/org/getSchoolNameByIds?ids=".. orgids)
	if res_org.status == 200 then
		orgs = (cjson.decode(res_org.body))
	else
		say("{\"success\":false,\"info\":\"查询学校数据失败！\"}")
		--return
	end
	returnjson.org_list = orgs.list
else
	returnjson.org_list = orgs
end
--根据上传数量获取前N个学校列表结束

--根据下载数量获取资源列表开始
--UFT_CODE
local function urlEncode(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end

--获取最新的活动开始 陈续刚2015-02-09添加
local hdlist
local params = "?page_type=2&hd_type=-1&qyjh_id="..dxqinfo.qyjh_id.."&path_id="..dxq_id.."&pageSize=3&pageNumber=1&subject_id=-1"
local res_org = ngx.location.capture("/dsideal_yy/qyjhfz/getHdByParams"..params)

if res_org.status == 200 then
	hdlist = (cjson.decode(res_org.body))
else
	say("{\"success\":false,\"info\":\"获取活动信息失败！\"}")
	return
end
returnjson.hd_list = hdlist.hd_list
--获取最新的活动结束
--统计资源数量
local zy_sql = "select count(distinct obj_id_int) as zy_tj from t_base_publish where b_delete=0 and pub_type=3 and pub_target="..dxq_id..""
local zy_result, err, errno, sqlstate = db:query(zy_sql);
if not zy_result then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	return;
end

returnjson.success = "true"
returnjson.xzt_tj = dxqinfo.xzt_tj
returnjson.xx_tj = dxqinfo.xx_tj
returnjson.js_tj = dxqinfo.js_tj
returnjson.hd_tj = dxqinfo.hd_tj
returnjson.zy_tj = zy_result[1]["zy_tj"]
returnjson.fzr_id = dxqinfo.person_id
returnjson.fzr_name = dxqinfo.person_name
returnjson.description = dxqinfo.description
returnjson.name = dxqinfo.name

say(cjson.encode(returnjson))
--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
--mysql放回连接池
db:set_keepalive(0,v_pool_size)