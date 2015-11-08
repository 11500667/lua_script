--[[   
    设置空间优秀.
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

local getParams = function()
    local org_id = getArgs()["org_id"]
    local org_type = getArgs()["org_type"]
    local record_id = getArgs()["record_id"]
    if not org_id or len(org_id)==0 then
       error()
    end
    if not org_type or len(org_type)==0 then
       error()
    end
    if not record_id or len(record_id)==0 then
       error()
    end
    local province_id = getArgs()["province_id"]
    local city_id = getArgs()["city_id"]
    local district_id = getArgs()["district_id"]

    if not province_id or len(province_id)==0 then
       error()
    end
    if not city_id or len(city_id)==0 then
       error()
    end
    if not district_id or len(district_id)==0 then
       error()
    end

    return org_id,org_type,record_id,province_id,city_id,district_id
end

local function save(record_id,org_id,org_type,province_id,city_id,district_id)
    local saveSql = "INSERT INTO t_social_space_excellence (record_id, org_id, org_type,provinceid,cityid,districtid) VALUES "
    saveSql = saveSql .. string.format("(%s,%s,%s,%s,%s,%s)", quote(record_id), quote(org_id), quote(org_type),quote(province_id),quote(city_id),quote(district_id))
    ngx.log(ngx.ERR,saveSql);
    local res, err, errno, sqlstate =mysql:query(saveSql)
    mysql:set_keepalive(0,v_pool_size)
    return res,err
end

local function saveExcellent()
    local resResult = {}
    resResult.success = false
 
    local sta,org_id,org_type,record_id,province_id,city_id,district_id = pcall(getParams);
    if not sta then
        resResult.info="参数错误！"
        return cjson.encode(resResult)
    end

    ngx.log(ngx.ERR,sta)
    ngx.log(ngx.ERR,"org_id:"..org_id)
    ngx.log(ngx.ERR,"org_type:"..org_type)
    ngx.log(ngx.ERR,"record_id:"..record_id)

    local result,err = save(record_id,org_id,org_type,province_id,city_id,district_id)
    if not result then
        resResult.info="保存出错！"
        return cjson.encode(resResult)
    end
    resResult.success = true
    resResult.info = "成功"
    cjson.encode_empty_table_as_object(false)
    return cjson.encode(resResult)
end

say(saveExcellent())