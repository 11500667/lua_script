local args = getParams();
local _DBUtil = require "common.DBUtil";
local ratingId = args.rating_id;
local resourceInfoId = args.resource_info_id;
local updateSql = "update t_rating_resource set RESOURCE_STATUS=1 where rating_id= "..ratingId.." and RESOURCE_INFO_ID="..resourceInfoId..""

_DBUtil:querySingleSql(updateSql);
local result = {} ;
result["success"] = true;
ngx.print(encodeJson(result));

