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

local cjson = require "cjson"

local result = {}

--[[
--获取该单位下所有资源中的最新资源
local newRes = ngx.location.capture("/dsideal_yy/djmh/getNewResByBurea?bureau_id="..bureau_id.."&show_size="..show_size.."&random="..math.random(1000),{max_body_size=40960})
local newRes_str = newRes.body
local newRes_info = cjson.decode(newRes_str)

--获取该单位下小学资源中的最新资源
local newXxRes = ngx.location.capture("/dsideal_yy/djmh/getNewResByBureauStageSubject?bureau_id="..bureau_id.."&show_size="..show_size.."&stage_id=4&subject_id=-1&random="..math.random(1000),{max_body_size=40960})
local newXxRes_str = newXxRes.body
local newXxRes_info = cjson.decode(newXxRes_str)

--获取该单位下初中资源中的最新资源
local newCzRes = ngx.location.capture("/dsideal_yy/djmh/getNewResByBureauStageSubject?bureau_id="..bureau_id.."&show_size="..show_size.."&stage_id=4&subject_id=-1&random="..math.random(1000),{max_body_size=40960})
local newCzRes_str = newCzRes.body
local newCzRes_info = cjson.decode(newCzRes_str)

--获取该单位下高中资源中的最新资源
local newGzRes = ngx.location.capture("/dsideal_yy/djmh/getNewResByBureauStageSubject?bureau_id="..bureau_id.."&show_size="..show_size.."&stage_id=4&subject_id=-1&random="..math.random(1000),{max_body_size=40960})
local newGzRes_str = newGzRes.body
local newGzRes_info = cjson.decode(newGzRes_str)

result["success"] = true
result["newRes"] = newRes_info.list
result["newXxRes"] = newXxRes_info.list
result["newCzRes"] = newCzRes_info.list
result["newGzRes"] = newGzRes_info.list
]]



local newRes,newXxRes,newCzRes,newGzRes,ActiveBureau = ngx.location.capture_multi({
	{"/dsideal_yy/djmh/getNewResByBurea?bureau_id="..bureau_id.."&show_size="..show_size.."&random="..math.random(1000)},
	{"/dsideal_yy/djmh/getNewResByBureauStageSubject?bureau_id="..bureau_id.."&show_size="..show_size.."&stage_id=4&subject_id=-1&random="..math.random(1000)},
	{"/dsideal_yy/djmh/getNewResByBureauStageSubject?bureau_id="..bureau_id.."&show_size="..show_size.."&stage_id=5&subject_id=-1&random="..math.random(1000)},
	{"/dsideal_yy/djmh/getNewResByBureauStageSubject?bureau_id="..bureau_id.."&show_size="..show_size.."&stage_id=6&subject_id=-1&random="..math.random(1000)},
	{"/dsideal_yy/djmh/getResSortByBureauId?bureau_id="..bureau_id.."&top=6&res_type=1&random="..math.random(1000)}
})

result["success"] = true
result["newRes"] = cjson.decode(newRes.body).list
result["newXxRes"] = cjson.decode(newXxRes.body).list
result["newCzRes"] = cjson.decode(newCzRes.body).list
result["newGzRes"] = cjson.decode(newGzRes.body).list
ngx.log(ngx.ERR,"@@@@@@@"..tostring(ActiveBureau.body).."@@@@@@@")
if #tostring(ActiveBureau.body) ~= 0 then 
	result["ActiveBureau"] = cjson.decode(ActiveBureau.body).list
end

ngx.print(cjson.encode(result))




