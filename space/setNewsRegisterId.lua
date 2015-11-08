--[[
保存注册号
@Author feiliming
@Date   2015-4-23
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

--args
local a_id = args["a_id"]
local a_identity_id = args["a_identity_id"]
local register_id = args["regist_id"]

if not a_id or len(a_id) == 0
    or not a_identity_id or len(a_identity_id) == 0
    or not register_id or len(register_id) == 0 then
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

--exist
local sql = "SELECT register_id FROM t_social_news_register WHERE a_id = "..quote(a_id).." AND a_identity_id = "..quote(a_identity_id)
local qresult, err = mysql:query(sql)
if not qresult then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local usql = ""
if qresult and qresult[1] and qresult[1].register_id then
    usql = "UPDATE t_social_news_register SET register_id = "..quote(register_id).." WHERE a_id = "..a_id.." AND a_identity_id = "..quote(a_identity_id)
else
    usql = "INSERT INTO t_social_news_register(a_id,a_identity_id,register_id) VALUES("..quote(a_id)..","..quote(a_identity_id)..","..quote(register_id)..")"
end
local uresult, err = mysql:query(usql)
if not uresult then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local rr = {}
rr.success = true
rr.info = "成功！"

say(cjson.encode(rr))
mysql:set_keepalive(0,v_pool_size)