local cookie_person_id = tonumber(ngx.var.cookie_person_id)
local cookie_identity_id = tonumber(ngx.var.cookie_identity_id)

--判断request类型
local request_method = ngx.var.request_method
local args,err
if request_method == "GET" then
    args,err = ngx.req.get_uri_args()
else
    --get_post_args()这个方法依赖于通过先调用ngx.req.read_body()方法先读取请求的body或者打开lua_need_request_body指令(设置lua_need_request_body为on), 否则将会抛出异常错误. 
    ngx.req.read_body()
    args,err = ngx.req.get_post_args() 
end
if not args then 
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end


--获得请求参数
local resIdInt = args["resource_id_int"]

if resIdInt==nil or resIdInt=="" then
	ngx.say("{\"success\":false,\"info\":\"参数resource_id_int不能为空！\"}")
	return
elseif not tonumber(resIdInt) then
	ngx.say("{\"success\":false,\"info\":\"参数resource_id_int只能为数字！\"}")
	return
end

local cjson = require "cjson"
local redis = require "resty.redis"
local mysql = require "resty.mysql"
local db, err = mysql : new();
if not db then 
	ngx.say("{\"success\":false,\"info\":\"获取数据库连接出错！\"}")
	ngx.log(ngx.ERR, "获取数据库连接出错，错误信息：" .. err);
	return;
end

db:set_timeout(1000) -- 1 sec

local ok, err, errno, sqlstate = db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024 * 1024 
}

if not ok then
    ngx.log(ngx.ERR, "failed to connect: ", err, ": ", errno, " ", sqlstate)
    ngx.say("{\"success\":false,\"info\":\"连接数据库服务器出错！\"}")
    return
end

--连接SSDB
local ssdb = require "resty.ssdb"
local ssdb_db = ssdb:new()
local ok, err = ssdb_db:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local sql_queryStruc = "SELECT SQL_NO_CACHE ID FROM T_RESOURCE_INFO_SPHINXSE WHERE QUERY='filter=resource_id_int," .. resIdInt ..";filter=group_id,2' limit 1"

local results, err, errno, sqlstate = db:query(sql_queryStruc);

if not results then
    ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".")
    ngx.say("{\"success\":false,\"info\":\"获取试题上传人出错！\"}")
    return
end 

if #results==0 then
	ngx.log(ngx.ERR, "resource_id_int为" .. resIdInt .. "的资源不存在！")
    ngx.say("{\"success\":false,\"info\":\"记录不存在！\"}")
    return
end

local red = redis:new()
red:set_timeout(1000) -- 1 sec

local redis_ok, redis_err = red:connect(v_redis_ip, v_redis_port)
if not redis_ok then
    ngx.log(ngx.ERR, "failed to connect: ", redis_err)
    ngx.say("{\"success\":false,\"info\":\"连接缓存服务器出错！\"}")
    return
end

local isCurrentUser = 0

if results[1]["ID"]~=ngx.null then
	local infoId = results[1]["ID"]
	local resRecord = ssdb_db:multi_hget("resource_" .. infoId, "person_id", "identity_id")

	if resRecord~=ngx.null then
		local person_id = tonumber(resRecord[2])
		local identity_id = tonumber(resRecord[4])

		if person_id==cookie_person_id and identity_id==cookie_identity_id then
			isCurrentUser = 1
		end
	end
else
	ngx.log(ngx.ERR, "获取资源的ID为空")
    ngx.say("{\"success\":false,\"info\":\"获取资源的ID出错！\"}")
    return
end

local resultJsonObj = {}
resultJsonObj.success = true
resultJsonObj.is_self = isCurrentUser

local resultJsonStr = cjson.encode(resultJsonObj)
ngx.say(resultJsonStr)


-- 将redis连接归还连接池
local ok, err = red:set_keepalive(0, v_pool_size);
if not ok then
    ngx.log(ngx.ERR, "failed to set keepalive: ", err)
    return
end

-- 将mysql连接归还到连接池
local ok, err = db:set_keepalive(0, v_pool_size);
if not ok then
    ngx.log(ngx.null, "failed to set keepalive: ", err)
    return
end

--放回到SSDB连接池
local ok, err = ssdb_db:set_keepalive(0, v_pool_size);
if not ok then
    ngx.log(ngx.null, "failed to set keepalive: ", err)
    return
end

