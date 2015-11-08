local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

--bureau_id参数 单位ID
if args["bureau_id"] == nil or args["bureau_id"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"bureau_id参数错误！\"}")
	return
end
local bureau_id = args["bureau_id"]

--show_size参数 显示多少条
if args["show_size"] == nil or args["show_size"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"show_size参数错误！\"}")
	return
end
local show_size = args["show_size"]

--res_type类型 1：资源  2：备课  4：试卷  5：微课
if args["res_type"] == nil or args["res_type"] == "" then 
	ngx.print("{\"success\":false,\"info\":\"res_type参数错误！\"}")
	return
end
local res_type = args["res_type"]

local cjson = require "cjson"

local NewRes,HotRes = ngx.location.capture_multi({
	{"/dsideal_yy/new_djmh/getNewResource?bureau_id="..bureau_id.."&stage_id=-1&show_size="..show_size.."&res_type="..res_type.."&random="..math.random(1000)},
	{"/dsideal_yy/new_djmh/getHotResource?&bureau_id="..bureau_id.."&stage_id=-1&show_size="..show_size.."&res_type="..res_type.."&random="..math.random(1000)}
})

local result = {}
result["success"] = true
result["NewRes"] = cjson.decode(NewRes.body).list
result["HotRes"] = cjson.decode(HotRes.body).list

ngx.print(cjson.encode(result))
