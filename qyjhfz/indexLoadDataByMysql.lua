--[[
首页点击加载数据（区域均衡门户(大学区门户)下加载大学区、协作体、学校、教师数据）[mysql版]
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
local returnjson = {}
--参数 
--加载数据的页面，1：区域均衡门户 2：大学区首页 3:协作体首页
local page_type = args["page_type"]
--要加载哪个栏目的数据：1：大学区，2：协作体，3：学校，4：教师
local data_source = args["data_source"]
--传入的区域均衡Id或者大学区ID
local path_id = args["path_id"]
--控制显示的数量
local limit = args["limit"]

--判断参数是否为空
if not page_type or string.len(page_type) == 0 
	or not data_source or string.len(data_source) == 0 
	or not path_id or string.len(path_id) == 0 
	or not limit or string.len(limit) == 0 
   then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end
limit = tonumber(limit)

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

if page_type == "1" then--区域均衡首页加载数据
	if data_source == "1" then--大学区数据 
		--根据区域均衡ID获取按照点击量排行的前6个大学区开始
		local dxq_sql = "select dxq_id,dxq_name as name,person_id,description,district_id,city_id,province_id,createtime,logo_url,b_use,b_delete,qyjh_id from t_qyjh_dxq where b_delete=0 and b_use=1 and qyjh_id="..path_id.." order by djl_tj desc limit 0,"..limit..""
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

	elseif data_source == "2"  then--协作体数据 
		--根据区域均衡ID获取按照[资源数+活动数]排行的前6个协作体开始
		local xzt_sql = "select qyjh_id,dxq_id,xzt_id,xzt_name as name,subject_id,person_name,ts,person_id,createUeer_id,description,district_id,city_id,province_id,createtime,logo_url,org_id  from t_qyjh_xzt where b_delete=0 and b_use=1 and qyjh_id="..path_id.." order by zy_tj+hd_tj desc limit 0,"..limit..""
		local xzt_result, err, errno, sqlstate = db:query(xzt_sql);
		if not xzt_result then
			ngx.say("{\"success\":false,\"info\":\"查询协作体数据失败！\"}");
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
				temp.zy_tj = xzt_result[i]["zy_tj"]
				temp.wk_tj = xzt_result[i]["wk_tj"]
				xzts[#xzts+1] = temp
			end
		end
		returnjson.xzt_list = xzts
	elseif data_source == "3"  then--学校数据
		--根据上传数量获取前N个学校列表开始
		--[[local org_sql = "select org_id ,count(distinct obj_info_id) as res_count from t_qyjh_dxq_org t1 left join t_base_publish t2 on t1.org_id = t2.school_id and t1.qyjh_id = t1.qyjh_id where t1.b_use=1 and t2.b_delete=0 and pub_type=3 and t2.qyjh_id="..path_id.." group by school_id order by res_count desc limit 0,"..limit..""]]
		local org_sql = "select qxt.org_id  ,count(bp.obj_id_int) as res_count from t_qyjh_dxq_org qxt LEFT JOIN t_base_publish bp on bp.school_id = qxt.org_id and qxt.b_use=1 and qxt.qyjh_id=bp.qyjh_id and pub_type=3 and bp.b_delete=0 where qxt.qyjh_id="..path_id.." GROUP BY  qxt.org_id order by res_count desc limit 0,"..limit..""
		local org_result, err, errno, sqlstate = db:query(org_sql);
		if not org_result then
			ngx.say("{\"success\":false,\"info\":\"查询学校数据失败！\"}");
			return;
		end
		local orgids = "-1"
		local orgs = {}
		if #org_result>=1 then
			for i=1,#org_result,1 do
				orgids = org_result[i]["org_id"] ..","..orgids
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
	elseif data_source == "4"  then--教师数据
		--根据上传数量获取前N个教师列表开始
		local tea_sql = "select qxt.person_id as person_id ,count(bp.obj_id_int) as res_count from t_base_person qxt LEFT JOIN t_base_publish bp on bp.person_id = qxt.person_id and pub_type=3 where qxt.BUREAU_ID in(select org_id from t_qyjh_dxq_org where qxt.identity_id=5 and qyjh_id="..path_id.." and B_USE=1) GROUP BY qxt.person_id order by res_count desc; limit 0,"..limit..""
		local tea_result, err, errno, sqlstate = db:query(tea_sql);
		if not tea_result then
			ngx.say("{\"success\":false,\"info\":\"查询协作体数据失败！\"}");
			return;
		end
		local teaids  = "-1"
		local teas = {}
		if #tea_result>=1 then
			for i=1,#tea_result,1 do
				teaids = tea_result[i]["person_id"]..","..teaids
			end
			local res_person = ngx.location.capture("/dsideal_yy/person/getPersonNameListByIds?ids="..teaids)
			--ngx.log(ngx.ERR, "aaaaownxzts====>"..teaids.."<====");
			if res_person.status == 200 then
				teas = cjson.decode(res_person.body)
			else
				say("{\"success\":false,\"info\":\"查询教师数据失败！\"}")
				return
			end
			returnjson.tea_list = teas.list
		else
			returnjson.tea_list = teas
		end
		--根据上传数量获取前N个教师列表结束
	end
elseif page_type == "2" then--大学区门户页加载数据
	if data_source == "2" then--大学区下协作体数据
		--根据大学区ID获取按照点击量排行的前6个协作体开始
		local xzt_sql = "select qyjh_id,dxq_id,xzt_id,xzt_name as name,subject_id,person_name,ts,person_id,createUeer_id,description,district_id,city_id,province_id,createtime,logo_url,org_id  from t_qyjh_xzt where b_delete=0 and b_use=1 and xzt_id="..path_id.." order by zy_tj+hd_tj desc limit 0,"..limit..""
		local xzt_result, err, errno, sqlstate = db:query(xzt_sql);
		if not xzt_result then
			ngx.say("{\"success\":false,\"info\":\"查询协作体数据失败！\"}");
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
				temp.zy_tj = xzt_result[i]["zy_tj"]
				temp.wk_tj = xzt_result[i]["wk_tj"]
				xzts[#xzts+1] = temp
			end
		end
		returnjson.xzt_list = xzts
		--根据大学区ID获取按照点击量排行的前6个协作体结束
	elseif data_source == "3"  then--学校数据 
		--根据上传数量获取前N个学校列表开始
		--[[local org_sql = "select school_id ,count(distinct obj_info_id) as res_count from t_base_publish where b_delete=0 and pub_type=3 and dxq_id="..path_id.." group by school_id order by res_count desc limit 0,"..limit..""]]
		local org_sql = "select qxt.org_id ,count(bp.obj_id_int) as res_count from t_qyjh_dxq_org qxt LEFT JOIN t_base_publish bp on bp.school_id = qxt.org_id and qxt.b_use=1 and qxt.qyjh_id=bp.qyjh_id and pub_type=3 and bp.b_delete=0 where qxt.dxq_id="..path_id.." GROUP BY qxt.org_id order by res_count desc limit 0,"..limit..""
		local org_result, err, errno, sqlstate = db:query(org_sql);
		if not org_result then
			ngx.say("{\"success\":false,\"info\":\"查询学校数据失败！\"}");
			return;
		end
		local orgids = "-1"
		local orgs = {}
		if #org_result>=1 then
			for i=1,#org_result,1 do
				orgids = org_result[i]["org_id"] ..","..orgids
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
	elseif data_source == "4"  then--教师数据 
		--根据上传数量获取前N个教师列表开始
		--[[local tea_sql = "select person_id ,count(distinct obj_info_id) as res_count from t_base_publish where b_delete=0 and pub_type=3 and dxq_id="..path_id.." group by person_id order by res_count desc limit 0,"..limit..""]]
		local tea_sql = "select qxt.person_id as person_id ,count(bp.obj_id_int) as res_count from t_base_person qxt LEFT JOIN t_base_publish bp on bp.person_id = qxt.person_id and pub_type=3 where qxt.identity_id=5 and qxt.BUREAU_ID in(select org_id from t_qyjh_dxq_org where dxq_id="..path_id.." and B_USE=1) GROUP BY qxt.person_id order by res_count desc limit 0,"..limit..""
		local tea_result, err, errno, sqlstate = db:query(tea_sql);
		if not tea_result then
			ngx.say("{\"success\":false,\"info\":\"查询协作体数据失败！\"}");
			return;
		end
		local teaids  = "-1"
		local teas = {}
		if #tea_result>=1 then
			for i=1,#tea_result,1 do
				teaids = tea_result[i]["person_id"]..","..teaids
			end
			local res_person = ngx.location.capture("/dsideal_yy/person/getPersonNameListByIds?ids="..teaids)
			--ngx.log(ngx.ERR, "aaaaownxzts====>"..teaids.."<====");
			if res_person.status == 200 then
				teas = cjson.decode(res_person.body)
			else
				say("{\"success\":false,\"info\":\"查询教师数据失败！\"}")
				return
			end
			returnjson.tea_list = teas.list
		else
			returnjson.tea_list = teas
		end
		--根据上传数量获取前N个教师列表结束
	end
else--协作体首页
	if data_source == "4"  then--教师数据 
		--根据上传数量获取前N个教师列表开始
		--[[local tea_sql = "select person_id ,count(distinct obj_info_id) as res_count from t_base_publish where b_delete=0 and pub_type=3 and xzt_id="..path_id.." group by person_id order by res_count desc limit 0,"..limit..""]]
		local tea_sql = "select qxt.tea_id as person_id ,count(bp.obj_id_int) as res_count from t_qyjh_xzt_tea qxt LEFT JOIN t_base_publish bp on bp.person_id = qxt.tea_id and qxt.xzt_id=bp.xzt_id and pub_type=3 and qxt.qyjh_id=bp.qyjh_id and bp.b_delete=0 where qxt.xzt_id="..path_id.." and qxt.b_use=1 GROUP BY qxt.tea_id order by res_count desc limit 0,"..limit..""
		local tea_result, err, errno, sqlstate = db:query(tea_sql);
		if not tea_result then
			ngx.say("{\"success\":false,\"info\":\"查询协作体数据失败！\"}");
			return;
		end
		local teaids  = "-1"
		local teas = {}
		if #tea_result>=1 then
			for i=1,#tea_result,1 do
				teaids = tea_result[i]["person_id"]..","..teaids
			end
			local res_person = ngx.location.capture("/dsideal_yy/person/getPersonNameListByIds?ids="..teaids)
			--ngx.log(ngx.ERR, "aaaaownxzts====>"..teaids.."<====");
			if res_person.status == 200 then
				teas = cjson.decode(res_person.body)
			else
				say("{\"success\":false,\"info\":\"查询教师数据失败！\"}")
				return
			end
			returnjson.tea_list = teas.list
		else
			returnjson.tea_list = teas
		end
		--根据上传数量获取前N个教师列表结束
	end
end

returnjson.success = "true"

say(cjson.encode(returnjson))
--mysql放回连接池
db:set_keepalive(0,v_pool_size)