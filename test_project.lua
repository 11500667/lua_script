
local cjson = require "cjson"

local resultJson = "";
local dsideal_orgId = "2005232"
local captureResponse = ngx.location.capture("/dsideal_yy/golbal/getValueByKey?key=ybk.dsideal.org", {
    method = ngx.HTTP_POST
});


if captureResponse.status == ngx.HTTP_OK then
    resultJson = cjson.decode(captureResponse.body);
    ngx.log(ngx.ERR, "===> captureResponse.body ===> ", captureResponse.body);
    dsideal_orgId = resultJson["ybk.dsideal.org"];
else
    ngx.print("{\"success\":false,\"info\":\"查询东师理想试题学科人员所在的部门ID失败！\"}")
    return
end

local v_dsideal_person_orgs = dsideal_orgId;

ngx.say(v_dsideal_person_orgs);
