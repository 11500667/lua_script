#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#申健 2015-2-3
#描述：判断试题上传人员是否为东师理想学科人员
]]

local request_method = ngx.var.request_method;
local args = nil;
if "GET" == request_method then
    args = ngx.req.get_uri_args();
else
    ngx.req.read_body();
    args = ngx.req.get_post_args();
end

if args["person_id"] == nil or args["person_id"]=="" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数person_id不能为空！\"}");
	return;
elseif args["identity_id"] == nil or args["identity_id"]=="" then
	ngx.print("{\"success\":\"false\",\"info\":\"参数identity_id不能为空！\"}");
	return;
end

local personId 	  = tostring(args["person_id"]);
local identityId  = tostring(args["identity_id"]);

local cjson = require "cjson";
-- 获取redis连接
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
	ngxngx.print("{\"success\":false,\"info\":\"判断重复过程出错！\"}")
	ngx.log(ngx.ERR, "===> 获取连接出错 ===> ", err)
	return
end

-- 东师理想学科人员所在的部门（普通教师）,多个部门之间用逗号间隔
local v_dsideal_person_orgs = "200113395";

local isDsidealPerson = false;

-- 身份是否为学科管理人员
if identityId == "2" then
	isDsidealPerson = true;
	
elseif identityId == "5" then 

	local bm = cache:hget("person_" .. personId .. "_" .. identityId, "bm");
	ngx.log(ngx.ERR, "===> bm ===> ", bm, " ===> ", type(bm));
	if bm~=nil and bm~=ngx.null and bm~="" then
		local orgIdTab = Split(v_dsideal_person_orgs, ",");
		ngx.log(ngx.ERR, "===> v_dsideal_person_orgs 按逗号分隔后的table ===> ", cjson.encode(orgIdTab));
		for i=1, #orgIdTab do
			local dsidealOrgId = orgIdTab[i];
			ngx.log(ngx.ERR, "===> dsidealOrgId ===> 值：", dsidealOrgId, " ==> 类型：", type(dsidealOrgId));
			if dsidealOrgId==bm then
				isDsidealPerson = true;
			end
		end		
	end
end

local resultObj = {};
resultObj.success = true;
resultObj.is_dsideal_person = isDsidealPerson;

local responseStr = cjson.encode(resultObj);
ngx.log(ngx.ERR, "===> isDsidealPerson.lua 返回的值 ===> ", responseStr);
ngx.print(responseStr);


local ok, err = cache: set_keepalive(0, v_pool_size)
if not ok then
	ngx.log(ngx.ERR, "====>将Redis连接归还连接池出错！");
end
