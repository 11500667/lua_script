--[[
删除协作体[mysql版]
@Author  chenxg
@Date    2015-06-02
--]]

local say = ngx.say

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
local xzt_id = args["xzt_id"]

--判断参数是否为空
if not xzt_id or string.len(xzt_id) == 0 
  then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

-- 获取redis链接
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
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

--存储详细信息
local xzt_sql = "select qyjh_id,dxq_id,zy_tj,hd_tj from t_qyjh_xzt where xzt_id = "..xzt_id.." "
local xzt_result, err, errno, sqlstate = db:query(xzt_sql);
if not xzt_result then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	return;
end
local qyjh_id = xzt_result[1]["qyjh_id"]
local dxq_id = xzt_result[1]["dxq_id"]
local zy_tj = xzt_result[1]["zy_tj"]
local hd_tj = xzt_result[1]["hd_tj"]

if not ok then
   say("{\"success\":false,\"info\":\""..err.."\"}")
   return
end

local n = ngx.now();
local ts2 = os.date("%Y%m%d%H%M%S").."00"..string.sub(n,12,14);
ts2 = ts2..string.rep("0",19-string.len(ts2));


--修改相关统计
local qyjh_updateSql = "update t_qyjh_qyjhs set xzt_tj =xzt_tj-1,hd_tj = hd_tj-"..tonumber(hd_tj).." where qyjh_id="..qyjh_id..""
local qyjh_result, err, errno, sqlstate = db:query(qyjh_updateSql);
if not qyjh_result then
	ngx.say("{\"success\":false,\"info\":\"更新区域均衡协作体数量失败！"..qyjh_updateSql.."\"}");
	return;
end
qyjh_updateSql = "update t_qyjh_dxq set xzt_tj =xzt_tj-1,hd_tj = hd_tj-"..hd_tj.." where dxq_id="..dxq_id..""
db:query(qyjh_updateSql)

--调用论坛接口删除版块
local bbs_sql = "select bbs_pk,b_delete from t_qyjh_bbs where bbs_type=2 and xzt_id="..xzt_id..""
local result, err, errno, sqlstate = db:query(bbs_sql);
if not result then
	ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
	return;
end
if #result>=1 then
	local forumService = require("social.service.CommonForumService")
	forumService:deleteForum(result[1]["bbs_pk"])
end
 
--标记删除协作体
local updateSql = "update t_qyjh_xzt set b_delete =1,b_use =0,ts="..ts2.." where xzt_id="..xzt_id..";update t_qyjh_xzt_tea set b_use =0,end_time="..ts2.." where xzt_id="..xzt_id;	
--db:query(updateSql)

--删除相关下属信息[活动和资源]
local hdUpdateSql = "update t_qyjh_hd set b_delete =1,ts="..ts2.." where xzt_id="..xzt_id..";update t_base_publish set b_delete =1,ts="..ts2.." where xzt_id="..xzt_id..";"..updateSql;	
db:query(hdUpdateSql)


say("{\"success\":true,\"info\":\"协作体删除成功！\"}")

-- 将redis连接归还到连接池
cache: set_keepalive(0, v_pool_size)
--mysql放回连接池
db:set_keepalive(0, v_pool_size)
