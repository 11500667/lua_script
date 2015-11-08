--[[
创建大学区[mysql版]
@Author  chenxg
@Date    2015-06-01
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
local qyjh_id = args["qyjh_id"]
local name = args["name"]
local description = args["description"]
local logo_url = args["logo_url"]
local person_id = args["person_id"]
local is_init = args["is_init"]

--从cookie获取当前用户的省市区ID
local cookie_province_id = tostring(ngx.var.cookie_background_province_id)
local cookie_city_id = tostring(ngx.var.cookie_background_city_id)
local cookie_district_id = tostring(ngx.var.cookie_background_district_id)

--判断参数是否为空
if not qyjh_id or string.len(qyjh_id) == 0 
  or not name or string.len(name) == 0 
  or not description or string.len(description) == 0 
  or not logo_url or string.len(logo_url) == 0
  or not person_id or string.len(person_id) == 0 
  then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end

--创建ssdb连接
local ssdblib = require "resty.ssdb"
local ssdb = ssdblib:new()
local ok, err = ssdb:connect(v_ssdb_ip, v_ssdb_port)
if not ok then
    say("{\"success\":false,\"info\":\""..err.."\"}")
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
--取大学区id
local dxq_id = ssdb:incr("qyjh_pk")[1]
local ts = os.date("%Y-%m-%d %H:%M:%S")
ts2 = os.date("%Y%m%d%H%M%S")

--存储区域均衡下大学区数量开始
local updateSql = "update t_qyjh_qyjhs set dxq_tj = dxq_tj+1 where qyjh_id="..qyjh_id.."";	
mysql_db:query(updateSql)

--mysql存储大学区信息
local n = ngx.now();
local ts3 = os.date("%Y%m%d%H%M%S").."00"..string.sub(n,12,14);
ts3 = ts3..string.rep("0",19-string.len(ts3));
local insertSql = "insert into t_qyjh_dxq (id,qyjh_id,dxq_id,dxq_name,ts,person_id,description,district_id,city_id,province_id,createtime,logo_url,is_init)values("
		..dxq_id..","..quote(qyjh_id)..","..quote(dxq_id)..","..quote(name)..","..quote(ts3)..","..quote(person_id)..","
		..quote(description)..","..quote(cookie_district_id)..","..quote(cookie_city_id)..","..quote(cookie_province_id)..","..quote(ts)..","..quote(logo_url)..","..quote(is_init)..")";	
mysql_db:query(insertSql)

--需要将大学区初始化为分区
if is_init and is_init == "1" then	
	--调用论坛接口创建bbs
	local bbsService = require("social.service.BbsService")
	local partitionService = require("social.service.CommonPartitionService")
	local tbbs = bbsService:getBbsByRegionId(qyjh_id);
	local bbs_id=tbbs.id;
	
	local bbs_pk = partitionService:savePartition(bbs_id,name,dxq_id,dxq_id,3)
	
	--ngx.log(ngx.ERR,"cxg_log ========>"..bbs_id.."<=============")
	local bbs_sql = "insert into t_qyjh_bbs(bbs_id,qyjh_id,dxq_id,bbs_type,create_time,bbs_pk)values("..quote(bbs_id)..","..quote(qyjh_id)..","..quote(dxq_id)..",1,"..quote(ts)..","..bbs_pk..")";
	mysql_db:query(bbs_sql);

	--ngx.log(ngx.ERR,"cxg_log ========>"..bbs_id..name..dxq_id..dxq_id.."<=============")
end
--return
say("{\"success\":true,\"dxq_id\":\""..dxq_id.."\",\"name\":\""..name.."\",\"info\":\"大学区创建成功！\"}")

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
--mysql放回连接池
mysql_db:set_keepalive(0,v_pool_size)
