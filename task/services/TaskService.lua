--[[
	姜旭 	2015-07-28
	描述： 	任务接口
]]
local _TaskService = {};

--处理task中为空字段
function useTask(task)
	if task.turnTaskId == nil or task.turnTaskId == "" then
		task.turnTaskId = 0;
	end
	if task.title == nil or task.title == "" then
		task.title = "";
	end
	if task.describeTask == nil or task.describeTask == "" then
		task.describeTask = "";
	end
	if task.completetime == nil or task.completetime == "" then
		task.completetime = "";
	end
	if task.levelId == nil or task.levelId == "" then
		task.levelId = "";
	end
	if task.createPerson == nil or task.createPerson == "" then
		task.createPerson = "";
	end
	if task.joinPerson == nil or task.joinPerson == "" then
		task.joinPerson = "";
	end
	if task.conclusion == nil or task.conclusion == "" then
		task.conclusion = "";
	end
	if task.remark == nil or task.remark == "" then
		task.remark = "";
	end
	if task.discussId == nil or task.discussId == "" then
		task.discussId = "";
	end
	if task.sequenceId == nil or task.sequenceId == "" then
		task.sequenceId = 0;
	end
	if task.menuId == nil or task.menuId == "" then
		task.menuId = "";
	end
	if task.oldStatus == nil or task.oldStatus == "" then
		task.oldStatus = "";
	end
	if task.oldStatusDesc == nil or task.oldStatusDesc == "" then
		task.oldStatusDesc = "";
	end
	if task.operation == nil or task.operation == "" then
		task.operation = "";
	end
	if task.curStatus == nil or task.curStatus == "" then
		task.curStatus = "";
	end
	if task.curStatusDesc == nil or task.curStatusDesc == "" then
		task.curStatusDesc = "";
	end
	if task.filePath == nil or task.filePath == "" then
		task.filePath = "";
	end
	if task.saveType == nil or task.saveType == "" then
		task.saveType = "";
	end
	if task.taskProperty == nil or task.taskProperty == "" then
		task.taskProperty = "";
	end
    return task;
end

---------------------------------------------------------------------------
--[[
	method：根据菜单编号获取所有状态
	author：姜旭
	date：2015-07-28
	param：	menu_id 菜单编号
]]
local function getStatusByMenuId(self , menu_id )
	local DBUtil = require "common.DBUtil"; 
	local querySql = " select distinct cur_status from t_base_task ";
	local whereSql = " where menu_id='"..menu_id.."'";
	querySql = querySql .. whereSql;
	ngx.log(ngx.ERR, "===> 根据菜单编码 ===> ", querySql);
	local querysql_res = DBUtil: querySingleSql(querySql);
	if not querysql_res then
		return false;
	end	
	local resultDate = {};
	resultDate.list = querysql_res;
	resultDate.success = true;
	return resultDate;
end
_TaskService.getStatusByMenuId = getStatusByMenuId;
---------------------------------------------------------------------------

---------------------------------------------------------------------------
--[[
	method：获取任务操作
	author：姜旭
	date：2015-07-28
	param：	menu_id 菜单编号
			cur_status 当前状态
]]
local function queryOpeByMenuId(self , menu_id , cur_status)
	local DBUtil = require "common.DBUtil";
	local DicItemService = require "base.dic.services.DicItemService";
	local querySql = "select operation from t_base_task ";
	local whereSql = " where menu_id="..menu_id.." and cur_status = '"..cur_status.."' ";
	querySql = querySql .. whereSql;
	ngx.log(ngx.ERR, "===> 根据菜单编码与当前状态查询 ===> ", querySql);
	local querysql_res = DBUtil: querySingleSql(querySql);
	if not querysql_res then
		return false;
	end	
	for i=1,#querysql_res do
		local operation = querysql_res[i]["operation"];
		local dicList = DicItemService:getDicItemById("OPERATION_DISCRIBLE",operation);
		querysql_res[i]["operation_desc"] = dicList.list[1]["detail"];
	end
	local resultDate = {};
	resultDate.list = querysql_res;
	resultDate.success = true;
	return resultDate;
end
_TaskService.queryOpeByMenuId = queryOpeByMenuId;
---------------------------------------------------------------------------

