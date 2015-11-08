--[[
删除分类
@Author  feiliming
@Date    2015-7-14
]]

local say = ngx.say
local len = string.len
local quote = ngx.quote_sql_str

--require model
local cjson = require "cjson"
local mysqllib = require "resty.mysql"

--post args
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

local category_id = args["category_id"]
if not category_id or len(category_id) == 0 then
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

--检查是否有子分类
local ssql = "select * from t_social_notice_category where parent_id = "..quote(category_id).." and b_delete = 0"
local sr, err = mysql:query(ssql)
if not sr then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
if #sr > 0 then
    say("{\"success\":false,\"info\":\"该分类下有子分类禁止删除！\"}")
    return
end

--检查该分类下是否有新闻
--TODO 改成sphinx查询?
local ssql2 = "select * from t_social_notice where category_id = "..quote(category_id).." and b_delete = 0"
local sr2, err = mysql:query(ssql2)
if not sr2 then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
if #sr2 > 0 then
    say("{\"success\":false,\"info\":\"该分类下有相关内容禁止删除！\"}")
    return
end

local dsql = "update t_social_notice_category set b_delete = 1 where category_id = "..quote(category_id)
local dr, err = mysql:query(dsql)
if not dr then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--return
local rr = {}
rr.success = true

cjson.encode_empty_table_as_object(false)
say(cjson.encode(rr))

--release
mysql:set_keepalive(0,v_pool_size)