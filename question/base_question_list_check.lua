#ngx.header.content_type = "text/plain;charset=utf-8"
local cookie_product_id = tostring(ngx.var.cookie_product_id)

--判断是否有person_id的cookie信息
if cookie_product_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"product_id的cookie信息参数错误！\"}")
    return
end


--连接redis服务器
local redis = require "resty.redis"
local cache = redis.new()
local ok,err = cache.connect(cache,v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

--获取check_status参数
local check_status = tostring(args["check_status"])
--判断check_status参数是否为空
if check_status == "nil" then
    ngx.say("{\"success\":false,\"info\":\"check_status参数错误！\"}")
    return
end

--获取version_id参数
local version_id = tostring(args["version_id"])
--判断version_id参数是否为空
if version_id == "nil" then
    ngx.say("{\"success\":false,\"info\":\"version_id参数错误！\"}")
    return
end

--获取version_id参数
local all_version_ids = tostring(args["all_version_ids"])
--判断version_id参数是否为空
if all_version_ids == "nil" then
    ngx.say("{\"success\":false,\"info\":\"all_version_ids参数错误！\"}")
    return
end



int version_id = getParaToInt("version_id");
String allVersionIds = getPara("all_version_ids");
if(check_status==null||check_status.length()==0)
    {
        check_status = "4";
    }
int product_id = Integer.parseInt(CookieUtil.getCookieByName(getRequest(), "product_id").getValue());
//当前是第几页
int pageNumber=getParaToInt("pageNumber");
int pageSize = getParaToInt("pageSize");


ngx.say("{\"success\":\"true\",\"totalRow\":\""..totalRow.."\",\"totalPage\":\""..totalPage.."\",\"pageNumber\":\""..pageNumber.."\",\"pageSize\":\""..pageSize.."\",\"list\":["..question_info.."]}")
