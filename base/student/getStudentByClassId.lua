local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--班级ID
if args["class_id"] == nil or args["class_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"class_id参数错误！\"}")
    return
end
local class_id = ngx.quote_sql_str(args["class_id"])

local cjson = require "cjson"

--连接数据库
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

local student_res= db:query("SELECT student_id,student_name,'0' as userPhoto FROM t_base_student WHERE B_USE=1 AND CLASS_ID="..class_id)
local student_info = student_res

--调用空间接口取基本信息
local personIds = {}
for i=1,#student_info do
    table.insert(personIds, student_info[i].student_id)
end
local aService = require "space.services.PersonAndOrgBaseInfoService"
local rt = aService:getPersonBaseInfo("6", unpack(personIds))
for i=1,#student_info do
    for _, v in ipairs(rt) do
        if tostring(student_info[i].student_id) == tostring(v.personId) then
            student_info[i].avatar_fileid = v and v.avatar_fileid or ""
            --teacherlist[i].description = v and v.person_description or ""
            break
        end
    end
end


local result = {}
result["success"] = true
result["list"] = student_info

cjson.encode_empty_table_as_object(false);
ngx.say(cjson.encode(result))

