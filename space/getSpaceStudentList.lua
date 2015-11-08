--[[   
    获取空间管理的学生数据.
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
local cjson = require "cjson"

--mysql
local mysql, err = mysqllib:new()
if not mysql then
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
-- org_id：机构id，从这个节点往下取
-- org_type：机构类型，1省2市3区县4校5分校6部门7班级
-- school_type：1小学2初中3高中4完全中学5九年一贯6十二年一贯
-- school_name：base64和URL编码的学校名称，模糊查询
-- pageNumber：当前页
-- pageSize：每页条数
--
local getParams = function()
    local args=getArgs()
    local org_id = args["org_id"]
    local org_type = args["org_type"]
    local class_type = args["class_type"]
    local pageNumber = args["pageNumber"]
    local pageSize = args["pageSize"]
    local district = args["district"]
    local province = args["province"]
    local city = args["city"]
    local school = args["school"]
    local class = args["class"]
    local student_name = args["student_name"]

    if not org_id or len(org_id)==0 then
       error()
    end
    -- if not org_type or len(org_type)==0 then
    --    error()
    -- end
    if not province or len(province)==0 then
        province="0"
    end
    if not district or len(district)==0 then
        district="0"
    end
    if not city or len(city)==0 then
        city="0"
    end
    if not school or len(school)==0 then
        school="0"
    end
    if not class or len(class)==0 then
        class="0"
    end
    -- if not school_type or len(school_type)==0 then
    --    error()
    -- end
    if student_name and len(student_name)~=0 then
       student_name = ngx.decode_base64(student_name)
    end
    if not pageNumber or len(pageNumber)==0 then
       error()
    end
    if not pageSize or len(pageSize)==0 then
       error()
    end
    return org_id,org_type,class_type,student_name,province,city,district,school,class,pageNumber,pageSize
end


-- CREATE TABLE `t_scoial_space_excellence` (
--     `ID` INT(11) NOT NULL AUTO_INCREMENT COMMENT 'id',
--     `record_id` INT(11) NOT NULL COMMENT '记录id',
--     `org_id` INT(11) NOT NULL COMMENT '机构id用户登录时取的机构',
--     `org_type` INT(11) NOT NULL COMMENT '机构类型1省2市3区县4校',
--     PRIMARY KEY (`ID`)
-- )
-- id  record_id   org_id   org_type
-- 1    1            1        1
-- 2    2            1        1
--1省2市3区县4校5分校6部门7班级
--显示省市区
local function getExcellence(record_id)
    local querySql = "select ifnull(group_concat(t.org_type),0) as org_type from t_social_space_excellence t where t.record_id="..record_id
    local result, err = mysql:query(querySql)
    if not result then
        error()
    end
    --1,2
    return result
end


local function convertTableToString(t)
    local str = ""
    if not t or table.getn(t)==0 then return str  end 
 
    for i=1,#t do
        if i<table.getn(t) then
            str = str..t[i]..","
        else
            str = str..t[i]
        end
    end
    return str
end

local function arraySort(arrays)
    local t = {}
    if arrays and #arrays>0 then
        for i=1,#arrays do
            table.insert(t,arrays[i]);
        end
    end
    table.sort(t)
    return t;
end


local function getExcellenceQuery(org_id,org_type,province,city,district,school,class,pageNumber,pageSize)
    local queryCountSql="SELECT count(*) as totalRow FROM (SELECT t.id,t.record_id,t.org_id, GROUP_CONCAT(t.org_type) AS org_type FROM t_social_space_excellence t WHERE 1=1 and t.identityid = 4"
    --local querySql = "select record_id,org_type from (select t.id,t.record_id,t.org_id ,group_concat(t.org_type) as org_type from t_scoial_space_excellence t group by record_id) t1 where t1.org_id="..org_id.." and t1.org_type="
    local querySql = "SELECT record_id,org_type,org_id FROM (SELECT t.id,t.record_id,t.org_id, GROUP_CONCAT(t.org_type) AS org_type FROM t_social_space_excellence t WHERE 1=1 and t.identityid = 4"
    local whereIdSql = ""

    if org_type == "1" then
        whereIdSql = " AND t.provinceid="..org_id
    elseif  org_type == "2" then
        whereIdSql = " AND t.cityid="..org_id
    elseif org_type == "3" then
        whereIdSql = " AND t.districtid="..org_id
    elseif org_type== "4" then
        whereIdSql = " AND t.schoolid="..org_id
    elseif org_type== "5" then
        whereIdSql = " AND t.classid="..org_id
    end

    local whereSql = " AND t.org_type in ("
    local t = {}
   -- local tabs = {}
    if province=="1" then
       table.insert(t,1)
    end
    if city=="1" then
       table.insert(t,2)
    end
    if district=="1" then
       table.insert(t,3)
    end
    if school=="1" then
       table.insert(t,4)
    end
    if class=="1" then
       table.insert(t,5)
    end
    whereSql = whereSql ..convertTableToString(t)..")"
    if province=="0" and city=="0" and  district=="0" and school=="0" and class=="0" then whereSql="" end
    local  groupSql = " GROUP BY record_id) t1"
    querySql=querySql..whereIdSql..whereSql..groupSql
    queryCountSql=queryCountSql..whereIdSql..whereSql..groupSql
    ngx.log(ngx.ERR,"queryCountSql=================",queryCountSql)
    local count,err1 = mysql:query(queryCountSql)
    ngx.log(ngx.ERR,"count[1].totalRow=================",count[1].totalRow)


    local totalRow = count[1].totalRow
    local totalPage = math.floor((totalRow + pageSize - 1) / pageSize)
    local offset = pageSize*pageNumber - pageSize
    local limit = pageSize
    querySql = querySql.." LIMIT "..offset..","..pageSize

    ngx.log(ngx.ERR,"querySql:"..querySql)
    local result, err = mysql:query(querySql)
    
    return result,totalRow,totalPage,err
end




-- 从接口中取出进行迭代
local function iteratorData(queryResult,resResult,orgType,pageNumber,pageSize)
     if queryResult then
        ngx.log(ngx.ERR,"for start..............",cjson.encode(queryResult))
        resResult.pageSize = queryResult.pageSize;
        resResult.pageNumber = queryResult.pageNumber;
        resResult.totalPage = queryResult.totalPage;
        resResult.totalRow = queryResult.totalRow;
        resResult.student_list={}
        local studentlist = queryResult.student_list;
        if studentlist~=nil and #studentlist>0 then
            ngx.log(ngx.ERR,"for start.......studentlist.......",cjson.encode(queryResult))
            for j=1,#studentlist do
                local resTempStudentResult = {}
                resTempStudentResult.class_id = studentlist[j].class_id
                resTempStudentResult.class_name = studentlist[j].class_name
                resTempStudentResult.class_type = studentlist[j].class_type
                resTempStudentResult.province_id=studentlist[j].province_id
                resTempStudentResult.city_id = studentlist[j].city_id
                resTempStudentResult.district_id = studentlist[j].district_id
                resTempStudentResult.school_id = studentlist[j].school_id;
                resTempStudentResult.school_name = studentlist[j].school_name;
                resTempStudentResult.student_id = studentlist[j].student_id;
                resTempStudentResult.student_name = studentlist[j].student_name;
                local status,studentRes = pcall(getExcellence,studentlist[j].student_id)
                resTempStudentResult.excellent_group = {}
                if studentRes~=nil and #studentRes>0 then
                     if studentRes[1].org_type~="0" then
                        resTempStudentResult.excellent_group = arraySort(Split(studentRes[1].org_type,","));
                     end
                end
                table.insert(resResult.student_list,resTempStudentResult)
            end
        end
        cjson.encode_empty_table_as_object(false)
        ngx.log(ngx.ERR,"resResult:======================>",cjson.encode(resResult))
     else
        resResult.student_list={}
        resResult.pageSize = pageSize;
        resResult.pageNumber = pageNumber;
        resResult.totalPage = 0;
        resResult.totalRow =0;
     end
end

local function iteratorStudentPageList(queryResult,org_type,resResult,excellent_group,totalRow,totalPage,pageNumber,pageSize)
     ngx.log(ngx.ERR,"iteratorStudentPageList:======================>",cjson.encode(queryResult))
     if queryResult and queryResult~=nil then
            resResult.pageSize = pageSize;
            resResult.pageNumber = pageNumber;
            resResult.totalPage = totalPage;
            resResult.totalRow =totalRow;
            resResult.student_list={}
            for j=1,#queryResult do
                local resTempStudentResult = {}
                resTempStudentResult.class_id = queryResult[j].class_id
                resTempStudentResult.class_name = queryResult[j].class_name
                resTempStudentResult.class_type = queryResult[j].class_type
                resTempStudentResult.province_id=queryResult[j].province_id
                resTempStudentResult.city_id = queryResult[j].city_id
                resTempStudentResult.district_id = queryResult[j].district_id
                resTempStudentResult.school_id = queryResult[j].school_id;
                resTempStudentResult.school_name = queryResult[j].school_name;
                resTempStudentResult.student_id = queryResult[j].student_id;
                resTempStudentResult.student_name = queryResult[j].student_name;
                ngx.log(ngx.ERR,"excellent_group:=start========================================>",cjson.encode(org_type[j]))
                resTempStudentResult.excellent_group = arraySort(Split(org_type[j],","));
                --ngx.log(ngx.ERR,"excellent_group:=start==end======================================>",cjson.encode(resTempSchoolResult.excellent_group))
                table.insert(resResult.student_list,resTempStudentResult)
            end
    end
end

--获取json
local function getSpaceStudentData()
    local resResult = {}
    resResult.success = false
    resResult.info = "成功"

    local sta,org_id,org_type,class_type,student_name,province,city,district,school,class,pageNumber,pageSize = pcall(getParams);

    if not sta then
        resResult.info="参数错误！"
        return cjson.encode(resResult)
    end
    ngx.log(ngx.ERR,sta)
    local queryParam = {org_id=org_id,org_type=org_type,student_name=student_name,pageNumber=pageNumber,pageSize=pageSize}
    local studentService  = require "base.student.services.StudentService";
    if province=="0" and district=="0" and city=="0" and school=="0" and class=="0" then

        local queryResult = studentService:queryStudentByOrgWithPage(queryParam);

        cjson.encode_empty_table_as_object(false)
        ngx.log(ngx.ERR,"返回数据：",cjson.encode(queryResult))
        if not queryResult then
            resResult.info="接口调用返回错误！"
            return cjson.encode(resResult)
        end

        iteratorData(queryResult,resResult,org_type,pageNumber,pageSize)--查询全部调用接口

        ngx.log(ngx.ERR,"返回resResult：",cjson.encode(resResult))
    else

        local ids,totalRow,totalPage,err = getExcellenceQuery(org_id,org_type,province,city,district,school,class,pageNumber,pageSize)
        if ids~=nil and #ids>0 then
            ngx.log(ngx.ERR,"============",cjson.encode(ids))
            local id_table = {}
            local org_typet = {}
            for i=1,#ids do
                table.insert(id_table,ids[i]['record_id'])
                table.insert(org_typet,ids[i]['org_type'])
            end
            
            local studentPageList = studentService:getStudentByIds(id_table);
            if not studentPageList then
                resResult.info="接口调用返回错误！"
                return cjson.encode(resResult)
            end
            --调用接口，传ids tables.
            iteratorStudentPageList(studentPageList,org_typet,resResult,org_type,totalRow,totalPage,pageNumber,pageSize)
        else
            resResult.student_list={}
            resResult.pageSize = pageSize;
            resResult.pageNumber = pageNumber;
            resResult.totalPage = 0;
            resResult.totalRow =0;
        end
    end
    resResult.success = true
    cjson.encode_empty_table_as_object(false)
    mysql:set_keepalive(0,v_pool_size)
    return cjson.encode(resResult)
end

say(getSpaceStudentData())
