--[[
删除活动[mysql版]
@Author  chenxg
@Date    2015-06-04
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local mysql = require "resty.mysql";

--判断request类型, 获得请求参数
local request_method = ngx.var.request_method
local args,err
if request_method == "GET" then
    args,err = ngx.req.get_uri_args()
else
    ngx.req.read_body()
    args,err = ngx.req.get_post_args() 
end
if not args then 
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end
--参数 
local hd_id = args["hd_id"]

--判断参数是否为空
if not hd_id or string.len(hd_id) == 0 
  then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end
--连接mysql
local db, err = mysql:new()
if not db then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return	
end
local ok, err = db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024 * 1024 }
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--存储详细信息
local querySql = "select qyjh_id,dxq_id,xzt_id,hd_id,lx_id as hd_type,hd_confid from t_qyjh_hd where hd_id = "..hd_id
local result, err, errno, sqlstate = db:query(querySql);
if not result then
	ngx.say("{\"success\":false,\"info\":\"查询协作体数据失败！\"}");
	return;
end
local hd = {}
hd.hd_id = result[1]["hd_id"]
hd.hd_confid = result[1]["hd_confid"]
hd.qyjh_id = result[1]["qyjh_id"]
hd.dxq_id = result[1]["dxq_id"]
hd.xzt_id = result[1]["xzt_id"]
hd.hd_type = result[1]["hd_type"]

local status = 200
	if hd.hd_type ~=1 then
		local res_hd, err = ngx.location.capture("/deleteHDForGBT", {
			args = {hd_confid = hd.hd_confid}
		})
		status = res_hd.status
	end
	if status == 200 then
		local n = ngx.now();
		local ts2 = os.date("%Y%m%d%H%M%S").."00"..string.sub(n,12,14);
		ts2 = ts2..string.rep("0",19-string.len(ts2));
		
		--标记删除活动
		local updateSql = "update t_qyjh_hd  set b_delete =1,ts="..ts2.." where hd_id="..hd_id;
		db:query(updateSql)
		
		--标记删除资源
		local resUpdateSql = "update t_base_publish set b_delete =1,ts="..ts2.." where hd_id="..hd_id;	
		db:query(resUpdateSql)
		
		--删除相关统计信息
		local update_sql = "update t_qyjh_qyjhs set hd_tj=hd_tj-1 where qyjh_id="..hd.qyjh_id..";update t_qyjh_dxq set hd_tj=hd_tj-1 where dxq_id="..hd.dxq_id..";update t_qyjh_xzt set hd_tj=hd_tj-1 where xzt_id="..hd.xzt_id..";"
		db:query(update_sql);
		
		say("{\"success\":true,\"info\":\"删除活动成功！\"}")

	else
		say("{\"success\":false,\"info\":\"删除活动失败！\"}")
		return
	end
--mysql放回连接池
db:set_keepalive(0, v_pool_size)
