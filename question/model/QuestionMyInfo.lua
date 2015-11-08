--[[
#申健  2015-05-16
#描述：我的试题的基础信息类
]]

local _QuestionMyInfo = {};

-- -------------------------------------------------------------------------
--[[
    局部函数：获取更新 T_TK_QUESTION_MY_INFO 表中的B_DELETE字段为1的SQL语句和缓存对象
    作者：    申健           2015-05-16
    参数1：   quesIdChar     试题的GUID
    参数2：   strucId        试题所在结构的ID
    参数3：   typeId         要删除的资源记录的类型：7共享
    返回值1： SQL语句
]]
local function updateDeleteStatus(self, quesIdChar, strucId, typeId)
    
    local DBUtil     = require "multi_check.model.DBUtil";
    local myTs       = require "resty.TS"
    local db         = DBUtil: getDb();
    local currentTS  = myTs.getTs();
    
    local querySql = "SELECT ID FROM T_TK_QUESTION_MY_INFO WHERE QUESTION_ID_CHAR='" .. quesIdChar .. "' AND STRUCTURE_ID_INT=" .. strucId .. " AND TYPE_ID=" .. typeId .. " AND B_DELETE=0;";
    local dbResult, err, errno, sqlstate = db:query(querySql);
    if not dbResult or dbResult == nil or #dbResult == 0 then
        ngx.log(ngx.ERR, "===> 获取审核记录失败");
        return false, nil, nil;
    end

    local quesMyInfoId = dbResult[1]["ID"];
    local sql = "UPDATE T_TK_QUESTION_MY_INFO SET B_DELETE=1, UPDATE_TS=".. currentTS .. " WHERE ID=" .. quesMyInfoId .. ";";

    -- 将数据库连接返回连接池
    DBUtil: keepDbAlive(db);
    local cacheKey   = "myquestion_" .. quesMyInfoId;
    return true, sql, { obj_type=2, key=cacheKey, field_name="b_delete", field_value="1" };

end

_QuestionMyInfo.updateDeleteStatus = updateDeleteStatus;
-- -------------------------------------------------------------------------

return _QuestionMyInfo;