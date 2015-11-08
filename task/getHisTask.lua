local args = getParams();
local taskService = require "task.services.TaskService";
-------------------------------前台输入--------------------------------------
--主任务编号
local taskId = args["task_id"];
--子任务编号
local taskChildId = args["task_child_id"];
--转派任务编号
local turnTaskId = args["turn_task_id"];
-------------------------------验证前台必须输入------------------------------
if taskId == nil or taskId == "" then
	ngx.say("{\"success\":false,\"info\":\"task_id参数错误！\"}");
	return;
end
if taskChildId == nil or taskChildId == "" then
	ngx.say("{\"success\":false,\"info\":\"task_child_id参数错误！\"}");
	return;
end
------------------------------------------------------------------------------
local hisTaskList = taskService: getHisTask(taskId,taskChildId,turnTaskId);
ngx.print(encodeJson(hisTaskList));