local args = getParams();
local DBUtil = require "common.DBUtil";
-------------------------------前台输入--------------------------------------
--主任务编号
local taskId = args["task_id"];
--子任务编号
local taskChildId = args["task_child_id"];
--转派任务id
local turnTaskId = args["turn_task_id"];
--评论内容
local comment = args["comment"];
--评价等级
local commentLevel = args["comment_level"];
-------------------------------验证前台必须输入------------------------------
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
if comment == nil or comment == "" then
	ngx.say("{\"success\":false,\"info\":\"comment参数错误！\"}");
	return;
end
------------------------------------------------------------------------------
local updateSql = "update t_task_mission set reserved1='"..comment.."',reserved2='"..commentLevel.."' ";
local whereSql = " where task_id= '"..taskId.."' and task_child_id= '"..taskChildId.."' and turn_task_id= '"..turnTaskId.."'"
updateSql = updateSql..whereSql;
ngx.log(ngx.ERR, "===> 更新任务信息 ===> ", updateSql);
local querysql_res = DBUtil: querySingleSql(updateSql);
if not querysql_res then
	return false;
end
local resultDate = {};
resultDate.success = true;
resultDate.info = "更新成功";
ngx.print(encodeJson(resultDate));