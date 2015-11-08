--[[
    #申健   2015-04-18
    #描述： 资源统计的服务类
]]

local _AppType = {};

----------------------------------------------------------------------------------
--[[
	局部函数：获取科目和应用类型之间的映射关系
	作者：    申健 	        2015-04-18
	参数1：   subjecId  	科目ID
	返回值1： table对象，存储应用类型的list
]]
local function getBySubject(self, subjectId)
	
	local DBUtil 	= require "multi_check.model.DBUtil";
	local db 	 	= DBUtil: getDb();
	
	-- 查询改学段科目下的应用类型
    local sql = "SELECT APP_TYPE_ID,APP_TYPE_NAME FROM t_resource_subject_apptype WHERE SUBJECT_ID = " .. subjectId .. " ORDER BY APP_TYPE_ID ASC;";
	
	local results, err, errno, sqlstate = db:query(sql);
    if not results then
        ngx.log(ngx.ERR, "bad result: ", err, ": ", errno, ": ", sqlstate, ".");
        return false, nil;
    end

    local app_type = {};
    for i = 1, #results do
        local tab1 = {};
        tab1["app_type_id"]   = results[i]["APP_TYPE_ID"];
        tab1["app_type_name"] = results[i]["APP_TYPE_NAME"];
        table.insert(app_type, tab1);
    end
    
    return true, app_type;
    
end
_AppType.getBySubject = getBySubject;

----------------------------------------------------------------------------------

return _AppType;