--[[

    获取空间管理的porlet数据

    @Author zhanghai

    @Date   2015-4-14

--]]
ngx.header.content_type = "text/plain;charset=utf-8"
local say = ngx.say
local len = string.len
local insert = table.insert
local quote = ngx.quote_sql_str


--require model
local mysqllib = require "resty.mysql"
local ssdblib = require "resty.ssdb"
local cjson = require "cjson"

--mysql
local mysql, err = mysqllib:new()
if not mysql then
	say("{\"success\":false,\"info\":\""..err.."\"}")
	return
end

local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
	say("{\"success\":false,\"info\":\""..err.."\"}")
	return
end

local ok, err = mysql:connect{
	host = v_mysql_ip,
	port = v_mysql_port,
	database = v_mysql_database,
	user = v_mysql_user,
	password = v_mysql_password,
	max_packet_size = 1024 * 1024 }
if not ok then
	say("{\"success\":false,\"info\":\""..err.."\"}")
	return
end

--get args
local getArgs = function()
	local request_method = ngx.var.request_method
	local args,err
	if request_method == "GET" then
		args,err = ngx.req.get_uri_args()
	else
		ngx.req.read_body()
		args,err = ngx.req.get_post_args()
	end
	return args
end


--获取参数

local getParams = function()
	local org_id = getArgs()["org_id"]
	local identity_id = getArgs()["identity_id"]
	local limit = getArgs()["limit"]
	local org_type = getArgs["type"]


	if not org_id or len(org_id)==0 then
		error()
	end
	if not org_type or len(org_type)==0 then
		error()
	end
	if not identity_id or len(identity_id)==0 then
		error()
	end
	if not limit or len(limit)==0 then
		error()
	end
	return org_id,org_type,identity_id,limit
end



local function getExcellence(org_id,org_type,limit)
	local querySql = "select t.record_id from t_social_space_excellence  t where t.org_id ="..quote(org_id).."and t.identityid="..quote(org_type).." limit "..limit
	local result, err = mysql:query(querySql)
	if not result then
		error()
	end
	--1,2
	return result
end


local function localSchoolList(ids,resResult,logo_urls)

	local schoolService = require "base.org.services.SchoolService";
	local util = require "space.util.util";

	local schoolPageList = schoolService:getSchoolByIds(ids);
	ngx.log(ngx.ERR,"cjson out=============>",cjson.encode(schoolPageList))
	util:logData(ids)
	if schoolPageList then
		for i=1,#schoolPageList do
			local restemp ={}
			restemp.name=schoolPageList[i].school_name
			restemp.id=schoolPageList[i].school_id
			restemp.stage_name=schoolPageList[i].stage_name
			--ngx.log(ngx.ERR,"ids===================================>schoolPageList[i].school_id::::",schoolPageList[i].school_id)
			restemp.logo_file_id=""
			for j=1,#ids do
			    -- ngx.log(ngx.ERR,"开始遍历 id::::",ids[j])
			    -- ngx.log(ngx.ERR,"ids===================================>ids[j]是否等于schoolPageList[i].school_id:  ",schoolPageList[i].school_id==ids[j])
			     if schoolPageList[i].school_id==ids[j] then
			      --  ngx.log(ngx.ERR,"ids===================================>logo_urls[j]:  ",logo_urls[j])
			        restemp.logo_file_id=logo_urls[j]
			        break;
			     end
			end
			table.insert(resResult.list,restemp)
		end
	end
end

local function localClassList(ids,resResult,logo_urls)

	local classService  = require "base.org.services.ClassService";
	local classPageList = classService:getClassByIds(ids);
	if classPageList then
		for i=1,#classPageList do
			local restemp ={}
			restemp.name=classPageList[i].class_name
			restemp.id=classPageList[i].class_id
			restemp.school_name=classPageList[i].school_name
		    restemp.logo_file_id=""
            for j=1,#ids do
                -- ngx.log(ngx.ERR,"开始遍历 id::::",ids[j])
                -- ngx.log(ngx.ERR,"ids===================================>ids[j]是否等于schoolPageList[i].school_id:  ",schoolPageList[i].school_id==ids[j])
                 if classPageList[i].class_id==ids[j] then
                  --  ngx.log(ngx.ERR,"ids===================================>logo_urls[j]:  ",logo_urls[j])
                    restemp.logo_file_id=logo_urls[j]
                    break;
                 end
            end
			table.insert(resResult.list,restemp)
		end
	end
end

local function localTeacherList(ids,resResult,logo_urls)

	local personService = require "base.person.services.PersonService";
	local personPageList = personService:getPersonByIds(ids);
	if personPageList then
		for i=1,#personPageList do
			local restemp={}
			restemp.name=personPageList[i].person_name
			restemp.id=personPageList[i].person_id
		    for j=1,#ids do
                -- ngx.log(ngx.ERR,"开始遍历 id::::",ids[j])
                -- ngx.log(ngx.ERR,"ids===================================>ids[j]是否等于schoolPageList[i].school_id:  ",schoolPageList[i].school_id==ids[j])
                 if personPageList[i].person_id==ids[j] then
                  --  ngx.log(ngx.ERR,"ids===================================>logo_urls[j]:  ",logo_urls[j])
                    restemp.logo_file_id=logo_urls[j]
                    break;
                 end
            end
			table.insert(resResult.list,restemp)
		end
	end
