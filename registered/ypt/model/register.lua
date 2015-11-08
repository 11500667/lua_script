--[[
#陈续刚 2015-08-26
#描述：云端用户注册功能
]]


local CacheUtil = require "common.CacheUtil";
local DBUtil    = require "common.DBUtil";
local _Register = {};
local quote = ngx.quote_sql_str
----------------------------------------------------------------------------------------
--[[
	局部函数：检验用户名是否存在，[支持添加和编辑时校验]
	作者： 	  陈续刚 		2015-08-26
	参数： 	  personId  	用户的ID，添加用户校验用户名是传递
	参数： 	  loginName  	用户的ID
	返回值1： boolean 	    查询是否成功 true:没有重复的 false：存在重名的
]]
local function checkLoginName(personId,loginName)
	local person_sql = ""
	if personId then
		person_sql = " and person_id !="..personId..""
	end
    local sql = "select person_id from t_sys_loginperson where login_name = "..quote(loginName).." "..person_sql
	--ngx.log(ngx.ERR, "cxg_log checkLoginName loginName=====>"..sql.."==>");	
	result = DBUtil: querySingleSql(sql)
	if not result then
		return false
	end
	if #result>=1 then
		return false
	else
		return true
	end
end

_Register.checkLoginName = checkLoginName;

-----------------------------------------------------------------------------------------
--[[
	局部函数：根据检索条件获取学校
	作者： 	  陈续刚 		2015-08-26
	参数： 	  provinceId  	省ID
	参数： 	  cityId  	    市ID
	参数： 	  districtId  	区ID
	参数： 	  keyword  	    关键字
	参数： 	  register_flag 学校范围【0全部1系统2注册未审核3注册审核通过4注册审核不通过】
	返回值1： 学校的table
]]
local function getSchByparams(provinceId,cityId,districtId,keyword,pageNumber,pageSize,register_flag)
	local returnjson = {}
	if keyword=="nil" or keyword=="" then
		keyword = ""
	else  --如果搜索关键字不为空就把传过来的base64进行编码转成真实的内容
		if #keyword~=0 then
			keyword = ngx.decode_base64(keyword)..""
		else
			keyword = ""
		end
	end
	
	local register_flag_sql = " and register_flag in(1,2,3)"
	local province_sql = ""
	local city_sql = ""
	local district_sql = ""
	if register_flag then
		if register_flag == 0 then
			register_flag_sql = " and register_flag in(1,2,3)"
		else
			register_flag_sql = " and register_flag ="..register_flag..""
		end
	end
	
	
	if provinceId ~= -1 then
		province_sql = " and o.province_id ="..provinceId..""
	end
	if cityId ~= -1 then
		city_sql = " and o.city_id ="..cityId..""
	end
	if districtId ~= -1 then
		district_sql = " and o.district_id ="..districtId..""
	end
    local base_sql = "select o.org_id,o.org_name,o.register_flag,ifnull(p.provincename,'--') as province_name,ifnull(c.cityname,'--') as city_name,ifnull(d.districtname,'--') as district_name from t_base_organization o left join t_gov_province p on p.id = o.province_id left join t_gov_city c on c.id = o.city_id left join t_gov_district d on d.id = o.district_id where o.b_use=1 and o.org_type !=3 and (o.org_name  like "..quote("%"..keyword.."%").." or o.org_id  like "..quote("%"..keyword.."%")..") and (BUSINESS_SYSTEM_SOURCE = 'COMMON' or BUSINESS_SYSTEM_SOURCE = 'YPT')"..province_sql..city_sql..district_sql..register_flag_sql.."    order by CREATE_TIME desc "
    
	--ngx.log(ngx.ERR, "cxg_log sql=====>"..base_sql.."==>");	
	local count_sql = "select o.org_id from t_base_organization o where o.b_use=1 and o.org_type !=3 and (o.org_name like "..quote("%"..keyword.."%").." or o.org_id  like "..quote("%"..keyword.."%")..") "..province_sql..city_sql..district_sql..register_flag_sql.." "
	
	local limit_sql = " limit "..pageSize*pageNumber-pageSize..","..pageSize
	local result = DBUtil: querySingleSql(base_sql..limit_sql)
	local count_result = DBUtil: querySingleSql(count_sql)
	
	if not result then
		return false, nil;
	end
	
	local totalRow = 0 
	if count_result then
		totalRow = #count_result
	end
	
	local totalPage = math.floor((totalRow + pageSize - 1) / pageSize)
	returnjson.success = true
	returnjson.totalPage = totalPage
	returnjson.totalRow = totalRow
	returnjson.pageSize = pageSize
	returnjson.pageNumber = pageNumber
	returnjson.table_List = result
	return true, returnjson;
end

_Register.getSchByparams = getSchByparams;

-----------------------------------------------------------------------------------------

