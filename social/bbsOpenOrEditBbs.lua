--[[
某地区开通或者编辑论坛
@Author feiliming
@Date   2015-3-21
]]

local say = ngx.say
local len = string.len
local quote = ngx.quote_sql_str

--require model
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"
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

local region_id = args["region_id"]
local region_type = args["region_type"]
local name = args["name"]
local logo_url = args["logo_url"]
local icon_url = args["icon_url"]
local domain = args["domain"]
local social_type = args["social_type"]
if not region_id or len(region_id) == 0 or
    not region_type or len(region_type) == 0 or
	not name or len(name) == 0 or
	--not logo_url or len(logo_url) == 0 or
	--not icon_url or
	not domain or
	not social_type or len(social_type) == 0 then
	say("{\"success\":false,\"info\":\"参数错误！\"}")
	return
end

--ssdb
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
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

--本来可以直接从ssdb取值进行判断，考虑ssdb稳定性，而且这是后台操作，前台接口从ssdb取值
local ssql = "select id from t_social_bbs where region_id = "..region_id
local sresult, err = mysql:query(ssql)
if not sresult then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--update
if sresult and #sresult > 0 then
    --update mysql
	local usql = "UPDATE t_social_bbs SET name = "..quote(name)..", logo_url = "..quote(logo_url)..
    ", icon_url = "..quote(icon_url)..", domain = "..quote(domain)..
    ", social_type = "..social_type.." WHERE region_id = "..region_id
    local uresult, err = mysql:query(usql)
    if not uresult then
        say("{\"success\":false,\"info\":\""..err.."\"}")
        return
    end
    --update ssdb
    local bbs_id = sresult[1].id
    local bbs = {}
    bbs.id = bbs_id
    bbs.region_id = region_id
    bbs.name = name
    bbs.logo_url = logo_url
    bbs.icon_url = icon_url
    bbs.domain = domain
    bbs.social_type = social_type
    ssdb:multi_hset("social_bbs_"..bbs_id, bbs)
    ssdb:hset("social_bbs_region_"..region_id, "bbs_id", bbs_id)

    --return
    local rr = {}
    rr.success = true
    rr.bbs = bbs
    cjson.encode_empty_table_as_object(false)
    say(cjson.encode(rr))

    --release
    ssdb:set_keepalive(0,v_pool_size)
    mysql:set_keepalive(0,v_pool_size)
    return
end

--insert
local bbs_id = ssdb:incr("social_bbs_pk")[1]

local isql = "insert into t_social_bbs(id,region_id,region_type,name,logo_url,icon_url,domain,social_type) values("..
	bbs_id..","..region_id..","..region_type..","..quote(name)..","..quote(logo_url)..
    ","..quote(icon_url)..","..quote(domain)..","..social_type..")"

--insert mysql
local iresult, err = mysql:query(isql)
if not iresult then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--insert ssdb
local bbs = {}
bbs.id = bbs_id
bbs.region_id = region_id
bbs.region_type = region_type
bbs.name = name
bbs.logo_url = logo_url
bbs.icon_url = icon_url
bbs.domain = domain
bbs.status = 0
bbs.social_type = social_type
bbs.post_today = 0
bbs.post_yestoday = 0
bbs.total_topic = 0
bbs.total_post = 0
ssdb:multi_hset("social_bbs_"..bbs_id, bbs)
ssdb:hset("social_bbs_region_"..region_id, "bbs_id", bbs_id)

--return
local rr = {}
rr.success = true
rr.bbs = bbs
cjson.encode_empty_table_as_object(false)
say(cjson.encode(rr))

--release
ssdb:set_keepalive(0,v_pool_size)
mysql:set_keepalive(0,v_pool_size)

