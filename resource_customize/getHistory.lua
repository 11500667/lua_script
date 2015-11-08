#ngx.header.content_type = "text/plain;charset=utf-8"
--[[
#申健 2014-12-6
#描述：获取用户的信息,用于资源定制,包括用户填写的手机号码和邮箱
]]

local personId = tostring(ngx.var.cookie_person_id)
local identityId = tostring(ngx.var.cookie_identity_id)

local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

--ssdb
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

local personJsonObj;
local res_person, err = ngx.location.capture("/getTeaDetailInfo", {
	args = { person_id = personId }
})
if res_person.status == 200 then
    ngx.log(ngx.ERR, "===> 获取教师信息[/getTeaDetailInfo]接口的返回值：[", res_person.body, "]");
	personJsonObj = cjson.decode(res_person.body)[1]
else
	ngx.say("{\"success\":false,\"info\":\"查询失败！\"}")
    return
end

local history, err = ssdb:multi_hget("resCusHistory_" .. personId .. "_" .. identityId, "telephone", "email", "qq");
ngx.log(ngx.ERR, "=== history ==>", type(history), #history, history[1], type(history[1]));
if history[1] == "ok" then
	personJsonObj.telephone = "";
	personJsonObj.email = "";
	personJsonObj.qq = "";
else
	personJsonObj.telephone = history[2];
	personJsonObj.email = history[4];
	personJsonObj.qq = history[6];
end

local resultJson = {};
resultJson.success = true;
resultJson.person_info = personJsonObj;

local resultJsonStr = cjson.encode(resultJson);
ngx.say(resultJsonStr);

ssdb:set_keepalive(0,v_pool_size)