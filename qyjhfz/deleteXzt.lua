--[[
删除协作体
@Author  chenxg
@Date    2015-03-02
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"

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

--创建ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
    return
end

--获取mysql数据库连接
local mysql = require "resty.mysql";
local db, err = mysql : new();
if not db then 
	ngx.log(ngx.ERR, err);
	return;
end
db:set_timeout(1000) -- 1 sec

local ok, err, errno, sqlstate = db:connect{
	host = v_mysql_ip,
	port = v_mysql_port,
	database = v_mysql_database,
	user = v_mysql_user,
	password = v_mysql_password,
	max_packet_size = 1024 * 1024 }

if not ok then
	ngx.say("{\"success\":\"false\",\"info\":\"查询数据失败！\"}")
	ngx.log(ngx.ERR, "=====> 连接数据库失败!");
	return
end

--存储详细信息
local hxzt = ssdb:hget("qyjh_xzt",xzt_id)
local xzt = cjson.decode(hxzt[1])
xzt.b_delete = 1

local ok, err = ssdb:hset("qyjh_xzt", xzt_id, cjson.encode(xzt))

if not ok then
   say("{\"success\":false,\"info\":\""..err.."\"}")
   return
end

--删除区域均衡和协作体的对应关系
ssdb:zdel("qyjh_qyjh_xzts_"..xzt.qyjh_id,xzt_id)
--删除大学区和协作体的对应关系
local dxq_xzts = ssdb:hget("qyjh_dxq_xzts",xzt.dxq_id)
dxq_xzts[1] = string.gsub(dxq_xzts[1], ","..xzt_id..",", ",")
local ok, err = ssdb:hset("qyjh_dxq_xzts", xzt.dxq_id, dxq_xzts[1])
if not ok then
   say("{\"success\":false,\"info\":\""..err.."\"}")
   return
end

--删除协作体和管理员的对应关系
ssdb:hdel("qyjh_xzt_manager", xzt_id)
--ssdb:hdel("qyjh_manager_xzts", xzt.person_id)

local old_qyjh_manager_xzts = ssdb:hget("qyjh_manager_xzts",xzt.person_id)
if not old_qyjh_manager_xzts[1] or string.len(old_qyjh_manager_xzts[1]) == 0  then
	old_qyjh_manager_xzts[1] = ","
end
old_qyjh_manager_xzts[1] = string.gsub(old_qyjh_manager_xzts[1], ","..xzt_id..",", ",")
local ok, err = ssdb:hset("qyjh_manager_xzts", xzt.person_id, old_qyjh_manager_xzts[1])


--删除协作体点击量
ssdb:zdel("qyjh_qyjh_xzt_djl_"..xzt.qyjh_id, xzt_id)
ssdb:zdel("qyjh_dxq_xzt_djl_"..xzt.dxq_id, xzt_id)


--存储区域均衡下协作体数量
ssdb:hincr("qyjh_qyjh_tj_"..xzt.qyjh_id,"xzt_tj", -1)

--存储大学区下协作体数量
ssdb:hincr("qyjh_dxq_tj",xzt.dxq_id.."_".."xzt_tj", -1)

--删除协作体的统计信息开始
ssdb:hdel("qyjh_xzt_tj",xzt_id.."_".."xx_tj")
ssdb:hdel("qyjh_xzt_tj",xzt_id.."_".."js_tj")
ssdb:hdel("qyjh_xzt_tj",xzt_id.."_".."zy_tj")
ssdb:hdel("qyjh_xzt_tj",xzt_id.."_".."hd_tj")

ssdb:zdel("qyjh_xzt_sort_"..xzt.dxq_id,xzt_id)
ssdb:zdel("qyjh_qyjh_xzt_sort_"..xzt.qyjh_id,xzt_id)
		
local n = ngx.now();
local ts2 = os.date("%Y%m%d%H%M%S").."00"..string.sub(n,12,14);
ts2 = ts2..string.rep("0",19-string.len(ts2));
--标记删除协作体
local updateSql = "update t_qyjh_xzt set b_delete =1,ts="..ts2.." where xzt_id="..xzt_id;	
db:query(updateSql)
--标记删除活动
local hdUpdateSql = "update t_qyjh_hd set b_delete =1,ts="..ts2.." where xzt_id="..xzt_id;	
db:query(hdUpdateSql)
--标记删除资源
local resUpdateSql = "update t_base_publish set b_delete =1,ts="..ts2.." where xzt_id="..xzt_id;	
db:query(resUpdateSql)
--[[if ok then 
	cache:del("qyjh_xzt_"..xzt.mysql_id)
end]]
--return
say("{\"success\":true,\"info\":\"协作体删除成功！\"}")

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
-- 将redis连接归还到连接池
cache: set_keepalive(0, v_pool_size)
--mysql放回连接池
db:set_keepalive(0, v_pool_size)