--[[
	局部函数：获取行政区划
	作者： 	  陈续刚 		2015-08-28
	参数： 	  parentId  	父ID
	参数： 	  typeId  	    检索类型：1省2市3区
	返回值1： 行政区划的table
]]
local function getAreaData(parentId,typeId)
	local returnjson = {}
	local sql = "";
	if typeId == "1" then --获取省
		sql = "SELECT ID as area_id,PROVINCENAME as area_name FROM T_GOV_PROVINCE"
	elseif typeId == "2" then --获取市
		sql = "SELECT ID as area_id,CITYNAME as area_name FROM T_GOV_CITY WHERE PROVINCEID = "..parentId..""
	elseif typeId == "3" then --获取区
		sql = "SELECT ID as area_id,DISTRICTNAME as area_name FROM T_GOV_DISTRICT WHERE CITYID = "..parentId..""
	end
    
	local result = DBUtil: querySingleSql(sql)

	if not result then
		returnjson.success = false
	else
		returnjson.success = true
		returnjson.table_List = result
	end

	return returnjson;
end

_Register.getAreaData = getAreaData;
-----------------------------------------------------------------------------------------
--[[
	局部函数：根据检索条件获取用户信息
	作者： 	  陈续刚 		2015-08-26
	参数： 	  provinceId  	省ID
	参数： 	  cityId  	    市ID
	参数： 	  districtId  	区ID
	参数： 	  keyword  	    关键字
	参数： 	  register_flag 学校范围【0全部1系统2注册未审核3注册审核通过4注册审核不通过】
	返回值1： 学校的table
]]
local function getPersonData(provinceId,cityId,districtId,keyword,pageNumber,pageSize,register_flag)
	local returnjson = {}
	if keyword=="nil" or keyword=="" then
		keyword = ""
	else  --如果搜索关键字不为空就把传过来的base64进行编码转成真实的内容
		if #keyword~=0 then
			keyword = ngx.decode_base64(keyword)..""
		else
			keyword = ""
		end
	end
	
	local register_flag_sql = " and p.register_flag in(2)"
	local province_sql = ""
	local city_sql = ""
	local district_sql = ""
	if register_flag then
		if register_flag == 0 then
			register_flag_sql = " and p.register_flag in(1,2,3)"
		else
			register_flag_sql = " and p.register_flag ="..register_flag..""
		end
	end
	
	
	if provinceId ~= -1 then
		province_sql = " and p.province_id ="..provinceId..""
	end
	if cityId ~= -1 then
		city_sql = " and p.city_id ="..cityId..""
	end
	if districtId ~= -1 then
		district_sql = " and p.district_id ="..districtId..""
	end
    local base_sql = "select p.person_id,p.person_name,lp.login_name,p.register_flag,ifnull(pr.provincename,'--') as province_name,ifnull(c.cityname,'--') as city_name,ifnull(d.districtname,'--') as district_name from t_base_person p left join t_sys_loginperson lp on lp.person_id = p.person_id and lp.identity_id = p.identity_id left join t_base_organization o on o.bureau_id = p.org_id left join t_gov_province pr on pr.id = p.province_id left join t_gov_city c on c.id = p.city_id left join t_gov_district d on d.id = p.district_id where p.b_use=1 and p.check_state=1 and (p.person_name  like "..quote("%"..keyword.."%").." or p.tel  like "..quote("%"..keyword.."%").." or lp.login_name like "..quote("%"..keyword.."%").." or o.org_name like "..quote("%"..keyword.."%")..") "..province_sql..city_sql..district_sql..register_flag_sql.."  order by p.CREATE_TIME desc "
    
	--ngx.log(ngx.ERR, "cxg_log base_sql=====>"..base_sql.."==>");	
	local count_sql = "select p.person_id from t_base_person p left join t_sys_loginperson lp on lp.person_id = p.person_id and lp.identity_id = p.identity_id where p.b_use=1 and p.check_state=1 and (p.person_name  like "..quote("%"..keyword.."%").." or p.tel  like "..quote("%"..keyword.."%").." or lp.login_name like "..quote("%"..keyword.."%")..") "..province_sql..city_sql..district_sql..register_flag_sql..""
	
	local limit_sql = " limit "..pageSize*pageNumber-pageSize..","..pageSize
	local result = DBUtil: querySingleSql(base_sql..limit_sql)
	--ngx.log(ngx.ERR, "cxg_log getPersonData  count_sql=====>"..count_sql.."==>");	
	local count_result = DBUtil: querySingleSql(count_sql)
	
	if not result then
		return false, nil;
	end
	
	local totalRow = 0 
	if count_result then
		totalRow = #count_result
	end
	
	local totalPage = math.floor((totalRow + pageSize - 1) / pageSize)
	returnjson.success = true
	returnjson.totalPage = totalPage
	returnjson.totalRow = totalRow
	returnjson.pageSize = pageSize
	returnjson.pageNumber = pageNumber
	returnjson.table_List = result
	return true, returnjson;
end

_Register.getPersonData = getPersonData;

