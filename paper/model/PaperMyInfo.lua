--[[
#申健 2015-04-15
#描述：我的试卷的基础信息类
]]

local _PaperMyInfo = {};

---------------------------------------------------------------------------
--[[
	局部函数：获取更新 T_SJK_PAPER_MY_INFO 表中的B_DELETE字段为1的SQL语句和缓存对象
	作者：    申健 	        2015-04-15
	参数1：   resIdInt  	试卷在base表的ID
	参数2：   typeId  		要删除的试卷记录的类型：7我的共享
	返回值1： SQL语句
]]
local function updateDeleteStatus(self, paperIdInt, typeId)
	
	local DBUtil 	 = require "multi_check.model.DBUtil";
	local myTs 	 	 = require "resty.TS"
	local db 	 	 = DBUtil: getDb();
	local currentTS  = myTs.getTs();
	
	local sql = "UPDATE T_SJK_PAPER_MY_INFO SET B_DELETE=1, UPDATE_TS=".. currentTS .. " WHERE PAPER_ID_INT=" .. paperIdInt .. " AND TYPE_ID=" .. typeId .. " AND B_DELETE=0;";
	
	local querySql = "SELECT SQL_NO_CACHE ID FROM T_SJK_PAPER_MY_INFO_SPHINXSE WHERE QUERY='filter=paper_id_int," .. paperIdInt .. ";filter=type_id," .. typeId .. ";filter=b_delete,0;' LIMIT 1;";
	
	local dbResult, err, errno, sqlstate = db:query(querySql);
	-- ngx.log(ngx.ERR, "===> dbResult : [", #dbResult, "]");
	if not dbResult or dbResult == nil or #dbResult == 0 then
		ngx.log(ngx.ERR, "===> 获取审核记录失败");
		return false, nil, nil;
	end
	
	local paperMyInfoId = dbResult[1]["ID"];
	
	-- 将数据库连接返回连接池
	DBUtil: keepDbAlive(db);
	local cacheKey = "mypaper_" .. paperMyInfoId;
	return true, sql, { obj_type=3, key=cacheKey, field_name="b_delete", field_value="1" };

end

_PaperMyInfo.updateDeleteStatus = updateDeleteStatus;

---------------------------------------------------------------------------

return _PaperMyInfo;