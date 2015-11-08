--
--    获取空间管理的porlet数据
--    @Author zhanghai
--    @Date   2015-4-14
--
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


local function getExcellence(org_id,org_type,identity)
	local querySql = "SELECT COUNT(ID) as totalRow FROM T_SOCIAL_SPACE_EXCELLENCE T WHERE T.ORG_ID ="..quote(org_id).."AND T.ORG_TYPE="..quote(org_type).." AND T.IDENTITYID="..quote(identity)
	ngx.log(ngx.ERR,"getExcellence query sql===>",querySql)
	local result, err = mysql:query(querySql)
	return result
end


local function loadSchooStatistic(org_id,org_type,resResult)
	local schoolService = require "base.org.services.SchoolService";
	local queryParam = {org_id=org_id,org_type=org_type,pageNumber=1,pageSize=2}
	local queryResult = schoolService:querySchoolByOrgWithPage(queryParam);
	ngx.log(ngx.ERR,"cjson out=============>",cjson.encode(queryResult))
	local _result_count = getExcellence(org_id,org_type,"1")
	resResult.school_excellence_total=_result_count[1].totalRow;
	if queryResult then
		resResult.school_total = queryResult.totalRow;
	end
end

local function loadClassStatistic(org_id,org_type,resResult)
	local classService  = require "base.org.services.ClassService";
	local queryParam = {org_id=org_id,org_type=org_type,pageNumber=1,pageSize=2}
	local queryResult = classService:queryClassByOrgWithPage(queryParam);
	local  _result_count = getExcellence(org_id,org_type,"2")
	resResult.class_excellence_total=_result_count[1].totalRow;
	if queryResult then
		resResult.class_total = queryResult.totalRow;

	end
end

local function loadTeacherStatistic(org_id,org_type,resResult)
	local personService = require "base.person.services.PersonService";
	local queryParam = {org_id=org_id,org_type=org_type,pageNumber=1,pageSize=2}
	local queryResult = personService:queryTeacherByOrgWithPage(queryParam);
	local _result_count = getExcellence(org_id,org_type,"3")
	resResult.teacher_excellence_total=_result_count[1].totalRow;
	if queryResult then
		resResult.teacher_total = queryResult.totalRow;
	end
end
local function loadStudentStatistic(org_id,org_type,resResult)
	local queryParam = {org_id=org_id,org_type=org_type,pageNumber=1,pageSize=2}
	local studentService  = require "base.student.services.StudentService";
	local queryResult = studentService:queryStudentByOrgWithPage(queryParam);
	local _result_count = getExcellence(org_id,org_type,"4")
	resResult.student_excellence_total=_result_count[1].totalRow;
	if queryResult then
		resResult.student_total = queryResult.totalRow;
	end
end

--获取json
local function getSpacePorletStatisData()
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
	local org_type = args["org_type"]


	ngx.log(ngx.ERR,"org_id============>",org_id);
	ngx.log(ngx.ERR,"org_type===========>",org_type);

	if not org_id or len(org_id)==0 then
		resResult.info="org_id参数错误！"
		return cjson.encode(resResult)
	end
	if not org_type or len(org_type)==0 then
		resResult.info="org_type参数错误！"
		return cjson.encode(resResult)
	end
	loadSchooStatistic(org_id,org_type,resResult)
	loadClassStatistic(org_id,org_type,resResult)
	loadTeacherStatistic(org_id,org_type,resResult)
	loadStudentStatistic(org_id,org_type,resResult)
	resResult.success = true
	cjson.encode_empty_table_as_object(false)
	mysql:set_keepalive(0,v_pool_size)
	return cjson.encode(resResult)
end

say(getSpacePorletStatisData())
