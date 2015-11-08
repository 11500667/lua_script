local args = getParams();
local taskService = require "task.services.TaskService";
-------------------------------前台输入--------------------------------------
--任务标题
local title = args["title"];
--任务属性
local taskType = args["task_type"];
--完成时间
local completetime = args["completetime"];
--承接人
local joinPerson = args["join_person"];
--任务等级（紧急程度）
local levelId = args["level_id"];
--任务描述
local describeTask = args["describe_task"];
--任务附件
local filePath = args["file_path"];
--保存类型  （0-保存不生成任务，1-保存并生成任务）
local saveType =args["save_type"];
local taskId =args["task_id"];
-------------------------------验证前台必须输入------------------------------
if title == nil or title == "" then
	ngx.say("{\"success\":false,\"info\":\"title参数错误！\"}");
	return;
end
if taskType == nil or taskType == "" then
	ngx.say("{\"success\":false,\"info\":\"task_type参数错误！\"}");
	return;
end
if completetime == nil or completetime == "" then
	ngx.say("{\"success\":false,\"info\":\"completetime参数错误！\"}");
	return;
end
if joinPerson == nil or joinPerson == "" then
	ngx.say("{\"success\":false,\"info\":\"join_person参数错误！\"}");
	return;
end
if levelId == nil or levelId == "" then
	ngx.say("{\"success\":false,\"info\":\"level_id参数错误！\"}");
	return;
end
if saveType == nil or saveType == "" then
	ngx.say("{\"success\":false,\"info\":\"save_type参数错误！\"}");
	return;
end
if taskId == nil or taskId == "" then
	ngx.say("{\"success\":false,\"info\":\"task_id参数错误！\"}");
	return;
end
----------------------------------------------------------------------------
--------------------------------删除原任务----------------------------------
taskService : delTask(taskId);
-------------------------------后台获取--------------------------------------
--操作序号
local sequenceId = 1
--菜单ID
local menuId = "11000200";
local oldStatus = "--";
local oldStatusDesc = "--";
local operation = "--";
local curStatus = "AA";
local curStatusDesc = "待接收";
--操作人
local createPerson = getCookieByName("person_id")
--主任务ID
local taskId = taskService : getTaskId();
--------------------------------添加任务属性table-----------------------------
local task = {};
task.title = title;
task.taskType = taskType;
task.completetime = completetime;
task.levelId = levelId;
task.describeTask = describeTask;
task.filePath = filePath;
task.saveType = saveType;
task.sequenceId = sequenceId;
task.menuId = menuId;
task.oldStatus = oldStatus;
task.oldStatusDesc = oldStatusDesc;
task.operation = operation;
task.curStatus = curStatus;
task.curStatusDesc = curStatusDesc;
task.createPerson = createPerson;
task.taskId = taskId;
------------------------------------------------------------------------------
joinPerson = Split(joinPerson,",");
for i=1,#joinPerson do 
	local join_id = joinPerson[i];
	task.joinPerson = join_id;
	task.taskChildId = taskService : getTaskChildId(taskId);
	task.taskProperty = 2;
	--ngx.log(ngx.ERR,encodeJson(task));
	taskService:saveTask(task);
end

local result = {};
result.success= true;
ngx.print(encodeJson(result));