---------------------------------------------------------------------------
--[[
	method：获取主任务ID
	author：姜旭
	date：2015-07-28
]]
local function getTaskId(self)
	local DBUtil = require "common.DBUtil";
	local querySql = "select max(task_id) as task_id from t_task_mission ";
	ngx.log(ngx.ERR, "===> 根据操作获取新状态 ===> ", querySql);
	local querysql_res = DBUtil: querySingleSql(querySql);
	if not querysql_res then
		return false;
	end
	local task_id = {};
	if querysql_res[1]["task_id"] == ngx.null then 
		task_id = "1";
	else
		task_id = tonumber(querysql_res[1]["task_id"])+1;
	end
	return task_id;
	
end
_TaskService.getTaskId = getTaskId;
---------------------------------------------------------------------------

---------------------------------------------------------------------------
--[[
	method：获取承接人主任务ID
	author：姜旭
	date：2015-07-28
]]
local function getTaskList(self,personId,status,pageNumber,pageSize)
	local DBUtil = require "common.DBUtil";
	local countSql = "select count(*) as count from t_task_mission ";
	local whereSql = " where cur_status in ( "..status..") and b_use=1 and join_person="..personId;
	countSql = countSql..whereSql;
	ngx.log(ngx.ERR, "===> 获取菜单列表数量 ===> ", countSql);
	local countsql_res = DBUtil: querySingleSql(countSql);
	if not countsql_res then
		return false;
	end
	local offset = pageSize*pageNumber-pageSize
	local limit = pageSize
	local totalRow = countsql_res[1]["count"]
	local totalPage = math.floor((totalRow+pageSize-1)/pageSize)
	
	local querySql = "select task_id,task_child_id,turn_task_id,task_type,title,describe_task,createtime,updatetime,completetime,level_id,create_person,join_person,conclusion,remark,discuss_id,sequence_id,menu_id,old_status,old_status_desc,operation,cur_status,cur_status_desc,file_path,b_use,task_property from t_task_mission ";
	
	querySql = querySql..whereSql;
	ngx.log(ngx.ERR, "===> 获取菜单列表 ===> ", querySql);
	local querysql_res = DBUtil: querySingleSql(querySql);
	if not querysql_res then
		return false;
	end
	local resultDate = {};
	resultDate.list = querysql_res;
	resultDate["totalRow"] = totalRow
	resultDate["totalPage"] = totalPage
	resultDate["pageNumber"] = pageNumber
	resultDate["pageSize"] = pageSize
	resultDate.success = true;
	return resultDate;
	
end
_TaskService.getTaskList = getTaskList;
---------------------------------------------------------------------------

---------------------------------------------------------------------------
--[[
	method：获取承接人主任务ID
	author：姜旭
	date：2015-07-28
]]
local function getInitTaskList(self,personId,status,pageNumber,pageSize)
	local DBUtil = require "common.DBUtil";
	local countSql = "select count(*) as count from t_task_mission ";
	local whereSql = " where cur_status in ( "..status..") and b_use=1 and create_person="..personId;
	countSql = countSql..whereSql;
	ngx.log(ngx.ERR, "===> 获取菜单列表数量 ===> ", countSql);
	local countsql_res = DBUtil: querySingleSql(countSql);
	if not countsql_res then
		return false;
	end
	local offset = pageSize*pageNumber-pageSize
	local limit = pageSize
	local totalRow = countsql_res[1]["count"]
	local totalPage = math.floor((totalRow+pageSize-1)/pageSize)
	
	local querySql = "select task_id,task_child_id,turn_task_id,task_type,title,describe_task,createtime,updatetime,completetime,level_id,create_person,join_person,conclusion,remark,discuss_id,sequence_id,menu_id,old_status,old_status_desc,operation,cur_status,cur_status_desc,file_path,b_use,task_property from t_task_mission ";
	
	querySql = querySql..whereSql;
	ngx.log(ngx.ERR, "===> 获取菜单列表 ===> ", querySql);
	local querysql_res = DBUtil: querySingleSql(querySql);
	if not querysql_res then
		return false;
	end
	local resultDate = {};
	resultDate.list = querysql_res;
	resultDate["totalRow"] = totalRow
	resultDate["totalPage"] = totalPage
	resultDate["pageNumber"] = pageNumber
	resultDate["pageSize"] = pageSize
	resultDate.success = true;
	return resultDate;
	
