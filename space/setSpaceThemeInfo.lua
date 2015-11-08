--[[
保存主题、布局信息
@Author feiliming
@Date   2015-4-17
]]

local say = ngx.say
local len = string.len
local quote = ngx.quote_sql_str

--require model
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

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
local identity_id = args["identity_id"]
local theme_json = args["theme_json"]
if not person_id or len(person_id) == 0 or
    not identity_id or len(identity_id) == 0 or
    not theme_json then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end


--ssdb
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip,v_ssdb_port)
if not ok then
    say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end


ssdb:set("space_theme_info_"..person_id.."_"..identity_id, theme_json)

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)

say("{\"success\":true}")
