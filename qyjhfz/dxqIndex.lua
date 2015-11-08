--[[
根据大学区ID获取大学区首页的信息
@Author  chenxg
@Date    2015-01-27
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"
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

--获取大学区统计信息开始
local xzt_tj = ssdb:hget("qyjh_dxq_tj",dxq_id.."_xzt_tj")
local xx_tj = ssdb:hget("qyjh_dxq_tj",dxq_id.."_xx_tj")
local js_tj = ssdb:hget("qyjh_dxq_tj",dxq_id.."_js_tj")
local hd_tj = ssdb:hget("qyjh_dxq_tj",dxq_id.."_hd_tj")
local zy_tj = ssdb:hget("qyjh_dxq_tj",dxq_id.."_zy_tj")
--获取大学区统计信息结束
--根据大学区ID获取按照[资源数+活动数]排行的前6个协作体开始
local txztids = ssdb:zrrange("qyjh_xzt_sort_"..dxq_id,0,6)
local xztids = {}
local xzts = {}
if #txztids>=2 then
	for i=1,#txztids,2 do
		table.insert(xztids,txztids[i])
	end
	local xztlist, err = ssdb:multi_hget('qyjh_xzt',unpack(xztids));
	for i=2,#xztlist,2 do
		--table.insert(xzts,xztlist[i])
		local t = cjson.decode(xztlist[i])
		xzts[#xzts+1] = t
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
local torgids = ssdb:zrrange("qyjh_dxq_org_uploadcount_"..dxq_id,0,8)
local orgids = "-1"
local orgs = {}
if #torgids>=2 then
	for i=1,#torgids,2 do
		orgids = torgids[i]..","..orgids
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

--获取最新资源
--[[local resource_new_tab= {}
res = mysql_db:query("SELECT SQL_NO_CACHE id FROM t_base_publish_sphinxse WHERE query='filter=b_delete,0;filter=pub_type,3;filter=pub_target,"..dxq_id..";groupby=attr:obj_info_id;groupsort=DOWN_COUNT desc;limit=6'")

for i=1,#res do

	local  res_new_tab = {}
	local  res_info = {}
	local iid = cache:hget("publish_"..res[i]["id"],"obj_info_id")
	local obj_type = cache:hget("publish_"..res[i]["id"],"obj_type")
	if obj_type == "1" or obj_type == "4" then --资源、备课
		res_info = cache:hmget("resource_"..iid,"resource_title","resource_format","resource_page","file_id","thumb_id","preview_status","width","height","for_urlencoder_url","for_iso_url","res_type","beike_type","resource_size_int","scheme_id_int","create_time","resource_id_int")
		--根据版本ID获取该版本属于哪个学科    
		local subject_name = ssdb:hget("t_resource_scheme_"..res_info[14],"subject_name")[1]
		local subject_id = ssdb:hget("t_resource_scheme_"..res_info[14],"subject_id")[1]
		res_new_tab["iid"] = iid
		res_new_tab["resource_title"] = res_info[1]
		res_new_tab["resource_format"] = res_info[2]
		res_new_tab["resource_page"] = res_info[3]
		res_new_tab["file_id"] = res_info[4]
		res_new_tab["thumb_id"] = res_info[5]
		res_new_tab["preview_status"] = res_info[6]
		res_new_tab["width"] = res_info[7]
		res_new_tab["height"] = res_info[8]
		res_new_tab["for_urlencoder_url"] = res_info[9]
		res_new_tab["for_iso_url"] = res_info[10]
		res_new_tab["res_type"] = res_info[11]
		res_new_tab["beike_type"] = res_info[12]
		res_new_tab["resource_size_int"] = res_info[13]
		res_new_tab["url_code"] = urlEncode(res_info[1])
		res_new_tab["subject_name"] = subject_name
		res_new_tab["subject_id"] = subject_id
		res_new_tab["create_time"] = res_info[15]
		res_new_tab["resource_id_int"] = res_info[16]
		
	elseif obj_type == "3" then --试卷		
		local paper_value = cache:hmget("paper_"..iid,"paper_id_char","paper_name","question_count","create_time","paper_type","extension","parent_structure_name","paper_id_int","person_id","resource_info_id")
		res_new_tab["iid"] = iid
		res_new_tab["paper_id"] = paper_value[1]
		res_new_tab["resource_title"] = paper_value[2]
		res_new_tab["create_time"] = paper_value[4]
		res_new_tab["resource_format"] = paper_value[6]
		res_new_tab["paper_id_int"] = paper_value[8]
		res_new_tab["paper_id_char"] =paper_value[1]
		ngx.log(ngx.ERR,"@@@@@@@@@"..paper_value[9].."@@@@@@@@@")
		local resource_value = cache:hmget("resource_"..paper_value[10],"preview_status","for_iso_url","for_urlencoder_url","file_id","resource_page","structure_id","scheme_id_int","resource_id_int")
		res_new_tab["preview_status"] =resource_value[1]
		res_new_tab["for_iso_url"] =resource_value[2]
		res_new_tab["for_urlencoder_url"] =resource_value[3]
		res_new_tab["file_id"] =resource_value[4]
		res_new_tab["page"] =resource_value[5]
		res_new_tab["scheme_id_int"] =resource_value[7]
		res_new_tab["resource_id_int"] =resource_value[8]
		local subject_name = ssdb:hget("t_resource_scheme_"..resource_value[7],"subject_name")[1]
		local subject_id = ssdb:hget("t_resource_scheme_"..resource_value[7],"subject_id")[1]
		res_new_tab["subject_name"] = subject_name
		res_new_tab["subject_id"] = subject_id

	elseif obj_type == "5" then --微课
		res_info = cache:hmget("wkds_"..iid,"wkds_name","file_id","scheme_id","scheme_id","scheme_id")
	end

	resource_new_tab[i] = res_new_tab
end
returnjson["resource_hot"] = resource_new_tab]]
--根据下载数量获取资源列表结束

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


returnjson.success = "true"
returnjson.xzt_tj = xzt_tj[1]
returnjson.xx_tj = xx_tj[1]
returnjson.js_tj = js_tj[1]
returnjson.hd_tj = hd_tj[1]
returnjson.zy_tj = zy_tj[1]
returnjson.fzr_id = dxqinfo.person_id
returnjson.fzr_name = dxqinfo.person_name
returnjson.description = dxqinfo.description
returnjson.name = dxqinfo.name

say(cjson.encode(returnjson))
--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
--redis放回连接池
cache:set_keepalive(0,v_pool_size)
--mysql放回连接池
mysql_db:set_keepalive(0,v_pool_size)