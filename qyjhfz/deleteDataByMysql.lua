--[[
清除区域均衡的相关数据[mysql版]
@Author  chenxg
@Date    2015-06-05
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

--参数
local path_id = args["path_id"]
--1:区域均衡2:大学区3:协作体4:活动
local page_type = args["page_type"]
if not path_id or string.len(path_id) == 0 
or not page_type or string.len(page_type) == 0 then
    say("{\"success\":false,\"info\":\"path_id or page_type[1--4] 参数错误！\"}")
    return
end
local n = ngx.now();
local ts = os.date("%Y%m%d%H%M%S").."00"..string.sub(n,12,14);
ts = ts..string.rep("0",19-string.len(ts));

if page_type == "1" then
	--调用论坛接口删除分区、版块相关信息
	local bbs_fq_sql = "select bbs_pk from t_qyjh_bbs where bbs_type=1 and qyjh_id="..path_id..";"
	local bbs_bk_sql = "select bbs_pk from t_qyjh_bbs where bbs_type=2 and qyjh_id="..path_id..";"
	local result, err, errno, sqlstate = db:query(bbs_fq_sql);
	local result2, err, errno, sqlstate = db:query(bbs_bk_sql);
	if not result then
		ngx.say("{\"success\":false,\"info\":\"查询论坛分区信息失败！\"}");
		return;
	end
	if #result>=1 then
		local partitionService = require("social.service.CommonPartitionService")
		for i=1,#result,1 do
			partitionService:deletePartition(result[i]["bbs_pk"])
		end
	end
	
	if #result2>=1 then
		local forumService = require("social.service.CommonForumService")
		for i=1,#result2,1 do
			forumService:deleteForum(result2[1]["bbs_pk"])
		end
	end
	
	
	local qyjh_sql = "delete from t_qyjh_qyjhs where qyjh_id="..path_id..";"
	local qyjh_hd_sql = "delete from t_qyjh_hd where qyjh_id="..path_id..";"
	local qyjh_xzt_sql = "delete from t_qyjh_xzt where qyjh_id="..path_id..";"
	local qyjh_dxq_sql = "delete from t_qyjh_dxq  where qyjh_id="..path_id..";"
	local qyjh_dxq_org_sql = "delete from t_qyjh_dxq_org  where qyjh_id="..path_id..";"
	local qyjh_dxq_dtr_sql = "delete from t_qyjh_dxq_dtr  where qyjh_id="..path_id..";"
	local qyjh_xzt_tea_sql = "delete from t_qyjh_xzt_tea  where qyjh_id="..path_id..";"
	local qyjh_zy_sql = "update t_base_publish set b_delete=1,ts="..ts.." where qyjh_id="..path_id..";"
	local bbs_sql = "delete from t_qyjh_bbs where qyjh_id="..path_id..";"
	db:query(qyjh_sql)
	db:query(qyjh_hd_sql)
	db:query(qyjh_xzt_sql)
	db:query(qyjh_dxq_sql)
	db:query(qyjh_dxq_org_sql)
	db:query(qyjh_dxq_dtr_sql)
	db:query(qyjh_xzt_tea_sql)
	db:query(qyjh_zy_sql)
	db:query(bbs_sql)
elseif page_type == "2" then
	local dxq_sql = "select qyjh_id,zy_tj,xzt_tj,hd_tj from t_qyjh_dxq where dxq_id = "..path_id
	local dxq_result, err, errno, sqlstate = db:query(dxq_sql);
	if not dxq_result then
		ngx.say("{\"success\":false,\"info\":\"获取大学区信息失败！\"}");
		return;
	end
	
	local bbs_fq_sql = "select bbs_pk from t_qyjh_bbs where bbs_type=1 and dxq_id="..path_id..";"
	local bbs_bk_sql = "select bbs_pk from t_qyjh_bbs where bbs_type=2 and dxq_id="..path_id..";"
	local result, err, errno, sqlstate = db:query(bbs_fq_sql);
	local result2, err, errno, sqlstate = db:query(bbs_bk_sql);
	if not result then
		ngx.say("{\"success\":false,\"info\":\"查询论坛分区信息失败！\"}");
		return;
	end
	if #result>=1 then
		local partitionService = require("social.service.CommonPartitionService")
		for i=1,#result,1 do
			partitionService:deletePartition(result[i]["bbs_pk"])
		end
	end
	
	if #result2>=1 then
		local forumService = require("social.service.CommonForumService")
		for i=1,#result2,1 do
			forumService:deleteForum(result2[1]["bbs_pk"])
		end
	end
	
	if #dxq_result>0 then 
		
		local bbs_bk_sql = "select bbs_pk from t_qyjh_bbs where bbs_type=2 and xzt_id="..path_id..";"
		local result2, err, errno, sqlstate = db:query(bbs_bk_sql);
		if not result2 then
			ngx.say("{\"success\":false,\"info\":\"查询论坛分区信息失败！\"}");
			return;
		end
		if #result2>=1 then
			local forumService = require("social.service.CommonForumService")
			for i=1,#result2,1 do
				forumService:deleteForum(result2[1]["bbs_pk"])
			end
		end
		
		local dxq_qyjh_sql = "update t_qyjh_qyjhs set dxq_tj = dxq_tj-1,xzt_tj = xzt_tj-"..dxq_result[1]["xzt_tj"]..",hd_tj = hd_tj-"..dxq_result[1]["hd_tj"]..",zy_tj = zy_tj-"..dxq_result[1]["zy_tj"].." where qyjh_id="..dxq_result[1]["qyjh_id"]..";"
		local dxq_hd_sql = "delete from t_qyjh_hd where dxq_id="..path_id..";"
		local dxq_xzt_sql = "delete from t_qyjh_xzt where dxq_id="..path_id..";"
		local dxq_dxq_org_sql = "delete from t_qyjh_dxq_org  where dxq_id="..path_id..";"
		local dxq_dxq_dtr_sql = "delete from t_qyjh_dxq_dtr  where dxq_id="..path_id..";"
		local dxq_xzt_tea_sql = "delete from t_qyjh_xzt_tea  where dxq_id="..path_id..";"
		local dxq_zy_sql = "update t_base_publish set b_delete=1,ts="..ts.." where pub_target="..path_id..";"
		local dxq_dxq_sql = "delete from t_qyjh_dxq  where dxq_id="..path_id..";"
		local bbs_sql = "delete from t_qyjh_bbs where dxq_id="..path_id..";"
		
		db:query(dxq_qyjh_sql)
		db:query(dxq_hd_sql)
		db:query(dxq_xzt_sql)
		db:query(dxq_dxq_org_sql)
		db:query(dxq_dxq_dtr_sql)
		db:query(dxq_xzt_tea_sql)
		db:query(dxq_zy_sql)
		db:query(dxq_dxq_sql)
		db:query(bbs_sql)
	end
elseif page_type == "3" then
	local xzt_sql = "select qyjh_id,dxq_id,zy_tj,hd_tj from t_qyjh_xzt where xzt_id = "..path_id
	local xzt_result, err, errno, sqlstate = db:query(xzt_sql);
	if not xzt_result then
		ngx.say("{\"success\":false,\"info\":\"获取协作体信息失败！\"}");
		return;
	end
	if #xzt_result>0 then 
		local xzt_qyjh_sql = "update t_qyjh_qyjhs set xzt_tj = xzt_tj-1,hd_tj = hd_tj-"..xzt_result[1]["hd_tj"]..",zy_tj = zy_tj-"..xzt_result[1]["zy_tj"].." where qyjh_id="..xzt_result[1]["qyjh_id"]..";"
		
		local xzt_dxq_sql = "update t_qyjh_dxq set xzt_tj = xzt_tj-1,hd_tj = hd_tj-"..xzt_result[1]["hd_tj"]..",zy_tj = zy_tj-"..xzt_result[1]["zy_tj"].." where dxq_id="..xzt_result[1]["dxq_id"]..";"
		
		local xzt_hd_sql = "delete from t_qyjh_hd where xzt_id="..path_id..";"
		local xzt_dxq_org_sql = "delete from t_qyjh_dxq_org  where xzt_id="..path_id..";"
		local xzt_dxq_dtr_sql = "delete from t_qyjh_dxq_dtr  where xzt_id="..path_id..";"
		local xzt_xzt_tea_sql = "delete from t_qyjh_xzt_tea  where xzt_id="..path_id..";"
		local xzt_zy_sql = "update t_base_publish set b_delete=1,ts="..ts.." where xzt_id="..path_id..";"
		local xzt_xzt_sql = "delete from t_qyjh_xzt where xzt_id="..path_id..";"
		local bbs_sql = "delete from t_qyjh_bbs where xzt_id="..path_id..";"
		
		db:query(xzt_qyjh_sql)
		db:query(xzt_dxq_sql)
		db:query(xzt_hd_sql)
		db:query(xzt_dxq_org_sql)
		db:query(xzt_dxq_dtr_sql)
		db:query(xzt_xzt_tea_sql)
		db:query(xzt_zy_sql)
		db:query(xzt_xzt_sql)
		db:query(bbs_sql)
	end
elseif page_type == "4" then
	local hd_sql = "select qyjh_id,dxq_id,xzt_id,zy_tj,wk_tj from t_qyjh_hd where hd_id = "..path_id
	local hd_result, err, errno, sqlstate = db:query(hd_sql);
	if not hd_result then
		ngx.say("{\"success\":false,\"info\":\"获取活动信息失败！\"}");
		return;
	end
	if #hd_result>0 then
		local hd_qyjh_sql = "update t_qyjh_qyjhs set hd_tj = hd_tj-1,zy_tj = zy_tj-"..hd_result[1]["zy_tj"].." where qyjh_id="..hd_result[1]["qyjh_id"]..";"
		
		local hd_dxq_sql = "update t_qyjh_dxq set hd_tj = hd_tj-1,zy_tj = zy_tj-"..hd_result[1]["zy_tj"].." where dxq_id="..hd_result[1]["dxq_id"]..";"	
		
		local hd_xzt_sql = "update t_qyjh_xzt set hd_tj = hd_tj-1,zy_tj = zy_tj-"..hd_result[1]["zy_tj"]..",wk_tj = wk_tj-"..hd_result[1]["wk_tj"].." where xzt_id="..hd_result[1]["xzt_id"]..";"	
		
		local hd_zy_sql = "update t_base_publish set b_delete=1,ts="..ts.." where hd_id="..path_id..";"
		local hd_hd_sql = "delete from t_qyjh_hd where hd_id="..path_id..";"
		
		db:query(hd_qyjh_sql)
		db:query(hd_dxq_sql)
		db:query(hd_xzt_sql)
		db:query(hd_zy_sql)
		db:query(hd_hd_sql)
	end
end
--mysql放回连接池
db:set_keepalive(0,v_pool_size)
say("{\"success\":\"true\",\"info\":\"删除指定信息成功！\"}")