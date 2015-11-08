--[[
创建协作体[mysql版]
@Author  chenxg
@Date    2015-06-02
--]]

local say = ngx.say

--引用模块
local cjson = require "cjson"
local ssdblib = require "resty.ssdb"
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
local dxq_id = args["dxq_id"]
local subject_id = args["subject_id"]
local name = args["name"]
local description = args["description"]
local logo_url = args["logo_url"]
local person_id = args["person_id"]
local is_init = args["is_init"]

--从cookie获取当前用户的身份和person_id
local cookie_identity_id = tostring(ngx.var.cookie_identity_id)
local cookie_person_id = tostring(ngx.var.cookie_person_id)
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

local sch_id = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"xiao")
local org_id = cache:hget("person_"..person_id.."_"..cookie_identity_id,"xiao")
local province_id = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"sheng")
local city_id = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"shi")
local district_id = cache:hget("person_"..cookie_person_id.."_"..cookie_identity_id,"qu")
local ts = os.date("%Y-%m-%d %H:%M:%S")
local n = ngx.now();
local ts2 = os.date("%Y%m%d%H%M%S").."00"..string.sub(n,12,14);
ts2 = ts2..string.rep("0",19-string.len(ts2));
local id = cache:incr("t_qyjh_xzt_pk")

--判断参数是否为空
if not qyjh_id or string.len(qyjh_id) == 0 
  or not subject_id or string.len(subject_id) == 0 
  or not dxq_id or string.len(dxq_id) == 0 
  or not name or string.len(name) == 0 
  or not description or string.len(description) == 0 
  or not logo_url or string.len(logo_url) == 0
  or not person_id or string.len(person_id) == 0 
  then
    say("{\"success\":false,\"info\":\"参数错误！\"}")
    return
end
--取协作体id
local xzt_id = ssdb:incr("qyjh_pk")[1]
--往mysql表存储协作体信息
--获取person_id详情, 调用java接口
local personlist
local res_person = ngx.location.capture("/dsideal_yy/person/getPersonNameListByIds?ids="..person_id)
if res_person.status == 200 then
	personlist = cjson.decode(res_person.body)
else
	say("{\"success\":false,\"info\":\"查询用户信息失败！\"}")
	return
end
local person_name = personlist.list[1].personName

local insertSql = "insert into t_qyjh_xzt (id,qyjh_id,dxq_id,xzt_id,xzt_name,subject_id,person_name,ts,person_id,createUeer_id,description,district_id,city_id,province_id,createtime,logo_url,org_id,is_init)values("
			..xzt_id..","..quote(qyjh_id)..","..quote(dxq_id)..","..quote(xzt_id)..","..quote(name)..","..quote(subject_id)..","..quote(person_name)..","..quote(ts2)..","..quote(person_id)..","..quote(cookie_person_id)..","
		..quote(description)..","..quote(district_id)..","..quote(city_id)..","..quote(province_id)..","..quote(ts)..","..quote(logo_url)..","..quote(sch_id)..","..quote(is_init)..")";		
local ok, err = db:query(insertSql)

--将带头人存储协作体内
local params = "xzt_id="..xzt_id.."&org_id="..sch_id.."&operationtype=1&person_id="..person_id
local res_xzt = ngx.location.capture("/dsideal_yy/ypt/qyjhfz/managePersonForXzt?"..params)
if res_xzt.status ~= 200 then
	say("{\"success\":false,\"info\":\"将带头人存储协作体失败！\"}")
	return
end

local updateSql = "update t_qyjh_qyjhs set xzt_tj = xzt_tj+1 where qyjh_id="..qyjh_id.."";	
db:query(updateSql)
updateSql = "update t_qyjh_dxq set xzt_tj = xzt_tj+1 where dxq_id="..dxq_id.."";	
db:query(updateSql)
local query_sql = "select person_id from t_qyjh_dxq_dtr where b_use=1 and dxq_id="..dxq_id.." and person_id="..person_id
	local result, err, errno, sqlstate = db:query(query_sql);
	if not result then
		ngx.say("{\"success\":false,\"info\":\"查询协作体数据失败！\"}");
		return;
	end
	if #result == 0 then
		updateSql = "update t_qyjh_dxq set dtr_tj = dtr_tj+1 where dxq_id="..dxq_id..";";
		db:query(updateSql)
		local insertSql = "insert into t_qyjh_dxq_dtr(qyjh_id,dxq_id,org_id,person_id,start_time) values("..quote(qyjh_id)..","..quote(dxq_id)..","..quote(org_id)..","..quote(person_id)..","..quote(os.date("%Y-%m-%d %H:%M:%S"))..")";
		db:query(insertSql)
	end

--需要将大学区初始化为分区
if is_init and is_init == "1" then	
	--调用论坛接口创建bbs
	local bbsService = require("social.service.BbsService")
	local partitionService = require("social.service.CommonPartitionService")
	local forumService = require("social.service.CommonForumService")
	local tbbs = bbsService:getBbsByRegionId(qyjh_id);
	local bbs_id=tbbs.id;
	local bbs_sql = "select bbs_pk from t_qyjh_bbs where bbs_type=1 and dxq_id="..dxq_id..""
	local result2, err, errno, sqlstate = db:query(bbs_sql);
	if not result2 then
		ngx.say("{\"success\":false,\"info\":\"查询数据失败！\"}");
		return;
	end
	-- icon_url = string.gsub(logo_url, "../../../", "../../")
	local icon_url = string.match(logo_url,".+/(.+)")
	local bz = {person_id=tostring(person_id),person_name=person_name,identity_id="5"}
	local forum_admin_list = {}
	forum_admin_list[1]=bz
	local pam = {bbs_id=tostring(bbs_id),partition_id=tostring(result2[1]["bbs_pk"]),name=name,icon_url=icon_url,description=description,sequence=tostring(xzt_id),type_id=tostring(xzt_id),type="3",forum_admin_list=forum_admin_list}
	local status, err = pcall(function()
        local bbs_pk = forumService:saveForum(pam)
		--ngx.log(ngx.ERR,"cxg_log ========>"..bbs_id.."<=============")
		local bbs_sql = "insert into t_qyjh_bbs(bbs_id,qyjh_id,dxq_id,xzt_id,bbs_type,create_time,bbs_pk,person_id)values("..quote(bbs_id)..","..quote(qyjh_id)..","..quote(dxq_id)..","..quote(xzt_id)..",2,"..quote(ts)..","..bbs_pk..","..person_id..")";
		db:query(bbs_sql);
    end)
	--ngx.log(ngx.ERR,"cxg_log ========>"..bbs_id..name..dxq_id..dxq_id.."<=============")
end
	
say("{\"success\":true,\"xzt_id\":\""..xzt_id.."\",\"name\":\""..name.."\",\"info\":\"协作体创建成功！\"}")

--ssdb放回连接池
ssdb:set_keepalive(0,v_pool_size)
-- 将redis连接归还到连接池
cache: set_keepalive(0, v_pool_size)
--mysql放回连接池
db:set_keepalive(0, v_pool_size)
