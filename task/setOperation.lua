local args = getParams();
local taskService = require "task.services.TaskService";
local DicItemService = require "base.dic.services.DicItemService";
-------------------------------前台输入--------------------------------------
--页面编码menu_id
local menuId = args["menu_id"];
--操作编码operation
local operation = args["operation"];
--当前状态cur_status
local curStatus = args["cur_status"];
--主任务id
local taskId = args["task_id"];
--子任务id
local taskChildId = args["task_child_id"];
--转派任务id
local turnTaskId = args["turn_task_id"];

local file_path_join = args["file_path_join"];
--任务总结
local conclusion = args["conclusion"];
--拒绝原因
local reason = args["reason"];

-------------------------------验证前台必须输入------------------------------
if menuId == nil or menuId == "" then
	ngx.say("{\"success\":false,\"info\":\"menu_id参数错误！\"}");
	return;
end
if operation == nil or operation == "" then
	ngx.say("{\"success\":false,\"info\":\"operation参数错误！\"}");
	return;
end
if curStatus == nil or curStatus == "" then
	ngx.say("{\"success\":false,\"info\":\"cur_status参数错误！\"}");
	return;
end
if taskId == nil or taskId == "" then
	ngx.say("{\"success\":false,\"info\":\"task_id参数错误！\"}");
	return;
end
if taskChildId == nil or taskChildId == "" then
	ngx.say("{\"success\":false,\"info\":\"task_child_id参数错误！\"}");
	return;
end
if turnTaskId == nil or turnTaskId == "" then
	ngx.say("{\"success\":false,\"info\":\"turn_task_id参数错误！\"}");
	return;
end
if file_path_join == nil or file_path_join == "" then
	file_path_join="";
end
-------------------------------后台获取--------------------------------------

local createPerson = getCookieByName("person_id");
--如果是转派任务
if tonumber(operation) == 100009 then
	local getNowTask = taskService : getJoinTaskDetail(taskId,taskChildId,turnTaskId);
	--转派人
	local task = {};
	local joinPerson = args["join_person"];
	joinPerson = Split(joinPerson,",");
	for i=1,#joinPerson do 
		local join_id = joinPerson[i];
		task.joinPerson = join_id; 
		task.taskId=taskId;
		task.turnTaskId=taskService : getTurnTaskId(taskId,taskChildId);	
		task.taskChildId =taskChildId;
		task.taskType=getNowTask.list[1]["task_type"]
		task.title=getNowTask.list[1]["title"]
		task.taskTitle=getNowTask.list[1]["title"]
		task.describeTask=getNowTask.list[1]["describe_task"]
		task.createtime=getNowTask.list[1]["createtime"]
		task.updatetime=getNowTask.list[1]["updatetime"]
		task.completetime=getNowTask.list[1]["completetime"]
		task.levelId=getNowTask.list[1]["level_id"]
		task.createPerson=createPerson;
		task.conclusion=getNowTask.list[1]["conclusion"]
		task.remark=getNowTask.list[1]["remark"]
		task.discussId=getNowTask.list[1]["discuss_id"]
		task.sequenceId=getNowTask.list[1]["sequence_id"];
		task.menuId=getNowTask.list[1]["menu_id"]
		task.oldStatus=getNowTask.list[1]["cur_status"];
		task.oldStatusDesc=getNowTask.list[1]["cur_status_desc"];
		task.operation=operation;
		task.curStatus="AH";
		task.curStatusDesc="转派已接收";
		task.filePath=getNowTask.list[1]["file_path"]
		task.reserved1=getNowTask.list[1]["reserved1"]
		task.reserved2=getNowTask.list[1]["reserved2"]
		task.reserved3=getNowTask.list[1]["reserved3"]
		task.reserved4=getNowTask.list[1]["reserved4"]
		task.reserved5=getNowTask.list[1]["reserved5"]
		task.bUse=getNowTask.list[1]["b_use"]
		task.opePerson=getNowTask.list[1]["ope_person"]
		task.saveType=1
		--转派任务
		task.taskProperty = 3;
		ngx.log(ngx.ERR,task.createPerson)
		ngx.log(ngx.ERR,task.joinPerson)
		taskService:saveTask(task);
	end
end


-------------------------------保存历史--------------------------------------
local seqId = taskService :getSequenceId(taskId,taskChildId,turnTaskId);
taskService : saveHisTask(taskId,taskChildId,turnTaskId,seqId);

-------------------------------更新最新--------------------------------------
--获取最新状态
local new_curStatus = taskService : getNewStaByOp(operation,curStatus);
local newStatus = new_curStatus.list[1]["new_status"];
--获取最新菜单码
local new_menuId = taskService : getNewMenuId(newStatus);
local newMenuId = new_menuId.list[1]["menu_id"];
ngx.log(ngx.ERR,newStatus);
ngx.log(ngx.ERR,newMenuId);
--获取原数据
local oldTaskList = taskService : getJoinTaskDetail(taskId,taskChildId,turnTaskId);
--初始化新数据
oldTaskList.list[1]["menu_id"] = newMenuId;
oldTaskList.list[1]["old_status"] = curStatus;
oldTaskList.list[1]["old_status_desc"] = oldTaskList.list[1]["cur_status_desc"];
oldTaskList.list[1]["operation"] = operation;
oldTaskList.list[1]["cur_status"] = newStatus;
if conclusion == nil or conclusion == "" or conclusion==ngx.null then
	conclusion = oldTaskList.list[1]["conclusion"];	
end
oldTaskList.list[1]["conclusion"] = conclusion;
oldTaskList.list[1]["sequence_id"] = seqId;
oldTaskList.list[1]["reserved3"] = reason;	
if file_path_join == nil or file_path_join == "" or file_path_join==ngx.null then
	file_path_join = oldTaskList.list[1]["reserved4"];	
end
oldTaskList.list[1]["reserved4"] = file_path_join;	

oldTaskList.list[1]["ope_person"] = createPerson;
--获取当前状态的翻译
local dicList = DicItemService:getDicItemById("TASK_STATUS",newStatus);
oldTaskList.list[1]["cur_status_desc"] = dicList.list[1]["detail"];		
local newTaskList = oldTaskList.list[1];
--保存新数据
taskService : updateTask(newTaskList);



local result = {};
result.success= true;
ngx.print(encodeJson(result));
