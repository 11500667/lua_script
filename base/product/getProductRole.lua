#lzy 2015-3-28
local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end
--[[
--person_id
if args["person_id"] == nil or args["person_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"person_id参数错误！\"}")
    return
end
local person_id = args["person_id"]

if args["identity_id"] == nil or args["identity_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"identity_id参数错误！\"}")
    return
end
local identity_id = args["identity_id"]

]]
if args["subject_ids"] == nil or args["subject_ids"] == "" then
    ngx.say("{\"success\":false,\"info\":\"subject_ids参数错误！\"}")
    return
end
local subject_ids = args["subject_ids"]

--连接redis服务器
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end
local cjson = require "cjson"
--[[
local unit_id = cache:hget("person_"..person_id.."_"..identity_id,"qu");


local response = ngx.location.capture("/dsideal_yy/ypt/multiCheck/getSubjectByPerson", {
	method = ngx.HTTP_POST,
	body = "unit_id="..unit_id.."&person_id="..person_id.."&identity_id="..identity_id

});
local cjson = require "cjson"
local personJsonObj;
if response.status == 200 then
    ngx.log(ngx.ERR,"response.body=="..response.body);
    personJsonObj = cjson.decode(response.body).subject_List
else
	ngx.print("{\"success\":false,\"info\":\"查询学科信息失败！\"}")
    return
end
local subject_ids="";
for i=1, #personJsonObj do
	local subject_id= personJsonObj[i]["SUBJECT_ID"];
	 subject_ids = subject_ids..","..subject_id
end
if #subject_ids>1 then

subject_ids = string.sub(subject_ids,2,#subject_ids)
end
]]
--连接数据库
local mysql = require "resty.mysql"
local db = mysql:new()
db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024*1024
}
local sql = "SELECT t1.PRODUCT_ID,t1.PRODUCT_NAME,t3.ROLE_ID,t1.SUBJECT_ID,t1.STAGE_ID FROM t_pro_product AS t1 INNER JOIN t_base_role_product AS t2 ON t1.PRODUCT_ID = t2.PRODUCT_ID INNER JOIN t_sys_role AS t3  ON t3.role_Id = t2.role_id WHERE t1.SUBJECT_ID in ("..subject_ids..") AND PLATFORM_ID = 1 GROUP BY t1.PRODUCT_ID";

local subject_res= db:query(sql);

local result = {}
result["success"] = true
result["list"] = subject_res

cjson.encode_empty_table_as_object(false);
-- 将redis连接归还到连接池
local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
    ngx.log(ngx.ERR, "====>将Redis连接归还连接池出错！");
end

ngx.say(cjson.encode(result))