-----------------------------------------------------------------------------------------
--[[
	局部函数：审核注册的学校
	作者： 	  陈续刚 		2015-08-29
	参数： 	  orgId  	    学校ID
	参数： 	  auditStatus   学校范围【3注册审核通过4注册审核不通过】
	参数： 	  auditDesc  	描述
	返回值1： boolean 修改成功，失败
]]
local function auditOrgInfo(orgId,auditStatus,auditDesc)
	local base_sql = "update t_base_organization o set o.register_flag="..auditStatus.." where org_id="..orgId..""
	--ngx.log(ngx.ERR, "cxg_log sql=====>"..base_sql.."==>");	
	local result = DBUtil: querySingleSql(base_sql)
	--[[
		学校下的账号，已有数据怎么处理？？？？？？？？？？？
	]]
	
	if not result then
		return false;
	end

	return true;
end

_Register.auditOrgInfo = auditOrgInfo;

-----------------------------------------------------------------------------------------
--[[
	局部函数：修改密码
	作者： 	  陈续刚 		2015-08-31
	参数： 	  Ptype  	    1:手机号注册 2:其他方式
	参数： 	  loginName     登录名
	参数： 	  tel  	        手机号
	参数： 	  pwd  	        密码
	返回值1： boolean       
]]
local function setPwdByparams(Ptype,loginName,tel,pwd)
	local sql = ""
	local per_sql = ""
 
	if Ptype == "1" then
		sql = "update t_sys_loginperson lp set login_password="..quote(pwd).." where lp.login_Name = "..quote(tel).."" ;
		
		per_sql = "select person_id from t_sys_loginperson lp where  lp.login_Name = "..quote(tel).."" ;
		CacheUtil:hset("login_"..tel, "pwd", pwd)
	else
		sql = "update t_sys_loginperson lp set login_password="..quote(pwd).." where lp.login_Name = "..quote(loginName).."" ;
		
		per_sql = "select person_id from t_sys_loginperson lp where  lp.login_Name = "..quote(loginName).."" ;
		
		local person_sql = "update t_base_person p set p.tel = "..quote(tel).." where p.person_id in(select perosn_id from t_sys_loginperson lp where lp.login_Name ="..quote(loginName)..")"
		DBUtil: querySingleSql(person_sql);
		CacheUtil:hset("login_"..loginName, "pwd", pwd)
	end
	
	--ngx.log(ngx.ERR, "cxg_log pwd======================================>"..tel..pwd.."==>");	
	local result = DBUtil: querySingleSql(sql)

	
	if not result then
		return false;
	end
	return true;
end

_Register.setPwdByparams = setPwdByparams;

-----------------------------------------------------------------------------------------
--[[
	局部函数：修改密码时校验手机号
	作者： 	  陈续刚 		2015-08-31
	参数： 	  Ptype  	    1:手机号注册 2:其他方式
	参数： 	  loginName     登录名
	参数： 	  tel  	        手机号
	返回值1： boolean       
]]
local function checkTel(Ptype,loginName,tel)
	local sql1 = ""
	local sql2 = ""
 
	if tostring(Ptype) == "1" then --手机号注册用户
		sql1 = "select p.person_id from t_sys_loginperson lp left join t_base_person p on p.person_id = lp.person_id and p.identity_id = lp.identity_id  where p.register_flag !=1 and  lp.login_Name = "..quote(tel).."" ;
	else
		sql1 = "select person_id from t_sys_loginperson lp where lp.login_Name = "..quote(loginName).." " ;
		if loginName == tel then --其他用户，手机号跟用户名一致时(相当于手机号注册用户)
			sql2 = "select p.person_id from t_sys_loginperson lp left join t_base_person p on p.person_id = lp.person_id and p.identity_id = lp.identity_id  where p.register_flag !=1 and  lp.login_Name = "..quote(tel).."" ;
		else
			sql2 = "select p.person_id from t_sys_loginperson lp left join t_base_person p on p.person_id = lp.person_id and p.identity_id = lp.identity_id  where lp.login_Name = "..quote(tel).." " ;
		end
	end	
	--ngx.log(ngx.ERR, "cxg_log sql1=====>"..sql1.."==>");	
	local result1 = DBUtil: querySingleSql(sql1)

	--ngx.log(ngx.ERR, "cxg_log sql2=====>"..sql2.."==>");	
	if not result1 or #result1<=0 then--账号不存在
		return false,"账号不存在";
	else
		local result2 = DBUtil: querySingleSql(sql2)
		if loginName == tel then
			if not result2 or  #result2<=0 then--账号不存在
				return false,"账号不存在,请核对后重新输入";
			else 
				return true,"可以修改密码"
			end
		else
			if not result2 or  #result2<=0 then--账号不存在
				return true,"该手机号未被注册，可以修改密码。";
			else 
				return false,"该手机号已经注册，请直接登录。"
			end	
		end
		
	end
end

_Register.checkTel = checkTel;

-----------------------------------------------------------------------------------------
return _Register