end
_TaskService.getInitTaskList = getInitTaskList;
---------------------------------------------------------------------------




---------------------------------------------------------------------------
--[[
	method：获取创建者主任务ID
	author：姜旭
	date：2015-07-28
]]
local function getCreateTaskList(self,personId,status,pageNumber,pageSize)
	local DBUtil = require "common.DBUtil";
	local countSql = "select count(distinct task_id) as count from t_task_mission ";
	local whereSql = " where cur_status = '"..status.."' and create_person="..personId.." and b_use=0";
	countSql = countSql..whereSql;
	ngx.log(ngx.ERR, "===> 获取菜单列表数量 ===> ", countSql);
	local countsql_res = DBUtil: querySingleSql(countSql);
	if not countsql_res then
		return false;
	end
	local offset = pageSize*pageNumber-pageSize
	local limit = pageSize
	local totalRow = countsql_res[1]["count"]
	local totalPage = math.floor((totalRow+pageSize-1)/pageSize)
	
	local querySql = "select task_id,task_child_id,turn_task_id,task_type,title,describe_task,createtime,updatetime,completetime,level_id,create_person,join_person,conclusion,remark,discuss_id,sequence_id,menu_id,old_status,old_status_desc,operation,cur_status,cur_status_desc,file_path,b_use,task_property, count(distinct task_id) from t_task_mission ";
	querySql = querySql..whereSql.." group by task_id";
	ngx.log(ngx.ERR, "===> 获取菜单列表 ===> ", querySql);
	local querysql_res = DBUtil: querySingleSql(querySql);
	if not querysql_res then
		return false;
	end
	local resultDate = {};
	resultDate.list = querysql_res;
	resultDate["totalRow"] = totalRow
	resultDate["totalPage"] = totalPage
	resultDate["pageNumber"] = pageNumber
	resultDate["pageSize"] = pageSize
	resultDate.success = true;
	return resultDate;
	
end
_TaskService.getCreateTaskList = getCreateTaskList;
---------------------------------------------------------------------------

---------------------------------------------------------------------------
--[[
	method：获取子任务ID
	author：姜旭
	date：2015-07-28
]]
local function getTaskChildId(self,task_id)
	local DBUtil = require "common.DBUtil";
	local querySql = "select max(task_child_id) as task_child_id from t_task_mission";
	local whereSql = " where task_id = "..task_id;
	querySql = querySql..whereSql;
	ngx.log(ngx.ERR, "===> 根据操作获取新状态 ===> ", querySql);
	local querysql_res = DBUtil: querySingleSql(querySql);
	if not querysql_res then
		return false;
	end
	local task_child_id = {};
	if querysql_res[1]["task_child_id"] == ngx.null then 
		task_child_id = "1";
	else
		task_child_id = tonumber(querysql_res[1]["task_child_id"])+1;
	end
	return task_child_id;
	
end
_TaskService.getTaskChildId = getTaskChildId;
---------------------------------------------------------------------------

---------------------------------------------------------------------------
--[[
	method：获取转派任务ID           
	author：姜旭
	date：2015-07-28
]]
local function getTurnTaskId(self,task_id,task_child_id)
	local DBUtil = require "common.DBUtil";
	local querySql = "select max(turn_task_id) as turn_task_id from t_task_mission";
	local whereSql = " where task_id = '"..task_id.."' and task_child_id='"..task_child_id.."'";
	querySql = querySql..whereSql;
	ngx.log(ngx.ERR, "===> 根据操作获取新状态 ===> ", querySql);
	local querysql_res = DBUtil: querySingleSql(querySql);
	if not querysql_res then
		return false;
	end
	local turn_task = {};
	if querysql_res[1]["turn_task_id"] == ngx.null then 
		turn_task = "0";
	else
		turn_task = tonumber(querysql_res[1]["turn_task_id"])+1;
	end
	return turn_task;
	
end
_TaskService.getTurnTaskId = getTurnTaskId;
---------------------------------------------------------------------------

