--[[
删除大学区
@Author  chenxg
@Date    2015-02-09
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"
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

--创建ssdb连接
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
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
-- 获取redis链接
local redis = require "resty.redis"
local cache = redis:new()
local ok,err = cache:connect(v_redis_ip,v_redis_port)
if not ok then
    ngx.say("{\"success\":\"false\",\"info\":\""..err.."\"}")
    return
end
--存储详细信息
local hhd = ssdb:hget("qyjh_hd",hd_id)
local hd = cjson.decode(hhd[1])
hd.b_delete = 1
hd_type = hd.hd_type
qyjh_id = hd.qyjh_id
local hd_type = hd.hd_type
local status = 200
	if hd_type ~="1" then
		local res_hd, err = ngx.location.capture("/deleteHDForGBT", {
			args = {hd_confid = hd.hd_confid}
		})
		status = res_hd.status
	end
	if status == 200 then
		--say("{\"success\":true,\"info\":\"连接高百特删除活动成功！\"}")
		--**************************
		local ok, err = ssdb:hset("qyjh_hd", hd_id, cjson.encode(hd))
		if not ok then
		   say("{\"success\":false,\"info\":\""..err.."\"}")
		   return
		else
			--删除活动相关联的信息
			--存储活动跟大学区对应关系信息
			if hd.page_type == "3" then 
				local hdxq = ssdb:hget("qyjh_dxq",hd.dxq_id)
				local dxq = cjson.decode(hdxq[1])
				path_id = hd.dxq_id
				
				ssdb:zdel("qyjh_dxq_hds_"..path_id,hd_id)
				ssdb:zdel("qyjh_dxq_hds_"..path_id.."_"..hd_type,hd_id)
				--大学区下活动数量
				ssdb:hincr("qyjh_dxq_tj_"..path_id,"hd_tj",-1)
				ssdb:hincr("qyjh_dxq_tj_"..path_id.."_"..hd_type,"hd_tj",-1)
			--存储活动跟协作体对应关系信息
			elseif hd.page_type == "4" then 
				local hxzt = ssdb:hget("qyjh_xzt",hd.xzt_id)
				local xzt = cjson.decode(hxzt[1])
				path_id = hd.xzt_id
				
				ssdb:zdel("qyjh_xzt_hds",path_id,hd_id)	
				ssdb:zdel("qyjh_xzt_hds",path_id.."_"..hd_type,hd_id)			
				--大学区活动数量-1
				ssdb:hincr("qyjh_dxq_tj",xzt.dxq_id.."_hd_tj",-1)
				ssdb:hincr("qyjh_dxq_tj",xzt.dxq_id.."_"..hd_type.."_hd_tj",-1)
				--协作体活动数量-1
				ssdb:hincr("qyjh_xzt_tj",path_id.."_hd_tj",-1)
				ssdb:hincr("qyjh_xzt_tj",path_id.."_"..hd_type.."_hd_tj",-1)
				
				ssdb:zdel("qyjh_xzt_hds_"..path_id,hd_id)
				ssdb:zdel("qyjh_xzt_hds_"..path_id.."_"..hd_type,hd_id)
			end

			--(1)存储活动跟区域均衡对应关系信息
			ssdb:zdel("qyjh_qyjh_hds_"..qyjh_id,hd_id)
			ssdb:zdel("qyjh_qyjh_hds_"..qyjh_id.."_"..hd_type,hd_id)
			--活动数量
			ssdb:hincr("qyjh_qyjh_tj_"..qyjh_id,"hd_tj",-1)
			ssdb:hincr("qyjh_qyjh_tj_"..qyjh_id.."_"..hd_type,"hd_tj",-1)
			
			ssdb:zincr("qyjh_xzt_sort_"..hd.dxq_id,xzt_id,-1)
			ssdb:zincr("qyjh_qyjh_xzt_sort_"..hd.qyjh_id,path_id,-1)
			--往mysql表中存储活动信息
			local n = ngx.now();
			local ts2 = os.date("%Y%m%d%H%M%S").."00"..string.sub(n,12,14);
			ts2 = ts2..string.rep("0",19-string.len(ts2));
			local updateSql = "update t_qyjh_hd  set b_delete =1,ts="..ts2.." where hd_id="..hd_id;
			db:query(updateSql)
			
			--标记删除资源
			local resUpdateSql = "update t_base_publish set b_delete =1,ts="..ts2.." where hd_id="..hd_id;	
			db:query(resUpdateSql)
			--ngx.log(ngx.ERR,"********===>"..updateSql.."<====*********")		
		
			say("{\"success\":true,\"info\":\"删除活动成功！\"}")
		end

		--**************************
	else
		say("{\"success\":false,\"info\":\"删除活动失败！\"}")
		return
	end


--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
-- 将redis连接归还到连接池
cache: set_keepalive(0, v_pool_size)
--mysql放回连接池
db:set_keepalive(0, v_pool_size)
