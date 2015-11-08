local args = getParams();
local taskService = require "task.services.TaskService";
-------------------------------前台输入--------------------------------------
--任务id
local taskId = args["task_id"];
-------------------------------验证前台必须输入------------------------------
if taskId == nil or taskId == "" then
	ngx.say("{\"success\":false,\"info\":\"task_id参数错误！\"}");
	return;
end
----------------------------------------------------------------------------

-------------------------------后台获取--------------------------------------
taskService : delTask(taskId);
local result = {};
result.success= true;
ngx.print(encodeJson(result));