---------------------------------------------------------------------------
--[[
	method：获取操作序号id         
	author：姜旭
	date：2015-07-28
]]
local function getSequenceId(self,task_id,task_child_id,turn_task_id)
	local DBUtil = require "common.DBUtil";
	local querySql = "select max(sequence_id) as sequence_id  from t_task_mission_history";
	local whereSql = " where task_id = '"..task_id.."' and task_child_id='"..task_child_id.."' and turn_task_id='"..turn_task_id.."'";
	querySql = querySql..whereSql;
	ngx.log(ngx.ERR, "===> 根据操作获取新状态 ===> ", querySql);
	local querysql_res = DBUtil: querySingleSql(querySql);
	if not querysql_res then
		return false;
	end
	local sequence_id = {};
	if querysql_res[1]["sequence_id"] == ngx.null then 
		sequence_id = "1";
	else
		sequence_id = tonumber(querysql_res[1]["sequence_id"])+1;
	end
	return sequence_id;
	
end
_TaskService.getSequenceId = getSequenceId;
---------------------------------------------------------------------------



---------------------------------------------------------------------------
--[[
	method：根据操作获取新状态
	author：姜旭
	date：2015-07-28
	param：	operation 操作码
			cur_status 当前状态
]]
local function getNewStaByOp(self , operation , cur_status)
	local DBUtil = require "common.DBUtil";
	local querySql = "select new_status from t_base_task ";
	local whereSql = " where operation="..operation.." and cur_status = '"..cur_status.."' ";
	querySql = querySql .. whereSql;
		ngx.log(ngx.ERR, "===> 根据操作获取新状态 ===> ", querySql);
	local querysql_res = DBUtil: querySingleSql(querySql);
	if not querysql_res then
		return false;
	end
	local resultDate = {};
	resultDate.list = querysql_res;
	resultDate.success = true;
	return resultDate;
	
end
_TaskService.getNewStaByOp = getNewStaByOp;
---------------------------------------------------------------------------

---------------------------------------------------------------------------
--[[
	method：获取新的菜单编码
	author：姜旭
	date：2015-07-28
	param：	operation 操作码
			cur_status 当前状态
]]
local function getNewMenuId(self , newStatus)
	local DBUtil = require "common.DBUtil";
	local querySql = "select menu_id from t_base_task ";
	local whereSql = " where cur_status = '"..newStatus.."' ";
	querySql = querySql .. whereSql;
		ngx.log(ngx.ERR, "===> 根据操作获取新状态 ===> ", querySql);
	local querysql_res = DBUtil: querySingleSql(querySql);
	if not querysql_res then
		return false;
	end
	local resultDate = {};
	resultDate.list = querysql_res;
	resultDate.success = true;
	return resultDate;
end
_TaskService.getNewMenuId = getNewMenuId;
---------------------------------------------------------------------------

---------------------------------------------------------------------------
--[[
	method：根据主任务编号与子任务编号获取任务详细信息
	author：姜旭
	date：2015-07-30
	param：	task_id 主任务编号
			task_child_id 子任务编号
]]
local function getTaskDetail(self , task_id , task_child_id , turn_task_id)
	local DBUtil = require "common.DBUtil";
	local personService = require "base.person.services.PersonService";
	local querySql = "select task_id,task_child_id,turn_task_id,title,task_type,describe_task,createtime,updatetime,completetime,level_id,create_person,join_person,conclusion,remark,discuss_id,sequence_id,menu_id,old_status,old_status_desc,operation,cur_status,cur_status_desc,file_path,reserved1,reserved2,reserved3,reserved4,reserved5 from t_task_mission ";
	local whereSql = " where task_id="..task_id.." and task_child_id = '"..task_child_id.."' and turn_task_id='"..turn_task_id.."' order by sequence_id";
	querySql = querySql .. whereSql;
		ngx.log(ngx.ERR, "===> 根据主任务编号与子任务编号获取任务详细信息 ===> ", querySql);
	local querysql_res = DBUtil: querySingleSql(querySql);
	if not querysql_res then
		return false;
	end
	local queryJoinPerson = "select task_id,group_concat(distinct join_person) as join_person from t_task_mission where task_id='"..task_id.."' and task_child_id='"..task_child_id.."' and turn_task_id='"..turn_task_id.."' group by task_id";
	local queryJoinPerson_res = DBUtil: querySingleSql(queryJoinPerson);
	if not queryJoinPerson_res then
		return false;
	end
	local createPersonD = personService:getPersonInfo(querysql_res[1]["create_person"],"5");
	querysql_res[1]["person_name"] = createPersonD.table_List.person_name
	
	querysql_res[1]["join_person"] = queryJoinPerson_res[1]["join_person"];
	ngx.log(ngx.ERR, "===> =================== ===> ", querysql_res[1]["join_person"]);
	local joinPerson = Split(querysql_res[1]["join_person"],",");
	local joinPersonList = {};
	for i=1,#joinPerson do 
		local join_id = joinPerson[i];
		ngx.log(ngx.ERR, "===> =================== ===> ", join_id);
		local joinPersonD = personService:getPersonInfo(join_id,"5");
		joinPersonD.table_List.person_id=join_id;
		--ngx.log(ngx.ERR,encodeJson(task));
		joinPersonList[i]=joinPersonD
	end
	local resultDate = {};
	resultDate.join_person = joinPersonList;
	resultDate.list = querysql_res;
	resultDate.success = true;
	return resultDate;
