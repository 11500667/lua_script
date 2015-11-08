#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#申健 2015-03-07
#描述：获取用户的单位类型
]]

-- 1.获取参数
local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["unit_id"] == nil or args["unit_id"]=="" then
    ngx.say("{\"success\":false,\"info\":\"参数unit_id不能为空！\"}");
    return;
end

local unitId   = tonumber(args["unit_id"]);

local function getUnitType(unitId)
	local unitType;
	if unitId > 100000 and unitId < 200000 then
		unitType = 1;
	elseif unitId > 200000 and unitId < 300000 then
		unitType = 2;
	elseif unitId > 300000 and unitId < 400000 then
		unitType = 3;
	elseif unitId > 400000 then
		unitType = 4;
	end
	return unitType;
end

local unitType = getUnitType(unitId);
ngx.print("{\"unit_type\":" .. unitType .. "}");