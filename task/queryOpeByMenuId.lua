local args = getParams();
local taskService = require "task.services.TaskService";
-------------------------------前台输入--------------------------------------
--菜单编号
local menuId = args["menu_id"];
--当前状态
local curStatus = args["cur_status"];

-------------------------------验证前台必须输入------------------------------
if curStatus == nil or curStatus == "" then
	ngx.say("{\"success\":false,\"info\":\"cur_status参数错误！\"}");
	return;
end
if menuId == nil or menuId == "" then
	ngx.say("{\"success\":false,\"info\":\"menu_id参数错误！\"}");
	return;
end
-----------------------------------------------------------------------------

-------------------------------后台获取--------------------------------------
local statusList = taskService : queryOpeByMenuId(menuId, curStatus);

ngx.print(encodeJson(statusList));