end
_TaskService.getTaskDetail = getTaskDetail;
---------------------------------------------------------------------------


---------------------------------------------------------------------------
--[[
	method：根据主任务编号与子任务编号获取任务详细信息
	author：姜旭
	date：2015-07-30
	param：	task_id 主任务编号
			task_child_id 子任务编号
]]
local function getJoinTaskDetail(self , task_id , task_child_id , turn_task_id)
	local DBUtil = require "common.DBUtil";
	local personService = require "base.person.services.PersonService";
	local querySql = "select task_id,task_child_id,turn_task_id,title,task_type,describe_task,createtime,updatetime,completetime,level_id,create_person,join_person,conclusion,remark,discuss_id,sequence_id,menu_id,old_status,old_status_desc,operation,cur_status,cur_status_desc,file_path,reserved1,reserved2,reserved3,reserved4,reserved5,b_use,task_property from t_task_mission ";
	local whereSql = " where task_id="..task_id.." and task_child_id = '"..task_child_id.."' and turn_task_id='"..turn_task_id.."' order by sequence_id";
	querySql = querySql .. whereSql;
		ngx.log(ngx.ERR, "===> 根据主任务编号与子任务编号获取任务详细信息 ===> ", querySql);
	local querysql_res = DBUtil: querySingleSql(querySql);
	if not querysql_res then
		return false;
	end
	local resultDate = {};
	resultDate.join_person = joinPersonList;
	resultDate.list = querysql_res;
	resultDate.success = true;
	return resultDate;
end
_TaskService.getJoinTaskDetail = getJoinTaskDetail;
---------------------------------------------------------------------------




---------------------------------------------------------------------------
--[[
	method：保存任务
	author：姜旭
	date：2015-07-30
	param：	
]]
local function saveTask(self , task)
	local DBUtil = require "common.DBUtil";
	task = useTask(task);
	local insertSql = "insert into t_task_mission (task_id, task_child_id, turn_task_id, task_type, title, describe_task, createtime, updatetime, completetime,level_id, create_person, join_person, conclusion, remark, discuss_id, sequence_id, menu_id, old_status, old_status_desc, operation, cur_status, cur_status_desc, file_path, reserved1, reserved2, reserved3, reserved4, reserved5, b_use, task_property,ope_person) values ("..task.taskId..", "..task.taskChildId..", "..task.turnTaskId..", '"..task.taskType.."', '"..task.title.."', '"..task.describeTask.."', now(), now(), '"..task.completetime.."', '"..task.levelId.."', '"..task.createPerson.."', '"..task.joinPerson.."', '"..task.conclusion.."', '"..task.remark.."', '"..task.discussId.."', '"..task.sequenceId.."', '"..task.menuId.."', '"..task.oldStatus.."', '"..task.oldStatusDesc.."', '"..task.operation.."', '"..task.curStatus.."', '"..task.curStatusDesc.."', '"..task.filePath.."' , '', '', '', '', '', '"..task.saveType.."','"..task.taskProperty.."' ,'"..task.createPerson.."')";
	ngx.log(ngx.ERR,insertSql);
	DBUtil: querySingleSql(insertSql);
	local resultDate = {};
	resultDate.success = true;
	return resultDate;
end
_TaskService.saveTask = saveTask;
---------------------------------------------------------------------------

---------------------------------------------------------------------------
--[[
	method：更新任务
	author：姜旭
	date：2015-07-30
	param：	
]]
local function setTask(self , task)
	local DBUtil = require "common.DBUtil";
	local updSql = "update set title=1,describe_task=1,updatetime=now(),level_id=1,join_person=1,conclusion=1,"
