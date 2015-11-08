local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

local cjson = require "cjson"

ngx.log(ngx.ERR,"################")

--单位ID
if args["bureau_id"] == nil or args["bureau_id"] == "" then
    ngx.say("{\"success\":false,\"info\":\"bureau_id参数错误！\"}")
    return
end
local bureau_id = args["bureau_id"]

--显示多少条
if args["show_size"] == nil or args["show_size"] == "" then
    ngx.say("{\"success\":false,\"info\":\"show_size参数错误！\"}")
    return
end
local show_size = args["show_size"]



local xxWk,czWk,gzWk = ngx.location.capture_multi({
	{"/dsideal_yy/new_djmh/getWkdsInfo?bureau_id="..bureau_id.."&stage_id=4&subject_id=-1&pageSize="..show_size.."&pageNumber=1&random="..math.random(1000)},
	{"/dsideal_yy/new_djmh/getWkdsInfo?bureau_id="..bureau_id.."&stage_id=5&subject_id=-1&pageSize="..show_size.."&pageNumber=1&random="..math.random(1000)},
	{"/dsideal_yy/new_djmh/getWkdsInfo?bureau_id="..bureau_id.."&stage_id=6&subject_id=-1&pageSize="..show_size.."&pageNumber=1&random="..math.random(1000)}
})

local result = {}
result["success"] = true
result["xxWk"] = cjson.decode(xxWk.body).wk_list
result["czWk"] = cjson.decode(czWk.body).wk_list
result["gzWk"] = cjson.decode(gzWk.body).wk_list

cjson.encode_empty_table_as_object(false);
ngx.print(cjson.encode(result))