end
local function localStudentList(ids,resResult,logo_urls)
	ngx.log(ngx.ERR,"开始调用优秀学生.开始")
	local studentService  = require "base.student.services.StudentService";
	local studentPageList = studentService:getStudentByIds(ids);
	if studentPageList then
		for i=1,#studentPageList do
			local restemp={}
			restemp.name=studentPageList[i].student_name
			restemp.id=studentPageList[i].student_id
			for j=1,#ids do
                -- ngx.log(ngx.ERR,"开始遍历 id::::",ids[j])
                -- ngx.log(ngx.ERR,"ids===================================>ids[j]是否等于schoolPageList[i].school_id:  ",schoolPageList[i].school_id==ids[j])
                 if studentPageList[i].student_id==ids[j] then
                  --  ngx.log(ngx.ERR,"ids===================================>logo_urls[j]:  ",logo_urls[j])
                    restemp.logo_file_id=logo_urls[j]
                    break;
                 end
            end
			table.insert(resResult.list,restemp)
		end

	end
	cjson.encode_empty_table_as_object(false)
	ngx.log(ngx.ERR,"<=================================>",cjson.encode(resResult))
	ngx.log(ngx.ERR,"开始调用优秀学生.结束")
end

--获取json
local function getSpacePorletData()
	local resResult = {}
	resResult.success = false
	resResult.info = "成功"
	local request_method = ngx.var.request_method
	local args,err
	if request_method == "GET" then
		args,err = ngx.req.get_uri_args()
	else
		ngx.req.read_body()
		args,err = ngx.req.get_post_args()
	end
	local org_id = args["org_id"]
	local identity_id = args["identity_id"]
	local limit = args["limit"]
	local org_type = args["type"]


	if not org_id or len(org_id)==0 then
		resResult.info="org_id参数错误！"
		return cjson.encode(resResult)
	end
	if not org_type or len(org_type)==0 then
		resResult.info="org_type参数错误！"
		return cjson.encode(resResult)
	end
	if not identity_id or len(identity_id)==0 then
		resResult.info="identity_id参数错误！"
		return cjson.encode(resResult)
	end
	if not limit or len(limit)==0 then
		resResult.info="limit参数错误！"
		return cjson.encode(resResult)
	end

	local stat,queryResult = pcall(getExcellence,org_id,org_type,limit);

	--

	--      list：[{
	--         id：学校id
	--         name：学校名称
	--         type：1小学2初中3高中4完全中学5九年一贯6十二年一贯
	--         logo_file_id: Logo地址
	--     }]

	-- 1省2市3区县4校5分校6部门7班级

	resResult.list={}
	resResult.success = true
	if queryResult then
		local table_ids = {}
		local logo_urls = {}
		for i=1,#queryResult do
			local restemp = {}
			local info_key = ""
			local logo_url = ""
			if org_type =="1" then
				info_key ="space_ajson_orgbaseinfo_"..queryResult[i]["record_id"].."_104";
			elseif org_type=="2" then
				info_key ="space_ajson_orgbaseinfo_"..queryResult[i]["record_id"].."_105";
			elseif org_type=="3" then
				info_key ="space_ajson_personbaseinfo_"..queryResult[i]["record_id"].."_5";
			elseif org_type=="4" then
				info_key ="space_ajson_personbaseinfo_"..queryResult[i]["record_id"].."_6";
			end
			ngx.log(ngx.ERR,"SPACE_AJSON_ORGBASEINFO_KEY:",info_key)
			local logoResult = ssdb:get(info_key)
			
		
			if logoResult and logoResult[1] and string.len(logoResult[1])>0 then
				ngx.log(ngx.ERR,"json=============>",logoResult[1])
				local jsonObj= cjson.decode(logoResult[1])
				if org_type =="1" then
					logo_url = jsonObj.org_logo_fileid
				elseif org_type=="2" then
					logo_url = jsonObj.org_logo_fileid
				elseif org_type=="3" then
					logo_url = jsonObj.space_avatar_fileid
				elseif org_type=="4" then
					logo_url = jsonObj.space_avatar_fileid
				end
			end
			table.insert(table_ids,queryResult[i]["record_id"])
			table.insert(logo_urls,logo_url)
		end
		ngx.log(ngx.ERR,"table_ids=================================>",cjson.encode(table_ids))
		if table_ids and #table_ids>0 then
    		if org_type =="1" then
    			localSchoolList(table_ids,resResult,logo_urls)
    		elseif org_type=="2" then
    			localClassList(table_ids,resResult,logo_urls)
    		elseif org_type=="3" then
    			localTeacherList(table_ids,resResult,logo_urls)
    		elseif org_type=="4" then
    			localStudentList(table_ids,resResult,logo_urls)
    		end
    	end
	end
    ssdb:set_keepalive(0,v_pool_size)
	cjson.encode_empty_table_as_object(false)
	mysql:set_keepalive(0,v_pool_size)
	return cjson.encode(resResult)
end

say(getSpacePorletData())