end
_TaskService.setTask = setTask;
---------------------------------------------------------------------------

---------------------------------------------------------------------------
--[[
	method：删除任务
	author：姜旭
	date：2015-07-30
	param：	
]]
local function delTask(self , task_id)
	local DBUtil = require "common.DBUtil";
	local delSql	= "delete from t_task_mission where task_id='"..task_id.."'";
	DBUtil: querySingleSql(delSql);
	local resultDate = {};
	resultDate.success = true;
	return resultDate;
end
_TaskService.delTask = delTask;
---------------------------------------------------------------------------

---------------------------------------------------------------------------
--[[
	method：保存历史表
	author：姜旭
	date：2015-08-19
	param：	
]]
local function saveHisTask(self , taskId , taskChildId,turnTaskId,seqId)
	local DBUtil = require "common.DBUtil";
	local querySql = "select task_id,task_child_id,turn_task_id,task_type,title,describe_task,createtime,updatetime,completetime,level_id,create_person,join_person,conclusion,remark,discuss_id,sequence_id,menu_id,old_status,old_status_desc,operation,cur_status,cur_status_desc,file_path,reserved1,reserved2,reserved3,reserved4,reserved5,b_use,task_property,ope_person from t_task_mission ";
	local whereSql = " where task_id="..taskId.." and task_child_id = '"..taskChildId.."' and turn_task_id='"..turnTaskId.."' order by sequence_id";
	querySql = querySql .. whereSql;
		ngx.log(ngx.ERR, "===> 根据主任务编号与子任务编号获取任务详细信息 ===> ", querySql);
	local querysql_res = DBUtil: querySingleSql(querySql);
	if not querysql_res then
		return false;
	end
	local taskType = querysql_res[1]["task_type"];
	local title = querysql_res[1]["title"];
	local describeTask = querysql_res[1]["describe_task"];
	local createtime = querysql_res[1]["createtime"];
	local updatetime = querysql_res[1]["updatetime"];
	local completetime = querysql_res[1]["completetime"];
	local levelId = querysql_res[1]["level_id"];
	local createPerson = querysql_res[1]["create_person"];
	local joinPerson = querysql_res[1]["join_person"];
	local conclusion = querysql_res[1]["conclusion"];
	local remark = querysql_res[1]["remark"];
	local discussId = querysql_res[1]["discuss_id"];
	local sequenceId = seqId;
	local menuId = querysql_res[1]["menu_id"];
	local oldStatus = querysql_res[1]["old_status"];
	local oldStatusDesc = querysql_res[1]["old_status_desc"];
	local operation = querysql_res[1]["operation"];
	local curStatus = querysql_res[1]["cur_status"];
	local curStatusDesc = querysql_res[1]["cur_status_desc"];
	local filePath = querysql_res[1]["file_path"];
	local reserved1 = "";
	local reserved2 = "";
	local reserved3 = "";
	local reserved4 = "";
	local reserved5 = "";
	local buse = querysql_res[1]["b_use"];
	local taskProperty = querysql_res[1]["task_property"];
	local opePerson = querysql_res[1]["ope_person"];
	local insertSql = "insert into t_task_mission_history (task_id, task_child_id, turn_task_id, task_type, title, describe_task, createtime, updatetime, completetime,level_id, create_person, join_person, conclusion, remark, discuss_id, sequence_id, menu_id, old_status, old_status_desc, operation, cur_status, cur_status_desc, file_path, reserved1, reserved2, reserved3, reserved4, reserved5, b_use, task_property,ope_person) values ("..taskId..", "..taskChildId..", "..turnTaskId..", '"..taskType.."', '"..title.."', '"..describeTask.."', '"..createtime.."', '"..updatetime.."', '"..completetime.."', '"..levelId.."', '"..createPerson.."', '"..joinPerson.."', '"..conclusion.."', '"..remark.."', '"..discussId.."', '"..sequenceId.."', '"..menuId.."', '"..oldStatus.."', '"..oldStatusDesc.."', '"..operation.."', '"..curStatus.."', '"..curStatusDesc.."', '"..filePath.."' , '"..reserved1.."', '"..reserved2.."', '"..reserved3.."', '"..reserved4.."', '"..reserved5.."', '"..buse.."','"..taskProperty.."','"..opePerson.."')";
	ngx.log(ngx.ERR,insertSql);
	local insertsql_res = DBUtil: querySingleSql(insertSql);
	if not insertsql_res then
		return false;
	end
	local resultDate = {};
	resultDate.success = true;
	return resultDate;
