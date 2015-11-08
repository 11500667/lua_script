--[[
	姜旭 	2015-08-13
	描述： 	
]]
local _DicItemService = {};
---------------------------------------------------------------------------
--[[
	method：获取数据字典信息
	author：姜旭
	date：2015-07-28
	param：	KIND 
			CODE
]]
local function getDicItemById(self , kind , code )
	local DBUtil = require "common.DBUtil"; 
	local querySql = " select kind,code,detail,remark from t_sys_dic_item ";
	local whereSql = " where b_use=1 and kind='"..kind.."' and code='"..code.."' order by DIC_ITEM_ID";
	querySql = querySql..whereSql;
	ngx.log(ngx.ERR, "===> 获取数据字典信息 ===> ", querySql);
	local querysql_res = DBUtil: querySingleSql(querySql);
	if not querysql_res then
		return false;
	end	
	local resultDate = {};
	resultDate.list = querysql_res;
	resultDate.success = true;
	return resultDate;
end
_DicItemService.getDicItemById = getDicItemById;
---------------------------------------------------------------------------


return _DicItemService