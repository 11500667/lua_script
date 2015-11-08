#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#申健 2015-03-07
#描述：保存指定地区的审核配置
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
elseif args["set_type"] == nil or args["set_type"]=="" then
    ngx.say("{\"success\":false,\"info\":\"参数set_type不能为空！\"}");
    return;
elseif args["set_value"] == nil or args["set_value"]=="" then
    ngx.say("{\"success\":false,\"info\":\"参数set_value不能为空！\"}");
    return;
end

-- 参数：单位ID
local unitId   = tostring(args["unit_id"]);
-- 参数：保存项， 1为自动通过，2为审核机制
local setType  = tostring(args["set_type"]);
-- 参数：设置项的值，如果set_type为1，set_value的值：0否，1是；如果set_type为2，set_value的值：1单级审核，2多级审核
local setValue = tostring(args["set_value"]);

--2. 连接SSDB
local ssdblib = require "resty.ssdb"
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    ngx.print("{\"success\":false, \"info\":\""..err.."\"}")
    return
end

--保存数据
if setType == "1" then --设置自动通过
	result, err = ssdb: hset("check_config_" .. unitId, "auto_pass", setValue);
else -- 设置审核机制
	local valArray = Split(setValue, ",");
	local checkWay = valArray[1];
	local forceChk = valArray[2];
	result, err = ssdb: multi_hset("check_config_" .. unitId, "check_way"	 , checkWay, "force_check", forceChk);
	-- result, err = ssdb: hset("check_config_" .. unitId, "force_check", forceChk);
end 

if not result then
	ngx.say("{\"success\":false,\"info\":\""..err.."\"}");
	return;
end

-- 输出值
ngx.say("{\"success\":true,\"info\":\"保存设置成功！\"}");

-- 将SSDB连接归还连接池
local ok, err = ssdb:set_keepalive(0,v_pool_size)
if not ok then
  ngx.log(ngx.ERR, "====>将ssdb连接归还连接池出错！");
end
