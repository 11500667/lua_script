local args = getParams();
local taskService = require "task.services.TaskService";
local dicItemService = require "base.dic.services.DicItemService";
-------------------------------前台输入--------------------------------------
--页码
local pageNumber = args["pageNumber"]
--页显示数量
local pageSize = args["pageSize"]
-------------------------------验证前台必须输入------------------------------
if pageNumber == nil or pageNumber == "" then
	ngx.say("{\"success\":false,\"info\":\"pageNumber参数错误！\"}");
	return;
end
if pageSize == nil or pageSize == "" then
	ngx.say("{\"success\":false,\"info\":\"pageSize参数错误！\"}");
	return;
end
-----------------------------------------------------------------------------

-------------------------------后台获取--------------------------------------
--获取后台缓存person_id
local personId = getCookieByName("person_id");

local status = "'AA','AB','AG','AH','AL','AF'";

--根据状态查询菜单数据
local taskList = taskService : getTaskList(personId,status,pageNumber,pageSize);
--for i=1 , #taskList.list do
	--添加当前状态翻译
--	taskList.list[i]["jx_test"] = "姜旭测试";
--end
ngx.print(encodeJson(taskList));