--获取数据字典详细信息 by huyue 2015-07-22
--1.获得参数方法
local args = getParams();
-- 获取数据库连接
local _DBUtil = require "common.DBUtil";
local kind = args["kind"];
if kind == nil or kind == "" then
	ngx.say("{\"success\":false,\"info\":\"kind参数错误！\"}");
	return;
else
  kind = args["kind"];
end
local query_dicitem_sql = "select CODE,DETAIL,REMARK from t_sys_dic_item ";
local query_dicitem_where = "where Kind = '"..kind.."' order by sort";
query_dicitem_sql = query_dicitem_sql..query_dicitem_where;
local query_dicitem_res = _DBUtil:querySingleSql(query_dicitem_sql);
local result = {} ;
result["table_List"] = query_dicitem_res;
result["success"] = true;
ngx.print(encodeJson(result));