end
_TaskService.saveHisTask = saveHisTask;

---------------------------------------------------------------------------
--[[
	method：获取任务历史
	author：姜旭
	date：2015-08-19
	param：	
]]
local function getHisTask(self , taskId ,taskChildId,turnTaskId)
	local DBUtil = require "common.DBUtil";
	local personService = require "base.person.services.PersonService";
	local querySql = "select task_id, task_child_id, turn_task_id, task_type, title, describe_task, createtime, updatetime, completetime,level_id, create_person, join_person, conclusion, remark, discuss_id, sequence_id, menu_id, old_status, old_status_desc, operation, cur_status, cur_status_desc, file_path, reserved1, reserved2, reserved3, reserved4, reserved5, b_use, task_property,ope_person from t_task_mission_history ";
	local whereSql = " where task_id = '"..taskId.."' and task_child_id='"..taskChildId.."' and turn_task_id='"..turnTaskId.."'";
	querySql = querySql..whereSql;
	ngx.log(ngx.ERR, "===> 根据主任务编号获取历史任务详细信息 ===> ", querySql);
	local querysql_res = DBUtil: querySingleSql(querySql);
	if not querysql_res then
		return false;
	end
	for i=1,#querysql_res do 
		if querysql_res[i] == nil or querysql_res[i] == "" or querysql_res[i]==ngx.null then
	
		else
			local createPersonD = personService:getPersonInfo(querysql_res[i]["ope_person"],"5");
			querysql_res[i]["ope_person_name"] = createPersonD.table_List.person_name
		end
	end
	
	
	
	--local createPersonD1 = personService:getPersonInfo(querysql_res[1]["ope_person"],"5");
	--querysql_res[1]["ope_person_name"] = createPersonD1.table_List.person_name
	
	
	
	local resultDate = {};
	resultDate.list = querysql_res;
	resultDate.success = true;
	return resultDate;
	
end
_TaskService.getHisTask = getHisTask;
---------------------------------------------------------------------------
--[[
	method：更新任务
	author：姜旭
	date：2015-08-19
	param：	
]]
local function updateTask(self ,task)
	local DBUtil = require "common.DBUtil";
	local taskId =task.task_id
	local taskChildId =task.task_child_id
	local turnTaskId =task.turn_task_id
	local taskType = task.task_type;
	local title = task.title;
	local describeTask = task.describe_task;
	local createtime = task.createtime;
	local updatetime = task.updatetime;
	local completetime = task.completetime;
	local levelId = task.level_id;
	local createPerson = task.create_person;
	local joinPerson = task.join_person;
	local conclusion = task.conclusion;
	if conclusion == nil or conclusion == "" or conclusion==ngx.null then
		conclusion = "";
	end
	local ope_person = task.ope_person;
	local remark = task.remark;
	local discussId = task.discuss_id;
	local sequenceId = task.sequence_id;
	local menuId = task.menu_id;
	local oldStatus = task.old_status;
	local oldStatusDesc = task.old_status_desc;
	local operation = task.operation;
	local curStatus = task.cur_status;
	local curStatusDesc = task.cur_status_desc;
	local filePath = task.file_path;
	local reserved1 = task.reserved1;
	local reserved2 = task.reserved2;
	local reserved3 = task.reserved3;
	local reserved4 = task.reserved4;
	local reserved5 = task.reserved5;
	if reserved1 == nil or reserved1 == "" or reserved1==ngx.null then
		reserved1 = "";
	end
	if reserved2 == nil or reserved2 == "" or reserved2==ngx.null then
		reserved2 = "";
	end
	if reserved3 == nil or reserved3 == "" or reserved3==ngx.null then
		reserved3 = "";
	end
	if reserved4 == nil or reserved4 == "" or reserved4==ngx.null then
		reserved4 = "";
	end
	if reserved5 == nil or reserved5 == "" or reserved5==ngx.null then
		reserved5 = "";
	end
	local buse = task.b_use;
	local taskProperty = task.task_property;
	local updateSql = "update t_task_mission set  task_type= '"..taskType.."', title= '"..title.."', describe_task= '"..describeTask.."', createtime= '"..createtime.."', updatetime= now(), completetime= '"..completetime.."', level_id= '"..levelId.."', create_person= '"..createPerson.."', join_person= '"..joinPerson.."', conclusion= '"..conclusion.."', remark= '"..remark.."', discuss_id= '"..discussId.."', sequence_id= '"..sequenceId.."', menu_id= '"..menuId.."', old_status= '"..oldStatus.."', old_status_desc= '"..oldStatusDesc.."', operation= '"..operation.."', cur_status= '"..curStatus.."', cur_status_desc= '"..curStatusDesc.."', file_path= '"..filePath.."', reserved1= '"..reserved1.."', reserved2= '"..reserved2.."', reserved3= '"..reserved3.."', reserved4= '"..reserved4.."', reserved5= '"..reserved5.."', b_use= '"..buse.."', task_property= '"..taskProperty.."'  ,ope_person='"..ope_person.."' ";
	local whereSql = " where task_id= '"..taskId.."' and task_child_id= '"..taskChildId.."' and turn_task_id= '"..turnTaskId.."'"
	updateSql = updateSql..whereSql;
	ngx.log(ngx.ERR, "===> 更新任务信息 ===> ", updateSql);
	local querysql_res = DBUtil: querySingleSql(updateSql);
	if not querysql_res then
		return false;
	end
	local resultDate = {};
	resultDate.list = querysql_res;
	resultDate.success = true;
	return resultDate;
