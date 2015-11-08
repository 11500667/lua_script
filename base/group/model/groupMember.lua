--[[
#陈续刚 2015-08-04
#描述：查询群组成员
	   根据当前用户获取所属机构，所管理机构，所属群组，所任教班级含班主任
	   机构群组添加成员
	   人员群组添加成员
]]
local DBUtil   = require "common.DBUtil";
local _GroupMember = {};
local quote = ngx.quote_sql_str
-- -----------------------------------------------------------------------------------
-- 函数描述： 群组功能 -> 获取T_BASE_GroupModel_MEMBER_NEW表的新的ID（从SSDB中获取）
-- 日    期： 2015年8月6日
-- 返 回 值： boolean true操作成功，false操作失败
-- -----------------------------------------------------------------------------------
local function getNewRecordMemberPk()
    return SSDBUtil: incr("t_base_group_member_new_pk");
end

_GroupMember.getNewRecordMemberPk = getNewRecordMemberPk;

---------------------------------------------------------------------------
--[[

]]
local function getGroupMumberForApp(groupId,app_type)
	local returnjson = {}
	local personlist = {}
	--从群组检索教师
	local base_sql = " select p.person_name,p.person_id,p.login_name,p.identity_id"
	local where_sql = " from t_base_group_member_new gm left join t_sys_loginperson p on p.person_id = gm.person_id and p.identity_id = gm.identity_id  where gm.b_use=1 and gm.state_id = 1 and gm.group_id="..groupId.." ";
	
	local result = DBUtil: querySingleSql(base_sql..where_sql);
	
	if result and #result>=1 then
		for i=1,#result do
			local person = {}
			local person_id = result[i]["person_id"]
			local identity_id = result[i]["identity_id"]
			local tx_info = SSDBUtil:multi_hget("ypt_"..person_id.."_"..identity_id,"extension","file_id")
			local res =  {}
			if tx_info[2] == nil then
				res.extension = "jpg";
			else
				res.extension = tx_info[2];
			end

			if tx_info[4] == nil then
				res.file_id = "0D7B3741-0C3D-D93C-BA3D-74668271F934";
			else
				res.file_id = tx_info[4];
			end
			person.person_name = result[i]["person_name"]
			person.person_id = result[i]["person_id"]
			person.login_name = result[i]["login_name"]
			person.avatar_url = res.file_id.."."..res.extension
			personlist[#personlist+1] = person
		end
	
	end
	returnjson.success = true
	returnjson.personList = personlist
	return returnjson;

	ngx.log(ngx.ERR, "cxg_log org_sql=====>"..base_sql..where_sql.."==>");
end
_GroupMember.getGroupMumberForApp = getGroupMumberForApp;
---------------------------------------------------------------------------
--[[
	局部函数：根据人员组内角色，学校名/用户姓名 模糊查询群组内成员
	作者： 	  陈续刚 		2015-08-04
	参数： 	  groupId  		群组的ID
	参数： 	  rangeType  	选取范围的类型[1所属机构2管理的机构3所属群组4任教班级5其他群组]
	参数： 	  orgType  	    机构的类型[1教育局2学校3部门] 
							只有群组添加人时需要，其他地方可以传-1
	参数： 	  stage_id 	    学段ID 默认-1
	参数： 	  subject_id  	学科ID 默认-1
	参数： 	  keyword  	    关键字
	参数： 	  pageNumber  	当前页码
	参数： 	  pageSize  	每页显示条数
	参数： 	  member_type  	人员组内角色：-1全部0群主1管理员2普通成员
	返回值1： boolean 	    查询是否成功
	返回值2： 成员的table
]]
local function getMemberByparams(groupId,nodeId,rangeType,orgType,keyword,pageNumber,pageSize,member_type,stage_id,subject_id)
	local returnjson={}
	local count_result = {}
	local result = {}
	local stage_sql = ""
	local subject_sql = ""
	if stage_id ~= -1 then 
		stage_sql = " and p.stage_id="..stage_id..""
	end
	if subject_id ~= -1 then 
		subject_sql = " and p.subject_id="..subject_id..""
	end
	if keyword=="nil" then
		keyword = ""
	else  --如果搜索关键字不为空就把传过来的base64进行编码转成真实的内容
		if #keyword~=0 then
			keyword = ngx.decode_base64(keyword)..""
		else
			keyword = ""
		end
	end
	local member_sql = ""
	if member_type ~=-1 then
		member_sql= " and gm.member_type="..member_type..""
	end

	local limit_sql = " limit "..pageSize*pageNumber-pageSize..","..pageSize
	--local DBUtil = require "common.DBUtil";
	--local db = DBUtil: getDb();
	--从群组中检索人员
	if rangeType == 3 then
		local group_type = 2
		local group_type_sql = "select GROUP_TYPE from t_base_group_new g where id="..nodeId..""
		local type_result = DBUtil: querySingleSql(group_type_sql)
		if type_result and #type_result==1 then
			group_type = tonumber(type_result[1]["GROUP_TYPE"])
		end
		--人员群组检索群组成员
		if group_type == 2 then
			--从群组检索教师
			local base_sql = " select p.PERSON_NAME,p.PERSON_ID,p.identity_id,o.org_name as sch_name,o.org_id as bureau_id,oo.org_name,gm.member_type,0 as is_check,gm.id"
			local where_sql = " from t_base_group_member_new gm left join t_base_organization o on o.org_id = gm.bureau_id left join t_base_person p on p.person_id = gm.person_id and p.identity_id = gm.identity_id left join t_base_organization oo on oo.org_id=p.org_id and oo.bureau_id = o.org_id  where gm.b_use=1 and gm.state_id = 1 and gm.identity_id !=6 and gm.group_id="..nodeId.." "..member_sql.." and (p.person_name like "..quote("%"..keyword.."%").." or o.org_name  like "..quote("%"..keyword.."%")..")" ..stage_sql..subject_sql.."  ";---order by member_type asc
			
			--从群组检索学生
			local base_sql2 = " select p.student_name as PERSON_NAME,p.student_id  as  PERSON_ID,6 as identity_id,o.org_name as sch_name,o.org_id as bureau_id,oo.class_name as org_name,gm.member_type,0 as is_check,gm.id "
			local where_sql2 = " from t_base_group_member_new gm left join t_base_organization o on o.org_id = gm.bureau_id left join t_base_student p on p.student_id = gm.person_id left join t_base_class oo on oo.class_id=p.class_id and oo.bureau_id = o.org_id where gm.b_use=1 and  gm.state_id = 1 and gm.identity_id=6 and gm.group_id="..nodeId.." "..member_sql.." and (p.student_name like "..quote("%"..keyword.."%").." or o.org_name  like "..quote("%"..keyword.."%")..")  ";--order by member_type asc
			
			count_result = DBUtil: querySingleSql("select gm.person_id "..where_sql.." UNION ".."select gm.person_id" .. where_sql2 );
			
			result = DBUtil: querySingleSql(base_sql..where_sql.." UNION "..base_sql2..where_sql2.."order by member_type asc " ..limit_sql);
			ngx.log(ngx.ERR, "cxg_log org_sql=====>"..base_sql..where_sql.." UNION "..base_sql2..where_sql2.."order by member_type asc " ..limit_sql.."==>");
		--机构群组检索群组成员
		else

			local base_sql = " select p.PERSON_NAME,p.PERSON_ID,p.identity_id,o.org_name as sch_name,o.org_id as bureau_id,oo.org_name,2 as member_type,0 as is_check,gm.id"
			local where_sql = "  from t_base_person p left join t_base_organization o on o.org_id = p.bureau_id   left join t_base_organization oo on oo.org_id=p.org_id and oo.bureau_id = o.org_id left join t_base_group_member_new gm on p.person_id = gm.person_id and p.identity_id = gm.identity_id and gm.group_id="..nodeId.." where p.org_id in(select org_id from t_base_group_org_new gmn where gmn.group_id="..nodeId..") and p.person_name like "..quote("%"..keyword.."%") ..stage_sql..subject_sql.." ";
			
			
			--ngx.log(ngx.ERR, "cxg_log org_sql=====>"..base_sql..where_sql..limit_sql.."==>");	
			count_result = DBUtil: querySingleSql("select p.person_id "..where_sql.."");
			
			result = DBUtil: querySingleSql(base_sql..where_sql.." "..limit_sql);
			
			
			
		end
	--从学校检索人员
	elseif rangeType == 1 or rangeType == 2 then
		local org_sql = "p.bureau_id = "..nodeId..""
		if orgType == 3 then
			org_sql = "p.org_id = "..nodeId..""
		end
		local base_sql = " select p.PERSON_NAME,p.PERSON_ID,p.identity_id,o.org_name as sch_name,o.org_id as bureau_id,oo.org_name,3 as member_type,0 as is_check ,-1 as id"
		local where_sql = " from t_base_person p left join t_base_organization o on o.org_id = p.bureau_id left join t_base_organization oo on oo.org_id=p.org_id and oo.bureau_id = o.org_id where "..org_sql.." and o.b_use=1 and oo.b_use=1 and p.person_name like "..quote("%"..keyword.."%")..stage_sql..subject_sql.."";
		
		count_result = DBUtil: querySingleSql("select p.person_id"..where_sql);
		result = DBUtil: querySingleSql(base_sql..where_sql..limit_sql);
	--从好友检索人员
	elseif rangeType == 5  then
		
	--从班级检索人员
	elseif rangeType == 4 then
		local org_sql = "p.class_id = "..nodeId..""
		local base_sql = " select p.student_name as PERSON_NAME,6 as identity_id,p.student_id as PERSON_ID,o.org_name as sch_name,o.org_id as bureau_id,oo.class_name as org_name,3 as member_type,0 as is_check,-1 as id"
		local where_sql = " from t_base_student p left join t_base_organization o on o.org_id = p.bureau_id left join t_base_class oo on oo.class_id=p.class_id and oo.bureau_id = o.org_id where "..org_sql.." and p.student_name like "..quote("%"..keyword.."%");
		
		count_result = DBUtil: querySingleSql("select p.student_id as person_id "..where_sql);
		ngx.log(ngx.ERR, "cxg_log asdasdasd=====>"..base_sql..where_sql..limit_sql.."==>");	
		result = DBUtil: querySingleSql(base_sql..where_sql..limit_sql);
	end
	if not result then 
		return false, nil;
	end
	--[[校验当前群组功能检索出来的用户的关系]]
	local person_ids = ""
	if count_result then
		local limit = pageSize*pageNumber+1
		if #count_result < limit then
			limit = #count_result
		end
		for i= pageSize*pageNumber-pageSize+1,limit do
			person_ids = person_ids .. count_result[i]["person_id"] ..","
		end
	end
	if string.len(person_ids) >1 then
		person_ids = string.sub(person_ids,0,string.len(person_ids)-1)
		local person_sql = "select group_id,person_id,identity_id from t_base_group_member_new gm where gm.b_use=1 and gm.group_id="..groupId.." and person_id in("..person_ids..")"
		ngx.log(ngx.ERR, "cxg_log person_sql=====>"..person_sql.."==>");	
		local person_result = DBUtil: querySingleSql(person_sql);
		if person_result then
			if #person_result >=1 then 
				for i=1,#person_result do
					local old_person_id = person_result[i]["person_id"]
					local old_identity_id = person_result[i]["identity_id"]
					for j=1,#result do
						local new_person_id = result[j]["PERSON_ID"]
						local new_identity_id = result[j]["identity_id"]
					
						if  tonumber(old_person_id) == tonumber(new_person_id) and tonumber(old_identity_id) == tonumber(new_identity_id) then
							result[j]["is_check"] = 1
						end
					end
				end
			end
		end
	end
	
	
	local totalRow = #count_result
	local totalPage = math.floor((totalRow + pageSize - 1) / pageSize)
	returnjson.success = true
	returnjson.totalPage = totalPage
	returnjson.totalRow = totalRow
	returnjson.pageSize = pageSize
	returnjson.pageNumber = pageNumber
	returnjson.table_List = result
	return true, returnjson;
end

_GroupMember.getMemberByparams = getMemberByparams;
---------------------------------------------------------------------------
--[[
	局部函数：根据 学校名 模糊查询机构群组内成员
	作者： 	  陈续刚 		2015-08-10
	参数： 	  groupId  		群组的ID
	参数： 	  stage_id 	    学段ID 默认-1
	参数： 	  subject_id  	学科ID 默认-1
	参数： 	  keyword  	    关键字
	参数： 	  pageNumber  	当前页码
	参数： 	  pageSize  	每页显示条数
	返回值1： boolean 	    查询是否成功
	返回值2： 成员的table
]]
local function getOrgMemberByparams(groupId,keyword,pageNumber,pageSize,stage_id,subject_id)
	local returnjson={}
	local count_result = {}
	local result = {}
	local stage_sql = ""
	local subject_sql = ""
	if stage_id ~= -1 then 
		stage_sql = " and gon.stage_id="..stage_id..""
	end
	if subject_id ~= -1 then 
		subject_sql = " and gon.subject_id="..subject_id..""
	end
	if keyword=="nil" then
		keyword = ""
	else  --如果搜索关键字不为空就把传过来的base64进行编码转成真实的内容
		if #keyword~=0 then
			keyword = ngx.decode_base64(keyword)..""
		else
			keyword = ""
		end
	end

	local limit_sql = " limit "..pageSize*pageNumber-pageSize..","..pageSize
	--local DBUtil = require "common.DBUtil";
	--local db = DBUtil: getDb();
	
	local org_sql = "gon.group_id = "..groupId..""
	
	--ifnull(SU.SUBJECT_NAME,'暂无') as SUBJECT_NAME
	local base_sql = " select gon.id,o.org_name,IFNULL(st.STAGE_NAME,'全部') as stage_name,IFNULL(su.SUBJECT_NAME,'全部') as subject_name "
	local where_sql = "  from t_base_group_org_new gon  left join t_base_organization o on o.org_id = gon.org_id  LEFT JOIN t_dm_subject su on su.SUBJECT_ID = gon.SUBJECT_ID  LEFT JOIN t_dm_stage st on st.STAGE_ID = gon.STAGE_ID where gon.b_use=1 and "..org_sql.." and o.org_name like "..quote("%"..keyword.."%")..stage_sql..subject_sql.."";
	
	count_result = DBUtil: querySingleSql("select gon.id"..where_sql);
	ngx.log(ngx.ERR, "cxg_log sql=====>"..base_sql..where_sql..limit_sql.."==>");	
	result = DBUtil: querySingleSql(base_sql..where_sql..limit_sql);
		
	if not result then 
		return false, nil;
	end
	local totalRow = #count_result
	local totalPage = math.floor((totalRow + pageSize - 1) / pageSize)
	returnjson.success = true
	returnjson.totalPage = totalPage
	returnjson.totalRow = totalRow
	returnjson.pageSize = pageSize
	returnjson.pageNumber = pageNumber
	returnjson.table_List = result
	return true, returnjson;
end

_GroupMember.getOrgMemberByparams = getOrgMemberByparams;

---------------------------------------------------------------------------
--[[
	局部函数：根据人员ID获取添加群人员的范围[学校，群组，好友，班级......]
	作者： 	  陈续刚 		2015-08-04
	参数： 	  personId  	人员ID
	参数： 	  identity_id  	身份ID
	参数： 	  plat_type  	所属系统类型：0系统、1云平台、2区域均衡、3教研、4学习模块、5高师实训
	参数： 	  group_type  	检索类型 1所属机构2管理的机构3所属群组4任教班级5其他群组
	参数： 	  use_range  	使用范围：-1全部、1教师、2学生、3混搭
	返回值1： boolean 	    查询是否成功
	返回值2： 成员的table
]]
local function getGroups(personId,identity_id,plat_type,group_type,use_range)
	--获取用户是否是管理员，最高级别
		--获取所管理区域的机构树【市、区管理员获取机构树，普通用户获取学校及部门】
	
	--local DBUtil = require "common.DBUtil";
	--local db = DBUtil: getDb();
	local CacheUtil = require "common.CacheUtil";
	local cache = CacheUtil: getRedisConn();
	local sql = "";
	local use_range_sql = "";
	if use_range ~= -1 then
		use_range_sql = " and g.use_range = "..use_range..""
	end
	--获取教师所属的学校【含部门】
	if identity_id == 5 and group_type == 1 then--普通教师
		--从cookie获取当前用户的省市区ID
		local schID = cache:hget("person_"..personId.."_"..identity_id,"xiao")
		sql = "SELECT ORG_ID,ORG_NAME,PARENT_ID,ORG_TYPE,-1 as CHECK_ID FROM T_BASE_ORGANIZATION WHERE BUREAU_ID ="..schID.."";
	elseif identity_id == 6 and group_type == 1 then--学生[暂时用不上]
		sql = "SELECT CLASE_ID as ORG_ID,CALSS_NAME as ORG_NAME,-1 AS PARENT_ID,-1 as ORG_TYPE,-1 as CHECK_ID  FROM T_BASE_CLASS WHERE CLASS_ID = (SELECT CLASS_ID FROM T_BASE_STUDENT WHERE STUDENT_ID="..personId..")";
	--获取所管理的市区校
	elseif group_type == 2 then
		local manage_sql = "select unit_id,unit_type from t_base_maneger where person_id="..personId.." and b_use=1 order by unit_id asc limit 1"
		--ngx.log(ngx.ERR, "cxg_log =====>"..group_type.."==>"..manage_sql);	
		local manage_result, err, errno, sqlstate = DBUtil: querySingleSql(manage_sql);
		if not manage_result or #manage_result==0 then --不是管理员
			return false, nil;
		else
			local unit_type = manage_result[1]["unit_type"]
			local unit_id = manage_result[1]["unit_id"]
			--unit_type =1 县区，获取树[不含部门]，构建机构树
			if tonumber(unit_type) == 1 then
				local quID = cache:hget("person_"..personId.."_"..identity_id,"qu")
				sql = "SELECT ORG_ID,ORG_NAME,district_id as PARENT_ID,ORG_TYPE, "..quID.." as CHECK_ID FROM T_BASE_ORGANIZATION WHERE district_id ="..unit_id.." and ORG_TYPE !=3";
			--unit_type =2 学校[含部门]
			elseif tonumber(unit_type) == 2 then
				
				sql = "SELECT ORG_ID,ORG_NAME,"..unit_id.." as PARENT_ID,ORG_TYPE,"..unit_id.." as CHECK_ID FROM T_BASE_ORGANIZATION WHERE BUREAU_ID ="..unit_id.."";
			--unit_type =3 市 需要获取区，然后获取校[不含部门]，构建机构树
			elseif tonumber(unit_type) == 3 then
				local shiID = cache:hget("person_"..personId.."_"..identity_id,"qu")
				local city_sql = "SELECT ID as ORG_ID,CITYNAME as ORG_NAME,-1 as PARENT_ID,5 as ORG_TYPE,-1 as CHECK_ID from t_gov_city where ID="..unit_id.." "
				local dis_sql = "SELECT ID as ORG_ID,DISTRICTNAME as ORG_NAME,CITYID as PARENT_ID,4 as ORG_TYPE,-1 as CHECK_ID from t_gov_district where CITYID="..unit_id.." "
				local sch_sql = "SELECT ORG_ID,ORG_NAME,district_id as PARENT_ID,ORG_TYPE,-1 as CHECK_ID FROM T_BASE_ORGANIZATION WHERE city_id ="..unit_id.." and ORG_TYPE =2"
				
				sql = city_sql.." UNION "..dis_sql.." UNION "..sch_sql
			end
		end
	--所属群组
	elseif 	group_type == 3 then
		sql = "select gm.group_id as ORG_ID,group_name as ORG_NAME,PARENT_ID,-1 as ORG_TYPE,-1 as CHECK_ID from t_base_group_member_new gm left join t_base_group_new g on g.ID = gm.group_id where gm.state_id = 1 and  gm.b_use=1 and g.b_use=1 and person_id="..personId.." and identity_id="..identity_id.." and g.PLAT_TYPE="..plat_type.." "..use_range_sql..""
	--获取任教班级
	elseif 	group_type == 4 then
		sql = "select distinct c.class_id as ORG_ID,c.class_name as ORG_NAME,org_ID as PARENT_ID ,6 as ORG_TYPE,-1 as CHECK_ID from t_base_class c left join t_base_class_subject cs on c.class_id = cs.class_id left join t_base_term t on t.xq_id = cs.xq_id where ((cs.b_use=1 and teacher_id="..personId..") or c.bzr_id="..personId..") and t.sfdqxq = 1"
	--其他群组
	elseif 	group_type == 5 then
		sql = "select gm.group_id as ORG_ID,group_name as ORG_NAME,PARENT_ID,-1 as ORG_TYPE,-1 as CHECK_ID from t_base_group_member_new gm left join t_base_group_new g on g.ID = gm.group_id where gm.state_id = 1 and gm.b_use=1 and g.b_use=1 and person_id="..personId.." and identity_id="..identity_id.." and g.PLAT_TYPE !="..plat_type..use_range_sql..""
	end
	--ngx.log(ngx.ERR, "cxg_log =====>"..group_type.."==>"..sql);	
	local result, err, errno, sqlstate = DBUtil: querySingleSql(sql);
	if not result then 
		return false, nil;
	end
	
	local treeData = "["
	local returnjson={}
	
	returnjson.success = true
	if #result>=1 then
		for i=1,#result,1 do
			local ORG_ID = result[i]["ORG_ID"]
			local ORG_NAME = result[i]["ORG_NAME"]
			local PARENT_ID = result[i]["PARENT_ID"]
			local CHECK_ID = result[i]["CHECK_ID"]
			local ORG_TYPE = result[i]["ORG_TYPE"]
			local open_str = ""
			if tonumber(PARENT_ID) == tonumber(CHECK_ID) then
				open_str = ",\"open\":true"
			end
			treeData = treeData.."{\"id\":"..ORG_ID..",\"pId\":"..PARENT_ID..",\"name\":\""..ORG_NAME.."\",\"org_type\":"..ORG_TYPE.." "..open_str.."},";--
		end
		if string.len(treeData) >1 then
			treeData = string.sub(treeData,0,string.len(treeData)-1)
		end
	end
	treeData = treeData.."]"
	returnjson.tree_data = treeData
	
	return true, returnjson;
end
_GroupMember.getGroups = getGroups;

---------------------------------------------------------------------------
--[[
	局部函数：机构群组添加成员
	作者： 	  陈续刚 		2015-08-05
	参数： 	  groupId    	群组的ID
	参数： 	  currentTime  	当前时间 2015-08-06 12:12:12
	参数： 	  ts  			TS值：2015080612121200000
	参数： 	  oids  	        所选机构及学段学科oids[{org_id:123,stage_id:1,subject_id:1},
											      {org_id:123,stage_id:1,subject_id:1}]
	返回值1： boolean 	    查询是否成功
	返回值2： 
]]
local function addMemberByOrg(groupId,currentTime,ts,oids)
	--local DBUtil = require "common.DBUtil";
	--local db = DBUtil: getDb();
	local CacheUtil = require "common.CacheUtil";
	local cache = CacheUtil: getRedisConn();
	local org_sql = "";
	local group_org_sql = "";
	for i=1,#oids do
		local stage_sql = ""
		local subject_sql = ""
		local org_type_sql = ""
		local join_type = "1"
        local org_id = oids[i].org_id
        local org_type = tonumber(oids[i].org_type)
        local stage_id = tonumber(oids[i].stage_id)
        local subject_id = tonumber(oids[i].subject_id)
		
		if org_type == 2 then 
			org_type_sql = " bureau_id="..org_id..""
		elseif org_type == 3 then 
			org_type_sql = " org_id="..org_id..""
		elseif org_type == 4 then 
			org_type_sql = " district_id="..org_id..""
		elseif org_type == 5 then 
			org_type_sql = " city_id="..org_id..""
		end
		
		if stage_id ~= -1 then 
			stage_sql = " and stage_id="..stage_id..""
			join_type = "2"
		end
		if subject_id ~= -1 then 
			subject_sql = " and subject_id="..subject_id..""
		end
		org_sql = org_sql .. " ("..org_type_sql..stage_sql..subject_sql..") or"
		group_org_sql = group_org_sql.."("..groupId..","..org_id..","..org_type..","..join_type..","..stage_id..","..subject_id.."),"
    end
	if string.len(org_sql) >1 then
		org_sql = string.sub(org_sql,0,string.len(org_sql)-2)
	end
	if string.len(group_org_sql) >1 then
		group_org_sql = string.sub(group_org_sql,0,string.len(group_org_sql)-1)
	end
	--机构群组选择完机构后，暂时不往群组-人员关系表写数据
	--[[
	local batch_sql = "insert into t_base_group_member_new(GROUP_ID,PERSON_ID,IDENTITY_ID,STATE_ID,B_USE,APPLY_TIME,CHECK_TIME,BUREAU_ID,TS) select "..groupId..",person_id,identity_id,1,1,"..quote(currentTime)..","..quote(currentTime)..",bureau_id ,"..ts.." from t_base_person where ("..org_sql..") and person_id not in(select person_id from t_base_group_member_new where GROUP_ID="..groupId..")";
	
	local result, err, errno, sqlstate = db: query(batch_sql);
	if not result then 
		return false;
	end
	]]
	
	
	if string.len(group_org_sql) >1 then
		local batch_sql2 = "insert into t_base_group_org_new(group_id,ORG_ID,ORG_TYPE,JOIN_TYPE,STAGE_ID,SUBJECT_ID) values "..group_org_sql..""
		local result2, err, errno, sqlstate = DBUtil: querySingleSql(batch_sql2);
		if not result2 then 
			return false;
		end
	end
	--维护人员跟群组的缓冲
	local redies_sql = "select person_id,identity_id from t_base_person where ("..org_sql..")"
	ngx.log(ngx.ERR, "cxg_log redies_sql=====>"..redies_sql.."==>");	
	local result3, err, errno, sqlstate = DBUtil: querySingleSql(redies_sql);
	if not result3 then 
		return false;
	end
	for i=1,#result3 do
		local personId = result3[i]["person_id"]
		local identityId = result3[i]["identity_id"]
		cache:sadd("group_"..personId.."_"..identityId , groupId);
		cache:sadd("group_"..personId.."_"..identityId.."_real" , groupId);
	end
	return true;
end
_GroupMember.addMemberByOrg = addMemberByOrg;
---------------------------------------------------------------------------
--[[
	局部函数：普通群组添加成员
	作者： 	  陈续刚 		2015-08-05
	参数： 	  groupId    	群组的ID
	参数： 	  pids 	        所选取的多个人员pids [{person_id:123,identity_id:1,bureau_id:1},
												  {person_id:123,identity_id:1,bureau_id:1}]
	参数： 	  oids  	    所选机构及学段学科oids[{org_id:123,stage_id:1,subject_id:1},
											       {org_id:123,stage_id:1,subject_id:1}]
	参数： 	  create_time  	当前时间 2015-08-06 12:12:12
	参数： 	  ts  			TS值：2015080612121200000
	返回值1： boolean 	    查询是否成功
	返回值2： 
]]
local function addMember(groupId,create_time,ts,pids,oids,state_id)
	--local DBUtil = require "common.DBUtil";
	--local db = DBUtil: getDb();
	local CacheUtil = require "common.CacheUtil";
	local cache = CacheUtil: getRedisConn();	

	local person_sql = ""
	local org_sql = ""
	--选取多个用户
	if pids and #pids>=1 then 
		for i=1,#pids do
			local person_id = pids[i].person_id
			local identity_id = pids[i].identity_id
			local bureau_id = pids[i].bureau_id
			person_sql = person_sql.."("..groupId..","..person_id..","..identity_id..","..bureau_id..","..state_id..",'"..create_time.."','"..create_time.."',"..ts.."),"
			cache:sadd("group_"..person_id.."_"..identity_id , groupId);
			cache:sadd("group_"..person_id.."_"..identity_id.."_real" , groupId);
		end
		if string.len(person_sql) >1 then
			person_sql = string.sub(person_sql,0,string.len(person_sql)-1)
			local batch_sql2 = "insert into t_base_group_member_new(GROUP_ID,PERSON_ID,IDENTITY_ID,BUREAU_ID,STATE_ID,APPLY_TIME,CHECK_TIME,TS) VALUES "..person_sql..""
			ngx.log(ngx.ERR, "cxg_log batch_sql=====>"..batch_sql2.."==>");	
			local result2, err, errno, sqlstate = DBUtil: querySingleSql(batch_sql2);
			if not result2 then 
				return false;
			end
		end
	end
	--机构+学段学科批量添加用户
	if oids and #oids>=1 then 
		for i=1,#oids do
			local org_id = ids[i].org_id
			local stage_id = ids[i].stage_id
			local subject_id = ids[i].subject_id
			if stage_id ~= "-1" then 
				stage_sql = " and stage_id="..stage_id..""
			end
			if subject_id ~= "-1" then 
				subject_sql = " and subject_id="..subject_id..""
			end
			org_sql = org_sql .. " (org_id="..org_id..stage_sql..subject_sql..") or"

		end
		if string.len(org_sql) >1 then
			org_sql = string.sub(org_sql,0,string.len(org_sql)-2)
			local batch_sql = "insert into t_base_group_member_new(GROUP_ID,PERSON_ID,IDENTITY_ID,STATE_ID,APPLY_TIME,CHECK_TIME,BUREAU_ID,TS) select "..groupId..",person_id,identity_id,1,"..quote(currentTime)..","..quote(currentTime)..",bureau_id ,"..ts.." from t_base_person where ("..org_sql..") and person_id not in(select person_id from t_base_group_member_new where GROUP_ID="..group_id..")";
			
			local result, err, errno, sqlstate = DBUtil: querySingleSql(batch_sql);
			if not result then 
				return false;
			end
			
			--维护人员跟群组的缓冲
			local redies_sql = "select person_id,identity_id from t_base_person where ("..org_sql..")"
			local result3, err, errno, sqlstate = DBUtil: querySingleSql(redies_sql);
			if not result3 then 
				return false;
			end
			for i=1,#result3 do
				local personId = result3[i]["person_id"]
				local identityId = result3[i]["identityId"]
				cache:sadd("group_"..personId.."_"..identityId , groupId);
				cache:sadd("group_"..personId.."_"..identityId.."_real" , groupId);
			end
			
		end			
	end
	--ngx.log(ngx.ERR, "cxg_log batch_sql=====>222222222222222222222==>");	
	return true;
end
_GroupMember.addMember = addMember;

--[[
	局部函数：机构群组移除某个群组
	作者： 	  陈续刚 		2015-08-10
	参数： 	  Id    		ID
	返回值1： boolean 	    删除是否成功
	返回值2：
]]
local function removeOrg(Id)
	--local DBUtil = require "common.DBUtil";
	--local db = DBUtil: getDb();
	local CacheUtil = require "common.CacheUtil";
	local cache = CacheUtil: getRedisConn();
	
	
	--维护人员跟群组的缓冲
	local group_sql = "select group_id,org_type,org_id,stage_id,subject_id from t_base_group_org_new where id="..Id.." and b_use=1"
	local result2, err, errno, sqlstate = DBUtil: querySingleSql(group_sql);
	local org_sql = ""
	local stage_sql = ""
	local subject_sql = ""
	if result2 and #result2>=1 then
		local org_id = result2[1]["org_id"]
		local org_type = tonumber(result2[1]["org_type"])
		local stage_id = tonumber(result2[1]["stage_id"])
		local subject_id = tonumber(result2[1]["subject_id"])
		
		if org_type == 2 then 
			org_sql = " bureau_id="..org_id..""
		elseif org_type == 3 then 
			org_sql = " org_id="..org_id..""
		elseif org_type == 4 then 
			org_sql = " district_id="..org_id..""
		elseif org_type == 5 then 
			org_sql = " city_id="..org_id..""
		end
		
		if stage_id ~= -1 then 
			stage_sql = " and stage_id="..stage_id..""
		end
		if subject_id ~= -1 then 
			subject_sql = " and subject_id="..subject_id..""
		end
		org_sql = org_sql..stage_sql..subject_sql..""
	end
	local redies_sql = "select person_id,identity_id from t_base_person where "..org_sql..""
	local result3, err, errno, sqlstate = DBUtil: querySingleSql(redies_sql);
	if not result3 then 
		return false;
	end
	for i=1,#result3 do
		local personId = result3[i]["person_id"]
		local identityId = result3[i]["identity_id"]
		cache:srem("group_"..personId.."_"..identityId , groupId);
		cache:srem("group_"..personId.."_"..identityId.."_real" , groupId);
	end
	local update_sql = "update t_base_group_org_new set b_use=0 where id="..Id..""
	
	local result, err, errno, sqlstate = DBUtil: querySingleSql(update_sql);
	if not result then 
		return false;
	end
	--ngx.log(ngx.ERR, "cxg_log batch_sql=====>222222222222222222222==>");	
	return true;
end
_GroupMember.removeOrg = removeOrg;

return _GroupMember;