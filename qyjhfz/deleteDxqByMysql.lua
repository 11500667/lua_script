--[[
删除大学区[mysql版]
@Author  chenxg
@Date    2015-06-02
--]]

local say = ngx.say
local quote = ngx.quote_sql_str
--引用模块
local cjson = require "cjson"

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
local dxq_id = args["dxq_id"]
local qyjh_id = args["qyjh_id"]

--判断参数是否为空
if not dxq_id or string.len(dxq_id) == 0  
  or not qyjh_id or string.len(qyjh_id) == 0 
  then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

--连接mysql数据库
local mysql = require "resty.mysql"
local db = mysql:new()
db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024*1024
}

--删除大学区下的协作体
local querySql = "select xzt_tj,zy_tj,hd_tj from t_qyjh_dxq where dxq_id="..dxq_id
local result, err, errno, sqlstate = db:query(querySql);
if not result then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	return;
end
local xzt_tj = result[1]["xzt_tj"]
local zy_tj = result[1]["zy_tj"]
local hd_tj = result[1]["hd_tj"]

local n = ngx.now();
local ts2 = os.date("%Y%m%d%H%M%S").."00"..string.sub(n,12,14);
ts2 = ts2..string.rep("0",19-string.len(ts2));

--删除大学区相关统计信息
--删除大学区信息
local updateSql = "update t_qyjh_dxq set b_delete =1,b_use =0,ts="..ts2.." where dxq_id="..dxq_id;	
db:query(updateSql)

updateSql = "update t_qyjh_qyjhs set dxq_tj =dxq_tj-1,xzt_tj =xzt_tj-"..xzt_tj..",hd_tj =hd_tj-"..hd_tj.." where qyjh_id="..qyjh_id;
db:query(updateSql)


--删除大学区所在分区
--调用论坛接口删除分区
local bbs_sql = "select bbs_pk,b_delete from t_qyjh_bbs where bbs_type=1 and dxq_id="..dxq_id
local result2, err, errno, sqlstate = db:query(bbs_sql);
if not result2 then
	ngx.say("{\"success\":false,\"info\":\"查询论坛分区信息失败！"..bbs_sql.."\"}");
	return;
end
if #result2>=1 then
	local partitionService = require("social.service.CommonPartitionService")
	partitionService:deletePartition(result2[1]["bbs_pk"])
end


--删除相关的下属信息【协作体、活动、大学区-学校、协作体--教师、大学区-带头人、资源】
updateSql = "update t_qyjh_xzt set b_delete =1,b_use =0,ts="..ts2.." where b_use=1 and dxq_id="..dxq_id..";update t_qyjh_hd set b_delete =1,ts="..ts2.." where b_delete =0 and dxq_id="..dxq_id..";update t_qyjh_dxq_org set b_use =0,end_time="..os.date("%Y%m%d%H%M%S").." where  b_use = 1 and dxq_id="..dxq_id..";update t_qyjh_xzt_tea set b_use = 0,end_time="..os.date("%Y%m%d%H%M%S").." where  b_use=1 and dxq_id="..dxq_id..";update t_qyjh_dxq_dtr set end_time = "..quote(os.date("%Y-%m-%d %H:%M:%S"))..",b_use=0 where b_use=1 and dxq_id="..dxq_id ..";update t_base_publish set b_delete =1,ts="..ts2.." where pub_target="..dxq_id;	
db:query(updateSql)


say("{\"success\":true,\"info\":\"大学区删除成功！\"}")

--mysql放回连接池
db:set_keepalive(0,v_pool_size)