end
_TaskService.updateTask = updateTask;
---------------------------------------------------------------------------


---------------------------------------------------------------------------
--[[
	method：查询承接着完成情况
	author：姜旭
	date：2015-07-30
	param：	
]]
local function getJoinStatus(self , taskId,taskChildId,turnTaskId,join_person)
	local DBUtil = require "common.DBUtil";
	local querySql	= "select task_id, task_child_id, turn_task_id, task_type, title, describe_task, createtime, updatetime, completetime,level_id, create_person, join_person, conclusion, remark, discuss_id, sequence_id, menu_id, old_status, old_status_desc, operation, cur_status, cur_status_desc, file_path, reserved1, reserved2, reserved3, reserved4, reserved5, b_use, task_property,ope_person from t_task_mission where task_id='"..taskId.."' and task_child_id='"..taskChildId.."' and task_property=2 and join_person='"..join_person.."'";
	ngx.log(ngx.ERR,querySql);
	local querySql_res = DBUtil: querySingleSql(querySql);
	if not querySql_res then
		return false;
	end
	local resultDate = {};
	resultDate.list = querySql_res;
	resultDate.success = true;
	resultDate.info = "查询成功"; 
	return resultDate;
end
_TaskService.getJoinStatus = getJoinStatus;
---------------------------------------------------------------------------

---------------------------------------------------------------------------
--[[
	method：查询转派者完成情况
	author：姜旭
	date：2015-07-30
	param：	
]]
local function getTurnStatus(self , taskId,taskChildId,turnTaskId,join_person)
	local DBUtil = require "common.DBUtil";
	local personService = require "base.person.services.PersonService";
	local querySql	= "select task_id, task_child_id, turn_task_id, task_type, title, describe_task, createtime, updatetime, completetime,level_id, create_person, join_person, conclusion, remark, discuss_id, sequence_id, menu_id, old_status, old_status_desc, operation, cur_status, cur_status_desc, file_path, reserved1, reserved2, reserved3, reserved4, reserved5, b_use, task_property,ope_person  from t_task_mission where task_id='"..taskId.."' and task_child_id='"..taskChildId.."' and task_property=3 and create_person='"..join_person.."'";
	ngx.log(ngx.ERR,querySql);
	local querySql_res = DBUtil: querySingleSql(querySql);
	if not querySql_res then
		return false;
	end
	if querySql_res[1] == nil then
	
	else
	local createPersonD = personService:getPersonInfo(querySql_res[1]["join_person"],"5");
	querySql_res[1]["join_person_name"] = createPersonD.table_List.person_name
	end
	
	local resultDate = {};
	resultDate.list = querySql_res;
	resultDate.success = true;
	resultDate.info = "查询成功"; 
	return resultDate;
end
_TaskService.getTurnStatus = getTurnStatus;
---------------------------------------------------------------------------


return _TaskService