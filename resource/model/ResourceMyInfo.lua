--[[
#申健 2015-04-15
#描述：我的资源的基础信息类
]]

local _ResourceMyInfo = {};

-- -------------------------------------------------------------------------
--[[
	局部函数：获取更新 T_RESOURCE_MY_INFO 表中的B_DELETE字段为1的SQL语句和缓存对象
	作者：    申健 	        2015-04-15
	参数1：   resIdInt  	资源在base表的ID
	参数2：   typeId  		要删除的资源记录的类型：7共享
	返回值1： SQL语句
]]
local function updateDeleteStatus(self, resIdInt, typeId)
	
	local DBUtil 	 = require "multi_check.model.DBUtil";
	local myTs 	 	 = require "resty.TS"
	local db 	 	 = DBUtil: getDb();
	local currentTS  = myTs.getTs();
	
	local sql = "UPDATE T_RESOURCE_MY_INFO SET B_DELETE=1, UPDATE_TS=".. currentTS .. " WHERE RESOURCE_ID_INT=" .. resIdInt .. " AND TYPE_ID=" .. typeId .. " AND B_DELETE=0;";
	
	local querySql = "SELECT SQL_NO_CACHE ID FROM T_RESOURCE_MY_INFO_SPHINXSE WHERE QUERY='filter=resource_id_int,"..resIdInt..";filter=type_id," .. typeId .. ";filter=b_delete,0;' LIMIT 1;";
	
	local dbResult, err, errno, sqlstate = db:query(querySql);
	-- ngx.log(ngx.ERR, "===> dbResult : [", #dbResult, "]");
	if not dbResult or dbResult == nil or #dbResult == 0 then
		ngx.log(ngx.ERR, "===> 获取审核记录失败");
		return false, nil, nil;
	end
	
	local resMyInfoId = dbResult[1]["ID"];
	
	-- 将数据库连接返回连接池
	DBUtil: keepDbAlive(db);
	local cacheKey  = "myresource_" .. resMyInfoId;
	return true, sql, { obj_type=1, key=cacheKey, field_name="b_delete", field_value="1" };

end

_ResourceMyInfo.updateDeleteStatus = updateDeleteStatus;

-- -------------------------------------------------------------------------
--[[
	局部函数：恢复回收站中的文件
	作者：    申健 	        2015-05-14
	参数1：   resIdInt  	资源在base表的ID
	返回值1： SQL语句
]]
local function recoverResInRecycle(self, resIdInt)
	
	local DBUtil 	 = require "common.DBUtil";
	local myTs 	 	 = require "resty.TS"
	local currentTS  = myTs.getTs();
	
	local sql = "UPDATE T_RESOURCE_MY_INFO SET B_DELETE=0, UPDATE_TS=".. currentTS .. " WHERE RESOURCE_ID_INT=" .. resIdInt .. " AND TYPE_ID=6 AND B_DELETE=1;";
	
	local querySql = "SELECT SQL_NO_CACHE ID FROM T_RESOURCE_MY_INFO_SPHINXSE WHERE QUERY='filter=resource_id_int,"..resIdInt..";filter=type_id,6;filter=b_delete,1;';";
	
	local dbResult = DBUtil:querySingleSql(querySql);
	if not dbResult then
		ngx.log(ngx.ERR, "===> 获取审核记录失败");
		return false;
	end
	
	local resMyInfoId = dbResult[1]["ID"];
	
	-- 将数据库连接返回连接池
	DBUtil: keepDbAlive(db);
	local checkObjType  = 1;
	local resMyInfo     = {checkObjType};
	return sql, { obj_type=1, info_id=resMyInfoId, info_map=resMyInfo };

end

_ResourceMyInfo.updateDeleteStatus = updateDeleteStatus;
---------------------------------------------------------------------------

return _ResourceMyInfo;