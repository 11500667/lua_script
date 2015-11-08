
--[[
	班级服务 by huyue 2015-07-11
]]
local _ClassInfoModel = {};

---------------------------------------------------------------------------

--[[
    描述： 根绝班级ID ，获取兄弟班级
    作者： 胡悦 2015-07-07
    参数： calssId  班级ID
]]
local function getBrotherClassByClassId(self,classId)

	local sql = "select class_id,entrance_year,org_id,stage_id from t_base_class where class_id = "..classId;
	
	ngx.log(ngx.ERR, "[hy_log]->[class_info]-> 查询当前班级的SQL ===> [[["..sql.."]]]");
	local DBUtil      = require "common.DBUtil";
	local queryResult = DBUtil: querySingleSql(sql);
    if not queryResult then
        return false;
    end
	local entranceYear = queryResult[1]["entrance_year"];
	local orgId = queryResult[1]["org_id"];
	local stageId = queryResult[1]["stage_id"];
	
	local query_class_sql = "select class_id,class_name from t_base_class where entrance_year = "..entranceYear.." and org_id = "..orgId.." and stage_id ="..stageId.." and class_id <>"..classId;
	ngx.log(ngx.ERR, "[hy_log]->[class_info]-> 查询兄弟班级的SQL ===> [[["..query_class_sql.."]]]");
	local queryClassResult = DBUtil: querySingleSql(query_class_sql);
	local resultTable = {};
    for index=1, #queryClassResult do
        local record = queryClassResult[index];
        table.insert(resultTable, { class_id=record["class_id"], class_name=record["class_name"] } );
    end
    
    return resultTable;

end

_ClassInfoModel.getBrotherClassByClassId = getBrotherClassByClassId;

---------------------------------------------------------------------------
return _ClassInfoModel;