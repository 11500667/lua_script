

local mysql = require "resty.mysql"
local cjson = require "cjson"
local quote = ngx.quote_sql_str

local status = "SUCCESS"
local info = "操作成功"

local db, err = mysql:new()
if not db then
	status = "FAILURE"
	info = "failed to instantiate mysql: " .. err
    return
end

db:set_timeout(1000) -- 1 sec

local ok, err, errno, sqlstate = db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024*1024
}

if not ok then
    status = "FAILURE"
	info = "failed to connect: " .. err .. "：" .. errno .. " " .. sqlstate
    return
end

local request_method = ngx.var.request_method
local args,err
if request_method == "GET" then
    args,err = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args,err = ngx.req.get_post_args() 
end
if not args then 
    status = "FAILURE"
	info = err
end


local articletype_id = args["articletype_id"]
local articletype_param = args["articletype_param"]
local articletype_value = args["articletype_value"]


-- 防止SQL注入
--local select_sql = "select t.* from t_jy_topic t where t.topic_id=" .. business_id

local select_sql = "update T_BLOG_ARTICLETYPE  set " .. articletype_param .. " =" .. quote(articletype_value) .. "  where  articletype_id = " .. articletype_id


--执行插入
local select_res, err, errno, sqlstate = db:query(select_sql)
ngx.log(ngx.ERR, select_sql)
if not select_res then
	ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
	return
end


-- 归还到连接池
local ok, err = db:set_keepalive(0, v_pool_size)

if not ok then
    ngx.say("failed to set keepalive: ", err)
    return
end










