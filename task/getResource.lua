local args = getParams();
--创建ssdb连接
local ssdblib = require "resty.ssdb"
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
ngx.log(ngx.ERR,"======================================================================");
--加码
function encodeURI(s)
  s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
  return string.gsub(s, " ", "+")
end
-------------------------------前台输入--------------------------------------
--资源编号
local resource_info_id = args["resource_info_id"];
-------------------------------验证前台必须输入------------------------------
if resource_info_id == nil or resource_info_id == "" then
	ngx.say("{\"success\":false,\"info\":\"resource_info_id参数错误！\"}");
	return;
end
-----------------------------------------------------------------------------
resource_info_id = Split(resource_info_id,",");
local resourceList = {};
for i=1,#resource_info_id do 
	local resource_res = {};
	local info_id = resource_info_id[i];
	local querySql = "select id from t_resource_info where resource_id_int = '"..info_id.."'"
	local DBUtil = require "common.DBUtil";
	local querySql_res = DBUtil: querySingleSql(querySql);
	if not querySql_res then
		return false;
	end
	local resource_id = querySql_res[1]["id"];
	ngx.log(ngx.ERR,"======================================================================"..resource_id);
	local res_info = ssdb:multi_hget("resource_"..resource_id,"resource_format","resource_page","resource_size","file_id","thumb_id","preview_status","width","height","resource_title")
	  resource_res["resource_format"] = res_info[2]
	  resource_res["resource_page"] = res_info[4]
	  resource_res["resource_size"] = res_info[6]		
	  resource_res["file_id"] = res_info[8]
	  resource_res["thumb_id"] = res_info[10]
	  resource_res["preview_status"] = res_info[12]
	  resource_res["width"] = res_info[14]
	  resource_res["height"] = res_info[16]
	  resource_res["resource_title"] = res_info[18]
	  resource_res["url_code"] = encodeURI(res_info[18])
	  resource_res["resource_id_int"] = info_id
	  resourceList[i] = resource_res  
end
local result = {};
result.list = resourceList;
result.success= true;
ngx.print(encodeJson(result));




