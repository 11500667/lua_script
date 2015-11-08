--[[   
    删除空间优秀.
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
    if not record_id or len(record_id)==0 then
       error()
    end
    return org_id,record_id
end

local function delete(record_id,org_id)
    local delSql = "delete from t_scoial_space_excellence where "
    delSql = delSql.."record_id="..quote(record_id).." and org_id ="..quote(org_id) 
    ngx.log(ngx.ERR,delSql);
    local res, err, errno, sqlstate = mysql:query(delSql)
    mysql:set_keepalive(0,v_pool_size)
    return res,err
end

local function deleteExcellent()
    local resResult = {}
    resResult.success = false
 
    local sta,org_id,record_id = pcall(getParams);
    if not sta then
        resResult.info="参数错误！"
        return cjson.encode(resResult)
    end

    ngx.log(ngx.ERR,sta)
    ngx.log(ngx.ERR,"org_id:"..org_id)
    ngx.log(ngx.ERR,"record_id:"..record_id)

    local result,err = delete(record_id,org_id)
    if not result then
        resResult.info="删除出错！"
        return cjson.encode(resResult)
    end
    resResult.success = true
    resResult.info = "成功"
    cjson.encode_empty_table_as_object(false)
    return cjson.encode(resResult)
end
say(deleteExcellent())