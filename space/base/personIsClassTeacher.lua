--[[
判断person_id是否班主任
@Author  feiliming
@Date    2015-4-26
]]
local say = ngx.say
local len = string.len
local quote = ngx.quote_sql_str

--require model
local cjson = require "cjson"
local mysqllib = require "resty.mysql"

--get args
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

local person_id = args["person_id"]
if not person_id or len(person_id) == 0 then
	say("{\"success\":false,\"info\":\"参数错误！\"}")
	return
end

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

--select
local sql = "SELECT class_id,class_name FROM t_base_class t WHERE BZR_ID = "..quote(person_id).." LIMIT 0,1000"
local list = mysql:query(sql)
if not list then
    say("{\"success\":false,\"info\":\"查询失败！\"}")
    return
end 

--return
local rr = {}
rr.success = true
rr.isClassTeacher = false

local class_list = {}
if list and #list > 0 then
    rr.isClassTeacher = true
    for i=1,#list do
	    local t = {}
	    t.class_id = list[i].class_id
        t.class_name = list[i].class_name
        table.insert(class_list, t)
    end
end

rr.class_list = class_list

cjson.encode_empty_table_as_object(false)
say(cjson.encode(rr))

--release
mysql:set_keepalive(0,v_pool_size)