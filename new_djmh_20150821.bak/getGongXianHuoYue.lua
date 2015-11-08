local request_method = ngx.var.request_method
local args = nil
if "GET" == request_method then
    args = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end

local cjson = require "cjson"

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

local gxOrg,gxUser,hyOgr,hyUser = ngx.location.capture_multi({
	{"/dsideal_yy/new_djmh/getGongXianOrg?bureau_id="..bureau_id.."&show_size="..show_size.."&random="..math.random(1000)},
	{"/dsideal_yy/new_djmh/getGongXianUser?bureau_id="..bureau_id.."&show_size="..show_size.."&random="..math.random(1000)},
	{"/dsideal_yy/new_djmh/getHuoYueOrg?bureau_id="..bureau_id.."&show_size="..show_size.."&random="..math.random(1000)},
	{"/dsideal_yy/new_djmh/getHuoYueUser?bureau_id="..bureau_id.."&show_size="..show_size.."&random="..math.random(1000)}
})

local result = {}
result["success"] = true
result["gxOrg"] = cjson.decode(gxOrg.body).list
result["gxUser"] = cjson.decode(gxUser.body).list
result["hyOgr"] = cjson.decode(hyOgr.body).list
result["hyUser"] = cjson.decode(hyUser.body).list

ngx.print(cjson.encode(result))