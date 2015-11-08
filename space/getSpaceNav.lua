--[[   
    通过ssdb key获取空间菜单的json数据.
    @Author zhanghai
    @Date   2015-4-14
--]]
ngx.header.content_type = "text/plain;charset=utf-8"
local say = ngx.say
local len = string.len

--require model
local ssdb = require "resty.ssdb"
local cjson = require "cjson"
local cache = ssdb:new()
local ok,err = cache:connect(v_ssdb_ip,v_ssdb_port)
if not ok then
    say("{\"success\":\"false\",\"info\":\""..err.."\"}")
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
--检查参数
local checkParams = function()
    for k,v in pairs(getArgs()) do
        ngx.log(ngx.ERR,k..":"..v)
        if not v or len(v) == 0 then
           return false
        end
    end
    return true
end
--获取参数
local getParams = function()
    if not checkParams() then
        error()
    end
    local space_type = getArgs()["space_type"]
    local person_id = getArgs()["person_id"]
    local identity_id = getArgs()["identity_id"]
    return space_type,person_id,identity_id
end

--获取json
local function getJson()
    local rr = {}
    rr.success = false
    rr.info = "成功"
    local status,space_type,person_id,identity_id = pcall(getParams)
    if status==false then
        rr.info = "参数错误!"
        return cjson.encode(rr)
    end
    local ssdb_space_nav_key = "space_nav_"..space_type.."_"..person_id.."_"..identity_id
    local jsonStr,err = cache:get(ssdb_space_nav_key)
    if not jsonStr then
        rr.info = err
        return cjson.encode(rr)
    end
    rr.success = true
    local j = {}
    if jsonStr and jsonStr[1] and len(jsonStr[1])>0 then
        j = cjson.decode(jsonStr[1])
    end
    rr.json = j
    ssdb:set_keepalive(0,v_pool_size)
    --say(err)
    cjson.encode_empty_table_as_object(false)
    return cjson.encode(rr)
end


say(getJson())
