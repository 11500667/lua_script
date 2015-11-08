--[[
保存编辑后的大学区[mysql版]
@Author  chenxg
@Date    2015-06-02
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local quote = ngx.quote_sql_str

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
local name = args["name"]
local description = args["description"]
local logo_url = args["logo_url"]
local person_id = args["person_id"]
local is_init = args["is_init"]
local qyjh_id = args["qyjh_id"]

--判断参数是否为空
if not dxq_id or string.len(dxq_id) == 0  
  or not name or string.len(name) == 0 
  or not description or string.len(description) == 0 
  or not logo_url or string.len(logo_url) == 0
  or not person_id or string.len(person_id) == 0 
  then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

--连接mysql数据库
local mysql = require "resty.mysql"
local mysql_db = mysql:new()
mysql_db:connect{
    host = v_mysql_ip,
    port = v_mysql_port,
    database = v_mysql_database,
    user = v_mysql_user,
    password = v_mysql_password,
    max_packet_size = 1024*1024
}

--更新mysql表中大学区的信息
local ts = os.date("%Y-%m-%d %H:%M:%S")
local n = ngx.now();
local ts2 = os.date("%Y%m%d%H%M%S").."00"..string.sub(n,12,14);
ts2 = ts2..string.rep("0",19-string.len(ts2));
		
local updateSql = "update t_qyjh_dxq set dxq_name = "..quote(name)..",person_id ="..quote(person_id)..",ts="..quote(ts2)..",description = "..quote(description)..",logo_url = "..quote(logo_url)..",is_init = "..quote(is_init).." where dxq_id="..quote(dxq_id);
--ngx.log(ngx.ERR,"********===>"..updateSql.."<====*********")
mysql_db:query(updateSql)

--ngx.log(ngx.ERR,"cxg_log ========>"..qyjh_id.."<=============")

--需要将大学区初始化为分区
if is_init then	
	--先查询之前有没有初始化过
	local bbs_sql = "select bbs_pk,b_delete from t_qyjh_bbs where bbs_type=1 and dxq_id="..dxq_id..""
	local result, err, errno, sqlstate = mysql_db:query(bbs_sql);
	if not result then
		ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
		return;
	end
	
	--调用论坛接口创建bbs
	local bbsService = require("social.service.BbsService")
	local partitionService = require("social.service.CommonPartitionService")
	local tbbs = bbsService:getBbsByRegionId(qyjh_id);
	local bbs_id=tbbs.id;
	if is_init == "1" then
		if #result>=1 then
			local update_sql = "update t_qyjh_bbs set b_delete=0 where bbs_pk="..result[1]["bbs_pk"]..""
			mysql_db:query(update_sql)
			partitionService:updatePartition(name,result[1]["bbs_pk"])
			if result[1]["b_delete"] == 1 then
				partitionService:recoveryPartition(result[1]["bbs_pk"])
			end
		else
			local bbs_pk = partitionService:savePartition(bbs_id,name,dxq_id,dxq_id,3)
			local bbs_sql = "insert into t_qyjh_bbs(bbs_id,qyjh_id,dxq_id,bbs_type,create_time,bbs_pk)values("..quote(bbs_id)..","..quote(qyjh_id)..","..quote(dxq_id)..",1,"..quote(ts)..","..bbs_pk..")";
			mysql_db:query(bbs_sql);
		end
	else
		if #result>=1 then
			local update_sql = "update t_qyjh_bbs set b_delete=1 where bbs_pk="..result[1]["bbs_pk"]..""
			mysql_db:query(update_sql)

			if result[1]["b_delete"] == 0 then
				partitionService:deletePartition(result[1]["bbs_pk"])
			end
		end
	end
	--ngx.log(ngx.ERR,"cxg_log ========>"..bbs_id.."<=============")
end

--return
say("{\"success\":true,\"dxq_id\":\""..dxq_id.."\",\"name\":\""..name.."\",\"info\":\"大学区信息修改成功！\"}")

--mysql放回连接池
mysql_db:set_keepalive(0,v_pool_size)
