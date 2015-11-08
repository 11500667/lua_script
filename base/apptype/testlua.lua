#ngx.header.content_type = "text/plain;charset=utf-8"
--local myPrime = require "resty.PRIME";

--local num = {2,3,5,7,11,13};
--ngx.say(myPrime.getCombineValuesNew(num,3))
--ngx.say("ddd");
local name = "5aSn5ZaK6YGT6buR6buR55qE44CL";
local response = ngx.location.capture("/getQuanPin", {
	method = ngx.HTTP_GET,
	args = { name = name}
	--body = "name="..
});


if response.status == 200 then
    ngx.say(response.body);
else
ngx.say("{\"success\":false,\"info\":\"查询失败！\"}")
   return
end
