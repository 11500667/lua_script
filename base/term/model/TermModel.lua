--[[
@Author cuijinlong
@date 2015-5-22
--]]
local _Scheme = {};
--[[
	局部函数：获得当前学期
]]
function _Scheme:get_current_term()
    local MysqlUtil = require "yxx.tool.MysqlUtil";
    local db = MysqlUtil:getDb();
    local row = MysqlUtil:query("SELECT XQ_ID from t_base_term where SFDQXQ=1");
    MysqlUtil:close(db);
    return row[1].XQ_ID;
end
return _Scheme


